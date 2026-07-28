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

  final packageMatch = RegExp(
    r'^name:\s*([a-z][a-z0-9_]*)\s*$',
    multiLine: true,
  ).firstMatch(pubspec.readAsStringSync());
  if (packageMatch == null) {
    stderr.writeln('Could not read the generated package name.');
    exitCode = 65;
    return;
  }
  final packageName = packageMatch.group(1)!;

  _deleteDirectory(Directory('${root.path}/lib/src/features/reference'));
  _deleteDirectory(Directory('${root.path}/test/features/reference'));

  final router = File('${root.path}/lib/src/app/router.dart');
  var routerSource = router.readAsStringSync();
  for (final import in const [
    "import '../features/reference/presentation/reference_detail_page.dart';\n",
    "import '../features/reference/presentation/reference_edit_page.dart';\n",
    "import '../features/reference/presentation/reference_list_page.dart';\n",
  ]) {
    routerSource = _replaceRequired(routerSource, import, '');
  }
  routerSource = _replaceRequired(
    routerSource,
    "  static const referenceDetail = '/references/:id';\n"
        "  static const referenceEdit = '/references/:id/edit';\n",
    '',
  );
  routerSource = _replaceRequired(
    routerSource,
    "\n  static String referenceDetailPath(String id) {\n"
        "    return '/references/\${Uri.encodeComponent(id)}';\n"
        "  }\n\n"
        "  static String referenceEditPath(String id) {\n"
        "    return '\${referenceDetailPath(id)}/edit';\n"
        "  }\n",
    '',
  );
  routerSource = _replaceRequired(
    routerSource,
    '        builder: (context, state) => const ReferenceListPage(),',
    '        builder: (context, state) => const ProtectedHomePage(),',
  );
  routerSource = _replaceRequired(
    routerSource,
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
  routerSource += '''

class ProtectedHomePage extends StatelessWidget {
  const ProtectedHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: const Text('Quality Gate App')),
      body: Center(child: Text(localizations.publicReady)),
    );
  }
}
''';
  router.writeAsStringSync(routerSource);

  File('${root.path}/test/app/app_test.dart').writeAsStringSync('''
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:$packageName/src/app/app.dart';
import 'package:$packageName/src/app/providers.dart';
import 'package:$packageName/src/core/config/app_config.dart';
import 'package:$packageName/src/core/observability/observability.dart';
import 'package:$packageName/src/features/auth/domain/auth.dart';

void main() {
  testWidgets('neutral starter remains runnable after reference removal', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(AppConfig.fromEnvironment()),
          observabilityProvider.overrideWithValue(NoopObservability()),
          authCredentialStoreProvider.overrideWithValue(_AuthenticatedStore()),
        ],
        child: const App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.byType(Scaffold), findsOneWidget);
  });
}

class _AuthenticatedStore implements AuthCredentialStore {
  @override
  Future<void> clear() async {}

  @override
  Future<AuthCredential?> read() async => const AuthCredential('token');

  @override
  Future<void> write(AuthCredential credential) async {}
}
''');

  final remainingReferences = _findReferenceMentions(root);
  if (remainingReferences.isNotEmpty) {
    stderr.writeln(remainingReferences.join('\n'));
    stderr.writeln('Reference feature code remains after removal.');
    exitCode = 1;
  }
}

List<String> _findReferenceMentions(Directory root) {
  final pattern = RegExp(r'features/reference|Reference(?:List|Detail|Edit)');
  final matches = <String>[];
  for (final relativeRoot in const ['lib', 'test']) {
    final directory = Directory('${root.path}/$relativeRoot');
    for (final entity in directory.listSync(recursive: true)) {
      if (entity is! File) {
        continue;
      }
      final lines = entity.readAsLinesSync();
      for (var index = 0; index < lines.length; index++) {
        if (pattern.hasMatch(lines[index])) {
          matches.add('${entity.path}:${index + 1}:${lines[index]}');
        }
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
