import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:{{app_name}}/l10n/app_localizations.dart';

import 'display_settings.dart';

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final localizations = AppLocalizations.of(context)!;
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('{{app_display_name}}'),
        actions: [
          PopupMenuButton<ThemeMode>(
            initialValue: themeMode,
            tooltip: localizations.themeMenuTooltip,
            icon: const Icon(Icons.brightness_6_outlined),
            onSelected: ref.read(themeModeProvider.notifier).setThemeMode,
            itemBuilder: (context) => [
              _themeMenuItem(
                mode: ThemeMode.system,
                selectedMode: themeMode,
                label: localizations.themeSystem,
              ),
              _themeMenuItem(
                mode: ThemeMode.light,
                selectedMode: themeMode,
                label: localizations.themeLight,
              ),
              _themeMenuItem(
                mode: ThemeMode.dark,
                selectedMode: themeMode,
                label: localizations.themeDark,
              ),
            ],
          ),
        ],
      ),
      body: Center(
        child: Text(localizations.homeReady),
      ),
    );
  }
}

PopupMenuItem<ThemeMode> _themeMenuItem({
  required ThemeMode mode,
  required ThemeMode selectedMode,
  required String label,
}) {
  return PopupMenuItem<ThemeMode>(
    value: mode,
    child: Row(
      children: [
        Icon(
          mode == selectedMode
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
        ),
        const SizedBox(width: 12),
        Flexible(child: Text(label)),
      ],
    ),
  );
}
