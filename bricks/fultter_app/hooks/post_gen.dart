import 'dart:io';

import 'package:mason/mason.dart';

typedef ProcessRunner = Future<ProcessResult> Function(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
});

class CommandProgress {
  const CommandProgress({required this.complete, required this.fail});

  final void Function() complete;
  final void Function() fail;
}

class GenerationOutput {
  const GenerationOutput({
    required this.info,
    required this.error,
    required this.success,
    required this.startProgress,
  });

  final void Function(String message) info;
  final void Function(String message) error;
  final void Function(String message) success;
  final CommandProgress Function(String message) startProgress;
}

Future<void> run(HookContext context) async {
  final logger = context.logger;
  await generateApp(
    variables: context.vars,
    output: GenerationOutput(
      info: logger.info,
      error: logger.err,
      success: logger.success,
      startProgress: (message) {
        final progress = logger.progress(message);
        return CommandProgress(
          complete: () => progress.complete(),
          fail: () => progress.fail(),
        );
      },
    ),
  );
}

Future<void> generateApp({
  required Map<String, dynamic> variables,
  required GenerationOutput output,
  String? workingDirectory,
  ProcessRunner? processRunner,
}) async {
  final appName = _validatedVariable(
    variables,
    'app_name',
    _isValidDartPackageName,
    'a lowercase Dart package name starting with a letter and containing only '
        'lowercase letters, digits, and underscores (for example, my_app)',
  );
  final orgDomain = _validatedVariable(
    variables,
    'org_domain',
    _isValidOrgDomain,
    'a lowercase reverse domain with at least two dot-separated segments '
        '(for example, com.example)',
  );
  final bundleId = _validatedVariable(
    variables,
    'bundle_id',
    _isValidBundleId,
    'a reverse-domain identifier with at least two dot-separated segments; '
        'each segment must start with a lowercase letter and contain only '
        'lowercase letters, digits, or underscores '
        '(for example, com.example.my_app)',
  );
  final appDisplayName = variables['app_display_name'] as String;
  final runPubGet = variables['run_pub_get'] as bool? ?? true;
  final runTests = variables['run_tests_after_generate'] as bool? ?? false;
  final root = workingDirectory ?? Directory.current.path;
  final runner = processRunner ?? _runProcess;

  final backupDirectory = await Directory.systemTemp.createTemp(
    'fultter_app_backup_',
  );
  const filesToRestore = [
    '.github',
    '.gitignore',
    'analysis_options.yaml',
    'config',
    'docs',
    'lib',
    'pubspec.yaml',
    'README.md',
    'test',
  ];

  try {
    await _backupTemplateFiles(root, backupDirectory.path, filesToRestore);

    try {
      await _runRequiredCommand(
        output,
        runner,
        'flutter',
        [
          'create',
          '--project-name',
          appName,
          '--org',
          orgDomain,
          '--platforms',
          'android,ios',
          '--no-pub',
          '.',
        ],
        workingDirectory: root,
      );

      await _patchGeneratedPlatformFiles(
        root: root,
        appName: appName,
        appDisplayName: appDisplayName,
        bundleId: bundleId,
        orgDomain: orgDomain,
      );
    } finally {
      await _restoreTemplateFiles(root, backupDirectory.path, filesToRestore);
    }

    await _runRequiredCommand(
      output,
      runner,
      'dart',
      ['format', '.'],
      workingDirectory: root,
    );

    if (runPubGet) {
      await _runRequiredCommand(
        output,
        runner,
        'flutter',
        ['pub', 'get'],
        workingDirectory: root,
      );
    }

    if (runTests) {
      await _runRequiredCommand(
        output,
        runner,
        'flutter',
        ['test'],
        workingDirectory: root,
      );
    }
  } finally {
    if (backupDirectory.existsSync()) {
      await backupDirectory.delete(recursive: true);
    }
  }

  output
    ..success('Generated $appName.')
    ..info('Run dev: flutter run --dart-define-from-file=config/dev.json')
    ..info(
      'Run staging: '
      'flutter run --dart-define-from-file=config/staging.json',
    )
    ..info('Run prod: flutter run --dart-define-from-file=config/prod.json')
    ..info('Verify analysis: flutter analyze')
    ..info('Verify tests: flutter test');
}

String _validatedVariable(
  Map<String, dynamic> variables,
  String field,
  bool Function(String value) validator,
  String acceptedFormat,
) {
  final value = variables[field];
  if (value is! String || !validator(value)) {
    throw FormatException('$field must be $acceptedFormat.');
  }
  return value;
}

Future<void> _backupTemplateFiles(
  String root,
  String backupRoot,
  List<String> paths,
) async {
  for (final path in paths) {
    final sourcePath = _join(root, path);
    final sourceType = FileSystemEntity.typeSync(sourcePath);
    if (sourceType == FileSystemEntityType.notFound) {
      continue;
    }
    await _copyEntity(
      sourceType == FileSystemEntityType.file
          ? File(sourcePath)
          : Directory(sourcePath),
      _join(backupRoot, path),
    );
  }
}

