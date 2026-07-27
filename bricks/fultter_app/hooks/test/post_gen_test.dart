import 'dart:io';

import 'package:test/test.dart';

import '../post_gen.dart';

void main() {
  group('metadata validation', () {
    final invalidValues = {
      'app_name': 'My-App',
      'org_domain': 'Example',
      'bundle_id': 'com.example.bad-value',
    };

    for (final invalid in invalidValues.entries) {
      test('${invalid.key} fails before running a command', () async {
        final variables = _validVariables()..[invalid.key] = invalid.value;
        var commandCount = 0;

        await expectLater(
          generateApp(
            variables: variables,
            output: _RecordedOutput().output,
            processRunner: (executable, arguments, {workingDirectory}) async {
              commandCount++;
              return ProcessResult(1, 0, '', '');
            },
          ),
          throwsA(
            isA<FormatException>().having(
              (error) => error.message,
              'message',
              allOf(contains(invalid.key), contains('must be')),
            ),
          ),
        );
        expect(commandCount, 0);
      });
    }
  });

  test('missing Flutter fails without reporting success', () async {
    final directory = await Directory.systemTemp.createTemp('hook_test_');
    addTearDown(() => directory.delete(recursive: true));
    final recorded = _RecordedOutput();

    await expectLater(
      generateApp(
        variables: _validVariables(),
        output: recorded.output,
        workingDirectory: directory.path,
        processRunner: (executable, arguments, {workingDirectory}) {
          throw ProcessException(executable, arguments, 'not found');
        },
      ),
      throwsA(
        predicate(
          (error) =>
              error.toString().contains('flutter') &&
              error.toString().contains('PATH'),
        ),
      ),
    );

    expect(recorded.successes, isEmpty);
    expect(recorded.failedProgress, 1);
  });

  test('command failure preserves output and restores template files',
      () async {
    final directory = await Directory.systemTemp.createTemp('hook_test_');
    addTearDown(() => directory.delete(recursive: true));
    final readme = File('${directory.path}/README.md')
      ..writeAsStringSync('template content');
    final gitignore = File('${directory.path}/.gitignore')
      ..writeAsStringSync('template ignores');
    final recorded = _RecordedOutput();

    await expectLater(
      generateApp(
        variables: _validVariables(),
        output: recorded.output,
        workingDirectory: directory.path,
        processRunner: (executable, arguments, {workingDirectory}) async {
          readme.writeAsStringSync('flutter content');
          gitignore.writeAsStringSync('flutter ignores');
          return ProcessResult(1, 7, 'create output', 'create failure');
        },
      ),
      throwsA(
        predicate(
          (error) =>
              error.toString().contains('exit code 7') &&
              error.toString().contains('create output') &&
              error.toString().contains('create failure'),
        ),
      ),
    );

    expect(readme.readAsStringSync(), 'template content');
    expect(gitignore.readAsStringSync(), 'template ignores');
    expect(recorded.errors.single, contains('stdout:\ncreate output'));
    expect(recorded.errors.single, contains('stderr:\ncreate failure'));
    expect(recorded.successes, isEmpty);
  });

  test('successful generation patches identity and prints exact commands',
      () async {
    final directory = await Directory.systemTemp.createTemp('hook_test_');
    addTearDown(() => directory.delete(recursive: true));
    final readme = File('${directory.path}/README.md')
      ..writeAsStringSync('template content');
    final workflow = File('${directory.path}/.github/workflows/flutter_ci.yml')
      ..createSync(recursive: true)
      ..writeAsStringSync('template workflow');
    final recorded = _RecordedOutput();
    final commands = <String>[];

    await generateApp(
      variables: _validVariables()
        ..['run_pub_get'] = false
        ..['run_tests_after_generate'] = false,
      output: recorded.output,
      workingDirectory: directory.path,
      processRunner: (executable, arguments, {workingDirectory}) async {
        commands.add('$executable ${arguments.join(' ')}');
        if (executable == 'flutter' && arguments.first == 'create') {
          readme.writeAsStringSync('flutter content');
          workflow.writeAsStringSync('flutter workflow');
          _writeGeneratedFile(
            directory,
            'android/app/build.gradle.kts',
            'applicationId = "com.example.my_app"',
          );
          _writeGeneratedFile(
            directory,
            'android/app/src/main/AndroidManifest.xml',
            '<application android:label="my_app" />',
          );
          _writeGeneratedFile(
            directory,
            'android/app/src/main/kotlin/com/example/my_app/MainActivity.kt',
            'package com.example.my_app',
          );
          _writeGeneratedFile(
            directory,
            'ios/Runner.xcodeproj/project.pbxproj',
            'PRODUCT_BUNDLE_IDENTIFIER = com.example.my_app;',
          );
          _writeGeneratedFile(
            directory,
            'ios/Runner/Info.plist',
            '<string>my_app</string>',
          );
        }
        return ProcessResult(1, 0, '', '');
      },
    );

    expect(readme.readAsStringSync(), 'template content');
    expect(workflow.readAsStringSync(), 'template workflow');
    expect(
      File('${directory.path}/android/app/build.gradle.kts').readAsStringSync(),
      contains('com.acme.product'),
    );
    expect(
      File('${directory.path}/android/app/src/main/AndroidManifest.xml')
          .readAsStringSync(),
      contains('android:label="My App"'),
    );
    expect(
      File(
        '${directory.path}/android/app/src/main/kotlin/'
        'com/example/my_app/MainActivity.kt',
      ).readAsStringSync(),
      contains('package com.acme.product'),
    );
    expect(
      File('${directory.path}/ios/Runner.xcodeproj/project.pbxproj')
          .readAsStringSync(),
      contains('com.acme.product'),
    );
    expect(
      File('${directory.path}/ios/Runner/Info.plist').readAsStringSync(),
      contains('<string>My App</string>'),
    );
    expect(
      commands,
      [
        'flutter create --project-name my_app --org com.example '
            '--platforms android,ios --no-pub .',
        'dart format .',
      ],
    );
    expect(recorded.successes, ['Generated my_app.']);
    expect(
      recorded.infos,
      [
        'Run dev: flutter run --dart-define-from-file=config/dev.json',
        'Run staging: '
            'flutter run --dart-define-from-file=config/staging.json',
        'Run prod: flutter run --dart-define-from-file=config/prod.json',
        'Verify analysis: flutter analyze',
        'Verify tests: flutter test',
      ],
    );
  });
}

Map<String, dynamic> _validVariables() {
  return {
    'app_name': 'my_app',
    'app_display_name': 'My App',
    'bundle_id': 'com.acme.product',
    'org_domain': 'com.example',
    'run_pub_get': true,
    'run_tests_after_generate': false,
  };
}

void _writeGeneratedFile(Directory root, String path, String content) {
  final file = File('${root.path}/$path');
  file.parent.createSync(recursive: true);
  file.writeAsStringSync(content);
}

class _RecordedOutput {
  final infos = <String>[];
  final errors = <String>[];
  final successes = <String>[];
  var completedProgress = 0;
  var failedProgress = 0;

  late final output = GenerationOutput(
    info: infos.add,
    error: errors.add,
    success: successes.add,
    startProgress: (_) => CommandProgress(
      complete: () => completedProgress++,
      fail: () => failedProgress++,
    ),
  );
}
