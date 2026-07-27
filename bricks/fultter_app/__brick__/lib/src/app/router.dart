import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:{{app_name}}/l10n/app_localizations.dart';

import '../features/auth/domain/auth.dart';
import 'display_settings.dart';
import 'providers.dart';

abstract final class AppRoutes {
  static const protectedHome = '/';
  static const protectedDetail = '/protected/:section';
  static const entry = '/sign-in';
  static const loading = '/loading';
  static const public = '/public';
}

final class AuthRouteRedirector {
  const AuthRouteRedirector();

  String? redirect(AuthState authState, Uri location) {
    final path = location.path;
    final isPublic = path == AppRoutes.public;
    final isEntry = path == AppRoutes.entry;
    final isLoading = path == AppRoutes.loading;

    switch (authState) {
      case AuthState.loading:
        if (isPublic || isLoading) {
          return null;
        }
        return _routeWithReturnLocation(AppRoutes.loading, location);
      case AuthState.unauthenticated:
      case AuthState.sessionExpired:
        if (isPublic || isEntry) {
          return null;
        }
        return _routeWithReturnLocation(
          AppRoutes.entry,
          location,
          sessionExpired: authState == AuthState.sessionExpired,
        );
      case AuthState.authenticated:
        if (!isEntry && !isLoading) {
          return null;
        }
        return _safeReturnLocation(location) ?? AppRoutes.protectedHome;
    }
  }

  String _routeWithReturnLocation(
    String route,
    Uri location, {
    bool sessionExpired = false,
  }) {
    final returnLocation = _returnLocation(location);
    final queryParameters = <String, String>{
      if (returnLocation != null) 'from': returnLocation,
      if (sessionExpired) 'expired': 'true',
    };
    return Uri(path: route, queryParameters: queryParameters).toString();
  }

  String? _returnLocation(Uri location) {
    if (location.path == AppRoutes.entry ||
        location.path == AppRoutes.loading) {
      return _safeReturnLocation(location);
    }
    if (location.path == AppRoutes.public) {
      return null;
    }
    return location.toString();
  }

  String? _safeReturnLocation(Uri location) {
    final rawLocation = location.queryParameters['from'];
    if (rawLocation == null) {
      return null;
    }

    final parsed = Uri.tryParse(rawLocation);
    if (parsed == null ||
        rawLocation.startsWith('//') ||
        parsed.hasScheme ||
        parsed.hasAuthority ||
        !parsed.path.startsWith('/') ||
        parsed.path == AppRoutes.entry ||
        parsed.path == AppRoutes.loading ||
        parsed.path == AppRoutes.public) {
      return null;
    }
    return parsed.toString();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authController = ref.watch(authControllerProvider);
  const redirector = AuthRouteRedirector();
  final router = GoRouter(
    refreshListenable: authController,
    redirect: (context, state) {
      return redirector.redirect(authController.state, state.uri);
    },
    routes: [
      GoRoute(
        path: AppRoutes.protectedHome,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: AppRoutes.protectedDetail,
        builder: (context, state) {
          return ProtectedDetailPage(section: state.pathParameters['section']!);
        },
      ),
      GoRoute(
        path: AppRoutes.entry,
        builder: (context, state) {
          return EntryPage(
            sessionExpired: state.uri.queryParameters['expired'] == 'true',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.loading,
        builder: (context, state) => const AuthLoadingPage(),
      ),
      GoRoute(
        path: AppRoutes.public,
        builder: (context, state) => const PublicPage(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});

class AuthLoadingPage extends StatelessWidget {
  const AuthLoadingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: CircularProgressIndicator(
          semanticsLabel: localizations.authLoading,
        ),
      ),
    );
  }
}

class EntryPage extends StatelessWidget {
  const EntryPage({
    required this.sessionExpired,
    super.key,
  });

  final bool sessionExpired;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: const Text('{{app_display_name}}')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            sessionExpired
                ? localizations.authSessionExpired
                : localizations.authRequired,
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class PublicPage extends StatelessWidget {
  const PublicPage({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: const Text('{{app_display_name}}')),
      body: Center(child: Text(localizations.publicReady)),
    );
  }
}

class ProtectedDetailPage extends StatelessWidget {
  const ProtectedDetailPage({
    required this.section,
    super.key,
  });

  final String section;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{{app_display_name}}')),
      body: Center(child: Text(section)),
    );
  }
}

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