Future<void> _restoreTemplateFiles(
  String root,
  String backupRoot,
  List<String> paths,
) async {
  for (final path in paths) {
    final sourcePath = _join(backupRoot, path);
    final sourceType = FileSystemEntity.typeSync(sourcePath);
    if (sourceType == FileSystemEntityType.notFound) {
      continue;
    }

    final destinationPath = _join(root, path);
    final destinationType = FileSystemEntity.typeSync(destinationPath);
    if (destinationType != FileSystemEntityType.notFound) {
      await FileSystemEntity.isFile(destinationPath)
          ? File(destinationPath).delete()
          : Directory(destinationPath).delete(recursive: true);
    }

    await _copyEntity(
      sourceType == FileSystemEntityType.file
          ? File(sourcePath)
          : Directory(sourcePath),
      destinationPath,
    );
  }
}

Future<void> _patchGeneratedPlatformFiles({
  required String root,
  required String appName,
  required String appDisplayName,
  required String bundleId,
  required String orgDomain,
}) async {
  final defaultBundleIds = {
    '$orgDomain.$appName',
    '$orgDomain.${appName.replaceAll('_', '')}',
  };

  final candidates = [
    'android/app/build.gradle',
    'android/app/build.gradle.kts',
    'android/app/src/main/AndroidManifest.xml',
    'android/app/src/debug/AndroidManifest.xml',
    'android/app/src/profile/AndroidManifest.xml',
    'ios/Runner.xcodeproj/project.pbxproj',
    'ios/Runner/Info.plist',
  ].map((path) => _join(root, path)).toList();
  candidates.addAll(
    await _findFiles(_join(root, 'android/app/src'), ['.kt', '.java']),
  );

  for (final path in candidates) {
    final file = File(path);
    if (!file.existsSync()) {
      continue;
    }

    var content = await file.readAsString();
    for (final defaultBundleId in defaultBundleIds) {
      content = content.replaceAll(defaultBundleId, bundleId);
    }
    content = content.replaceAll(
      'android:label="$appName"',
      'android:label="$appDisplayName"',
    );
    content = content.replaceAll(
      '<string>$appName</string>',
      '<string>$appDisplayName</string>',
    );
    await file.writeAsString(content);
  }
}

Future<List<String>> _findFiles(String root, List<String> extensions) async {
  final directory = Directory(root);
  if (!directory.existsSync()) {
    return const [];
  }

  final files = <String>[];
  await for (final entity in directory.list(recursive: true)) {
    if (entity is File && extensions.any(entity.path.endsWith)) {
      files.add(entity.path);
    }
  }
  return files;
}

Future<void> _copyEntity(
    FileSystemEntity source, String destinationPath) async {
  if (source is File) {
    await File(destinationPath).parent.create(recursive: true);
    await source.copy(destinationPath);
    return;
  }

  if (source is Directory) {
    await Directory(destinationPath).create(recursive: true);
    await for (final child in source.list(recursive: false)) {
      await _copyEntity(child, _join(destinationPath, _basename(child.path)));
    }
  }
}

String _join(String parent, String child) {
  return '$parent${Platform.pathSeparator}${child.replaceAll('/', Platform.pathSeparator)}';
}

String _basename(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.substring(normalized.lastIndexOf('/') + 1);
}

bool _isValidDartPackageName(String value) {
  return RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(value);
}

bool _isValidOrgDomain(String value) {
  return RegExp(r'^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)+$').hasMatch(value);
}

bool _isValidBundleId(String value) {
  return RegExp(r'^[a-z][a-z0-9_]*(\.[a-z][a-z0-9_]*)+$').hasMatch(value);
}

Future<ProcessResult> _runProcess(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
}) {
  return Process.run(
    executable,
    arguments,
    workingDirectory: workingDirectory,
  );
}

Future<void> _runRequiredCommand(
  GenerationOutput output,
  ProcessRunner processRunner,
  String executable,
  List<String> arguments, {
  required String workingDirectory,
}) async {
  final command = '$executable ${arguments.join(' ')}';
  final progress = output.startProgress(command);

  late final ProcessResult result;
  try {
    result = await processRunner(
      executable,
      arguments,
      workingDirectory: workingDirectory,
    );
  } on ProcessException catch (error) {
    progress.fail();
    final message = 'Unable to run required command "$command": '
        '${error.message}. Ensure $executable is installed and available in PATH.';
    output.error(message);
    throw Exception(message);
  }

  if (result.exitCode != 0) {
    progress.fail();
    final stdout = result.stdout.toString().trim();
    final stderr = result.stderr.toString().trim();
    final details = StringBuffer(
      'Required command "$command" failed with exit code ${result.exitCode}.',
    );
    if (stdout.isNotEmpty) {
      details.write('\nstdout:\n$stdout');
    }
    if (stderr.isNotEmpty) {
      details.write('\nstderr:\n$stderr');
    }
    final message = details.toString();
    output.error(message);
    throw Exception(message);
  }

  progress.complete();
}
