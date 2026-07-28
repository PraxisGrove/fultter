import 'dart:convert';
import 'dart:io';

void main(List<String> arguments) {
  if (arguments.length != 1) {
    stderr.writeln('Usage: dart run tool/remove_reference_feature.dart <app>');
    exitCode = 64;
    return;
  }

  final root = Directory(arguments.single).absolute;
  final pubspec = File('${root.path}/pubspec.yaml');
  if (!pubspec.existsSync()) {
    stderr.writeln('Generated app pubspec not found at ${root.path}.');
    exitCode = 66;
    return;
  }

  final packageName = RegExp(
    r'^name:\s*([a-z][a-z0-9_]*)\s*$',
    multiLine: true,
  ).firstMatch(pubspec.readAsStringSync())?.group(1);
  if (packageName == null) {
    stderr.writeln('Could not read the generated package name.');
    exitCode = 65;
    return;
  }

  _deleteDirectory(Directory('${root.path}/lib/src/features/reference'));
  _deleteDirectory(Directory('${root.path}/test/features/reference'));
  _updateRouter(root, packageName);
  _removeReferenceLocalizations(root);
  _regenerateLocalizations(root);
  _updateAppTests(root);
  _updateGuidance(root);

  final remainingReferences = _findReferenceMentions(root);
  if (remainingReferences.isNotEmpty) {
    stderr.writeln(remainingReferences.join('\n'));
    stderr.writeln('Reference feature code remains after removal.');
    exitCode = 1;
  }
}

