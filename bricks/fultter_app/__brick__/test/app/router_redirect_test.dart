import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/src/app/router.dart';
import 'package:{{app_name}}/src/features/auth/domain/auth.dart';

void main() {
  const redirector = AuthRouteRedirector();

  test('covers every auth state and route boundary', () {
    final expectedPaths = <AuthState, Map<String, String?>>{
      AuthState.loading: {
        AppRoutes.protectedHome: AppRoutes.loading,
        AppRoutes.entry: AppRoutes.loading,
        AppRoutes.loading: null,
        AppRoutes.public: null,
      },
      AuthState.unauthenticated: {
        AppRoutes.protectedHome: AppRoutes.entry,
        AppRoutes.entry: null,
        AppRoutes.loading: AppRoutes.entry,
        AppRoutes.public: null,
      },
      AuthState.authenticated: {
        AppRoutes.protectedHome: null,
        AppRoutes.entry: AppRoutes.protectedHome,
        AppRoutes.loading: AppRoutes.protectedHome,
        AppRoutes.public: null,
      },
      AuthState.sessionExpired: {
        AppRoutes.protectedHome: AppRoutes.entry,
        AppRoutes.entry: null,
        AppRoutes.loading: AppRoutes.entry,
        AppRoutes.public: null,
      },
    };

    for (final stateEntry in expectedPaths.entries) {
      for (final routeEntry in stateEntry.value.entries) {
        final redirect = redirector.redirect(
          stateEntry.key,
          Uri.parse(routeEntry.key),
        );
        expect(
          redirect == null ? null : Uri.parse(redirect).path,
          routeEntry.value,
          reason: '${stateEntry.key} at ${routeEntry.key}',
        );
      }
    }
  });

  test('loading protected navigation moves to loading once', () {
    final redirect = redirector.redirect(
      AuthState.loading,
      Uri.parse('/protected/orders?tab=open'),
    );

    expect(Uri.parse(redirect!).path, AppRoutes.loading);
    expect(
      Uri.parse(redirect).queryParameters['from'],
      '/protected/orders?tab=open',
    );
    expect(redirector.redirect(AuthState.loading, Uri.parse(redirect)), isNull);
  });

  test('public navigation remains available in every auth state', () {
    for (final state in AuthState.values) {
      expect(redirector.redirect(state, Uri.parse('/public')), isNull);
    }
  });

  test('loading restoration carries a protected deep link to entry', () {
    final loadingRedirect = redirector.redirect(
      AuthState.loading,
      Uri.parse('/protected/orders?tab=open'),
    );

    final entryRedirect = redirector.redirect(
      AuthState.unauthenticated,
      Uri.parse(loadingRedirect!),
    );

    final uri = Uri.parse(entryRedirect!);
    expect(uri.path, AppRoutes.entry);
    expect(uri.queryParameters['from'], '/protected/orders?tab=open');
  });

  test('unauthenticated protected navigation preserves a deep link', () {
    final redirect = redirector.redirect(
      AuthState.unauthenticated,
      Uri.parse('/protected/orders?tab=open'),
    );

    final uri = Uri.parse(redirect!);
    expect(uri.path, AppRoutes.entry);
    expect(uri.queryParameters['from'], '/protected/orders?tab=open');
    expect(redirector.redirect(AuthState.unauthenticated, uri), isNull);
  });

  test('authenticated entry navigation returns to the protected target', () {
    final entry = Uri(
      path: AppRoutes.entry,
      queryParameters: {'from': '/protected/orders?tab=open'},
    );

    final redirect = redirector.redirect(AuthState.authenticated, entry);

    expect(redirect, '/protected/orders?tab=open');
    expect(
      redirector.redirect(AuthState.authenticated, Uri.parse(redirect!)),
      isNull,
    );
  });

  test('authenticated entry navigation defaults to protected home', () {
    expect(
      redirector.redirect(AuthState.authenticated, Uri.parse(AppRoutes.entry)),
      AppRoutes.protectedHome,
    );
  });

  test('session expiry redirects and marks the entry state', () {
    final redirect = redirector.redirect(
      AuthState.sessionExpired,
      Uri.parse('/protected/account'),
    );

    final uri = Uri.parse(redirect!);
    expect(uri.path, AppRoutes.entry);
    expect(uri.queryParameters['from'], '/protected/account');
    expect(uri.queryParameters['expired'], 'true');
    expect(redirector.redirect(AuthState.sessionExpired, uri), isNull);
  });

  test('external and non-protected return locations are ignored', () {
    for (final returnLocation in [
      'https://example.com/account',
      '//example.com/account',
      '///example.com/account',
      AppRoutes.entry,
      AppRoutes.loading,
      AppRoutes.public,
    ]) {
      final entry = Uri(
        path: AppRoutes.entry,
        queryParameters: {'from': returnLocation},
      );
      expect(
        redirector.redirect(AuthState.authenticated, entry),
        AppRoutes.protectedHome,
      );
    }
  });
}
