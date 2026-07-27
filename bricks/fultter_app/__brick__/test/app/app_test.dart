import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/src/app/app.dart';
import 'package:{{app_name}}/src/app/display_settings.dart';
import 'package:{{app_name}}/src/app/providers.dart';
import 'package:{{app_name}}/src/core/config/app_config.dart';
import 'package:{{app_name}}/src/core/config/app_environment.dart';
import 'package:{{app_name}}/src/core/observability/observability.dart';

void main() {
  testWidgets('supports system, light, and dark theme modes', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.light;
    addTearDown(
      tester.platformDispatcher.clearPlatformBrightnessTestValue,
    );
    final container = await _pumpApp(tester);

    for (final mode in ThemeMode.values) {
      container.read(themeModeProvider.notifier).setThemeMode(mode);
      await tester.pumpAndSettle();

      expect(
        tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        mode,
      );
      expect(
        Theme.of(tester.element(find.byType(Scaffold))).brightness,
        mode == ThemeMode.dark ? Brightness.dark : Brightness.light,
      );
    }
  });

  testWidgets('lets users select a theme from the reference control', (
    tester,
  ) async {
    final container = await _pumpApp(tester);

    await tester.tap(find.byTooltip('Choose theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Dark theme'));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.dark);
  });

  testWidgets('renders English and Simplified Chinese localizations', (
    tester,
  ) async {
    final container = await _pumpApp(tester);
    expect(find.text('Ready.'), findsOneWidget);

    container
        .read(localeProvider.notifier)
        .setLocale(const Locale('zh', 'CN'));
    await tester.pumpAndSettle();

    expect(find.text('准备就绪。'), findsOneWidget);
    expect(find.byTooltip('选择主题'), findsOneWidget);
  });

  testWidgets(
    'falls back to English for an unsupported locale',
    (tester) async {
      await _pumpApp(tester, locale: const Locale('fr'));

      expect(find.text('Ready.'), findsOneWidget);
    },
  );

  testWidgets('reference controls do not clip at 200 percent text scale', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(
      tester.platformDispatcher.clearTextScaleFactorTestValue,
    );

    await _pumpApp(tester);
    await tester.tap(find.byTooltip('Choose theme'));
    await tester.pumpAndSettle();

    expect(find.text('System theme'), findsOneWidget);
    expect(find.text('Light theme'), findsOneWidget);
    expect(find.text('Dark theme'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

Future<ProviderContainer> _pumpApp(
  WidgetTester tester, {
  Locale? locale,
}) async {
  final container = ProviderContainer(
    overrides: [
      appConfigProvider.overrideWithValue(
        const AppConfig(
          environment: AppEnvironment.dev,
          apiBaseUrl: 'https://api.example.com',
          enableNetworkLogs: true,
          allowInsecureHttpForDebug: false,
        ),
      ),
      observabilityProvider.overrideWithValue(NoopObservability()),
    ],
  );
  addTearDown(container.dispose);
  if (locale != null) {
    container.read(localeProvider.notifier).setLocale(locale);
  }

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: const App(),
    ),
  );
  await tester.pumpAndSettle();
  return container;
}
