import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{app_name}}/l10n/app_localizations.dart';

import 'app_theme.dart';
import 'display_settings.dart';
import 'router.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: '{{app_display_name}}',
      routerConfig: router,
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      localeResolutionCallback: _resolveLocale,
    );
  }
}

Locale _resolveLocale(
  Locale? requestedLocale,
  Iterable<Locale> supportedLocales,
) {
  if (requestedLocale != null) {
    for (final supportedLocale in supportedLocales) {
      if (supportedLocale == requestedLocale ||
          (supportedLocale.languageCode == requestedLocale.languageCode &&
              supportedLocale.countryCode == null)) {
        return supportedLocale;
      }
    }
  }

  return const Locale('en');
}
