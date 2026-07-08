import 'dart:io';

import 'package:mason/mason.dart';

Future<void> run(HookContext context) async {
  final logger = context.logger;
  final appName = context.vars['app_name'] as String;
  final appDisplayName = context.vars['app_display_name'] as String;
  final bundleId = context.vars['bundle_id'] as String;
  final orgDomain = context.vars['org_domain'] as String;
  final runPubGet = context.vars['run_pub_get'] as bool? ?? true;
  final runTests = context.vars['run_tests_after_generate'] as bool? ?? false;

  if (!_isValidDartPackageName(appName)) {
    throw Exception('app_name must be a valid Dart package name.');
  }

  if (!await _commandExists('flutter')) {
    logger.warn(
      'Flutter was not found in PATH. Generated Dart files, but skipped '
      'flutter create and flutter pub get.',
    );
    return;
  }

  final backupDirectory = await Directory.systemTemp.createTemp(
    'fultter_app_backup_',
  );
  final filesToRestore = [
    '.github',
    'analysis_options.yaml',
    'config',
    'docs',
    'lib',
    'pubspec.yaml',
    'README.md',
    'test',
  ];

  for (final path in filesToRestore) {
    final source = FileSystemEntity.typeSync(path) == FileSystemEntityType.file
        ? File(path)
        : Directory(path);
    if (source.existsSync()) {
      await _copyEntity(source, '${backupDirectory.path}/$path');
    }
  }

  await _run(
    logger,
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
  );

  await _patchGeneratedPlatformFiles(
    appName: appName,
    appDisplayName: appDisplayName,
    bundleId: bundleId,
    orgDomain: orgDomain,
  );

  for (final path in filesToRestore) {
    final sourcePath = '${backupDirectory.path}/$path';
    final sourceType = FileSystemEntity.typeSync(sourcePath);
    if (sourceType == FileSystemEntityType.notFound) {
      continue;
    }
    final destination = FileSystemEntity.typeSync(path) ==
            FileSystemEntityType.file
        ? File(path)
        : Directory(path);
    if (destination.existsSync()) {
      await destination.delete(recursive: true);
    }
    final source = sourceType == FileSystemEntityType.file
        ? File(sourcePath)
        : Directory(sourcePath);
    await _copyEntity(source, path);
  }

  await backupDirectory.delete(recursive: true);

  await _run(logger, 'dart', ['format', '.']);

  if (runPubGet) {
    await _run(logger, 'flutter', ['pub', 'get']);
  }

  if (runTests) {
    await _run(logger, 'flutter', ['test']);
  }

  logger
    ..success('Generated $appName.')
    ..info('Run with:')
    ..info(
      'flutter run --dart-define-from-file=config/dev.json',
    );
}

Future<void> _patchGeneratedPlatformFiles({
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
  ];
  candidates.addAll(await _findFiles('android/app/src', ['.kt', '.java']));

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
    if (entity is! File) {
      continue;
    }
    if (extensions.any(entity.path.endsWith)) {
      files.add(entity.path);
    }
  }
  return files;
}

Future<void> _copyEntity(FileSystemEntity source, String destinationPath) async {
  if (source is File) {
    await File(destinationPath).parent.create(recursive: true);
    await source.copy(destinationPath);
    return;
  }

  if (source is Directory) {
    await Directory(destinationPath).create(recursive: true);
    await for (final child in source.list(recursive: false)) {
      final name = _basename(child.path);
      await _copyEntity(child, '$destinationPath/$name');
    }
  }
}

String _basename(String path) {
  final normalized = path.replaceAll('\\', '/');
  return normalized.substring(normalized.lastIndexOf('/') + 1);
}

bool _isValidDartPackageName(String value) {
  return RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(value);
}

Future<bool> _commandExists(String command) async {
  final result = await Process.run(
    'sh',
    ['-c', 'command -v $command >/dev/null 2>&1'],
  );
  return result.exitCode == 0;
}

Future<void> _run(
  Logger logger,
  String executable,
  List<String> arguments,
) async {
  final progress = logger.progress('$executable ${arguments.join(' ')}');
  final result = await Process.run(executable, arguments);

  if (result.exitCode != 0) {
    progress.fail();
    logger.err(result.stdout.toString());
    logger.err(result.stderr.toString());
    throw Exception('$executable failed with exit code ${result.exitCode}.');
  }

  progress.complete();
}