void _updateRouter(Directory root, String packageName) {
  final router = File('${root.path}/lib/src/app/router.dart');
  var source = router.readAsStringSync();
  final displayName = RegExp(
    r"appBar: AppBar\(title: const Text\('([^']*)'\)\)",
  ).firstMatch(source)?.group(1);
  if (displayName == null) {
    throw StateError('Could not read the generated app display name.');
  }

  for (final import in const [
    "import '../features/reference/presentation/reference_detail_page.dart';\n",
    "import '../features/reference/presentation/reference_edit_page.dart';\n",
    "import '../features/reference/presentation/reference_list_page.dart';\n",
  ]) {
    source = _replaceRequired(source, import, '');
  }
  source = _replaceRequired(
    source,
    "import 'providers.dart';\n",
    "import 'home_page.dart';\nimport 'providers.dart';\n",
  );
  source = _replaceRequired(
    source,
    "  static const referenceDetail = '/references/:id';\n"
        "  static const referenceEdit = '/references/:id/edit';\n",
    '',
  );
  source = _replaceRequired(
    source,
    "\n  static String referenceDetailPath(String id) {\n"
        "    return '/references/\${Uri.encodeComponent(id)}';\n"
        "  }\n\n"
        "  static String referenceEditPath(String id) {\n"
        "    return '\${referenceDetailPath(id)}/edit';\n"
        "  }\n",
    '',
  );
  source = _replaceRequired(
    source,
    '        builder: (context, state) => const ReferenceListPage(),',
    '        builder: (context, state) => const HomePage(),',
  );
  source = _replaceRequired(
    source,
    "      GoRoute(\n"
        "        path: AppRoutes.referenceEdit,\n"
        "        builder: (context, state) {\n"
        "          return ReferenceEditPage(id: state.pathParameters['id']!);\n"
        "        },\n"
        "      ),\n"
        "      GoRoute(\n"
        "        path: AppRoutes.referenceDetail,\n"
        "        builder: (context, state) {\n"
        "          return ReferenceDetailPage(id: state.pathParameters['id']!);\n"
        "        },\n"
        "      ),\n",
    '',
  );
  router.writeAsStringSync(source);

  File('${root.path}/lib/src/app/home_page.dart').writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:$packageName/l10n/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('$displayName')),
      body: Center(child: Text(AppLocalizations.of(context)!.homeReady)),
    );
  }
}
''');
}

void _removeReferenceLocalizations(Directory root) {
  final files = Directory('${root.path}/lib/l10n')
      .listSync()
      .whereType<File>()
      .where((file) => RegExp(r'app_.*\.arb$').hasMatch(file.path));
  for (final file in files) {
    final values = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
    values.removeWhere((key, value) => key.startsWith('reference'));
    final output = const JsonEncoder.withIndent('  ').convert(values);
    file.writeAsStringSync('$output\n');
  }
}

void _regenerateLocalizations(Directory root) {
  final result = Process.runSync('flutter', const [
    'gen-l10n',
  ], workingDirectory: root.path);
  stdout.write(result.stdout);
  stderr.write(result.stderr);
  if (result.exitCode != 0) {
    throw ProcessException(
      'flutter',
      const ['gen-l10n'],
      'Localization generation failed.',
      result.exitCode,
    );
  }
}

void _updateAppTests(Directory root) {
  final file = File('${root.path}/test/app/app_test.dart');
  var source = file.readAsStringSync();
  source = _removeTest(
    source,
    'lets users select a theme from the reference control',
  );
  source = _removeTest(
    source,
    'reference controls do not clip at 200 percent text scale',
  );
  source = source
      .replaceAll(
        "expect(find.text('References'), findsOneWidget);",
        "expect(find.text('Ready.'), findsOneWidget);",
      )
      .replaceAll(
        "expect(find.text('参考项目'), findsOneWidget);",
        "expect(find.text('准备就绪。'), findsOneWidget);",
      )
      .replaceAll("    expect(find.byTooltip('选择主题'), findsOneWidget);\n", '');
  source = _replaceRequired(
    source,
    "  testWidgets('returns an authenticated user to a protected deep link', (\n",
    '''  testWidgets('neutral starter remains runnable after reference removal', (
    tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text('Ready.'), findsOneWidget);
    expect(find.text('References'), findsNothing);
  });

  testWidgets('returns an authenticated user to a protected deep link', (
''',
  );
  file.writeAsStringSync(source);
}

String _removeTest(String source, String name) {
  final start = source.indexOf("  testWidgets('$name'");
  if (start < 0) {
    throw StateError('Reference removal test contract changed: $name');
  }
  final end = source.indexOf('  testWidgets(', start + 1);
  if (end < 0) {
    throw StateError('Could not find the test following: $name');
  }
  return source.replaceRange(start, end, '');
}

void _updateGuidance(Directory root) {
  _replaceInFile(File('${root.path}/AGENTS.md'), {
    'The\nreference feature is the normative example; follow its boundaries unless a\n'
            'requirement explicitly needs a different design.':
        'Follow `docs/recipes.md` unless a requirement explicitly needs a different\n'
        'design.',
    'both reference\n  locales': 'all supported\n  locales',
  });
  _replaceInFile(File('${root.path}/docs/architecture.md'), {
    '      reference/\n'
            '        data/\n'
            '        domain/\n'
            '        application/\n'
            '        presentation/\n':
        '',
    '\nThe reference feature is the executable example for repository contracts,\n'
            'provider replacement, controllers, pagination, forms, and widget tests. Follow\n'
            '`docs/recipes.md` to build an equivalent feature. If the product does not need\n'
            'the example, follow `docs/remove-reference-feature.md`; do not remove shared\n'
            'infrastructure along with it.\n':
        '\n',
  });
  _replaceInFile(File('${root.path}/docs/recipes.md'), {
    'Use the reference feature as the executable pattern. Replace `catalog` and the\n'
            'example type names below with product-neutral names appropriate to the feature.':
        'Use these steps as the executable pattern. Replace `catalog` and the example\n'
        'type names below with product-neutral names appropriate to the feature.',
  });
  _replaceInFile(File('${root.path}/lib/src/features/README.md'), {
    'Use `features/reference` as the normative vertical-slice example and follow\n'
            '`docs/recipes.md` for placement, dependency direction, routes, repository\n'
            'replacement, and tests. Follow `docs/remove-reference-feature.md` when the\n'
            'example is no longer needed.\n':
        'Follow `docs/recipes.md` for placement, dependency direction, routes,\n'
        'repository replacement, and tests.\n',
  });
}

void _replaceInFile(File file, Map<String, String> replacements) {
  var source = file.readAsStringSync();
  for (final entry in replacements.entries) {
    source = _replaceRequired(source, entry.key, entry.value);
  }
  file.writeAsStringSync(source);
}

List<String> _findReferenceMentions(Directory root) {
  final pattern = RegExp(
    r'features/reference|Reference(?:List|Detail|Edit)|reference(?:List|Detail|Edit)',
  );
  final files = <File>[
    File('${root.path}/AGENTS.md'),
    File('${root.path}/docs/architecture.md'),
    File('${root.path}/docs/recipes.md'),
    ...Directory('${root.path}/lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart')),
    ...Directory('${root.path}/test')
        .listSync(recursive: true)
        .whereType<File>()
        .where((file) => file.path.endsWith('.dart')),
  ];
  final matches = <String>[];
  for (final file in files) {
    final lines = file.readAsLinesSync();
    for (var index = 0; index < lines.length; index++) {
      if (pattern.hasMatch(lines[index])) {
        matches.add('${file.path}:${index + 1}:${lines[index]}');
      }
    }
  }
  return matches;
}

String _replaceRequired(String source, String pattern, String replacement) {
  if (!source.contains(pattern)) {
    throw StateError('Reference removal contract changed: $pattern');
  }
  return source.replaceFirst(pattern, replacement);
}

void _deleteDirectory(Directory directory) {
  if (!directory.existsSync()) {
    throw StateError('Reference directory not found: ${directory.path}');
  }
  directory.deleteSync(recursive: true);
}
