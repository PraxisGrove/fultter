# Remove the reference feature

The reference vertical slice is removable. These steps leave a neutral,
protected starter screen while preserving configuration, failures, networking,
security, observability, authentication, routing, theme, and localization.

## 1. Add the neutral screen

Create `lib/src/app/home_page.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:{{app_name}}/l10n/app_localizations.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('{{app_display_name}}')),
      body: Center(child: Text(AppLocalizations.of(context)!.homeReady)),
    );
  }
}
```

The route remains protected, so an app without a stored credential still opens
the neutral sign-in boundary. Integrate a real identity provider separately;
do not make the home route public merely to bypass authentication.

## 2. Remove reference routing

In `lib/src/app/router.dart`:

1. Delete the three imports from `features/reference/presentation`.
2. Add `import 'home_page.dart';`.
3. Delete `AppRoutes.referenceDetail`, `AppRoutes.referenceEdit`,
   `referenceDetailPath`, and `referenceEditPath`.
4. Change the `AppRoutes.protectedHome` route builder to
   `const HomePage()`.
5. Delete the `GoRoute` blocks for `AppRoutes.referenceEdit` and
   `AppRoutes.referenceDetail`.

Keep `AuthRouteRedirector`, `/sign-in`, `/loading`, `/public`, and
`/protected/:section`; they are shared authentication/routing examples.

## 3. Delete reference source and tests

Delete exactly these directories:

```txt
lib/src/features/reference/
test/features/reference/
```

No package in `pubspec.yaml` is reference-only, so remove no dependency.

## 4. Remove reference localization

From every `lib/l10n/app_*.arb`, delete all keys beginning with `reference`.
Keep `homeReady`, authentication, public-route, and theme keys. Run:

```sh
flutter gen-l10n
```

## 5. Update generated guidance

The root rules and recipes describe the example while it exists. After removal:

- In `AGENTS.md`, replace the introductory reference-feature sentence with
  "Follow `docs/recipes.md` unless a requirement explicitly needs a different
  design." Change "both reference locales" to "all supported locales".
- In `docs/architecture.md`, remove the `reference/` subtree and the final
  reference-feature paragraph. Keep the dependency-direction diagram.
- In `docs/recipes.md`, replace the opening reference-feature sentence with
  "Use these steps as the executable pattern."

Keep this removal guide as evidence of the deleted example's boundary.

## 6. Replace reference-specific app tests

In `test/app/app_test.dart`:

- Change visible `References` / `参考项目` assertions to `Ready.` /
  `准备就绪。`.
- Remove the theme-menu interaction test and the reference-control 200% text
  scale test. Those controls belonged to the deleted page.
- Keep direct theme-mode, locale fallback, auth redirect, public route, deep
  link, and session-expiry tests.
- Add a neutral home widget test that expects `Ready.` for an authenticated
  user and confirms no reference route or title is rendered.

If the product still needs an in-app theme selector, add it as a separate
product requirement instead of retaining a reference-feature widget.

## 7. Verify the neutral app

Search for stale references and run the full gate:

```sh
test -z "$(rg -n "features/reference|Reference(List|Detail|Edit)|referenceRepositoryProvider|reference(List|Detail|Edit)" lib test AGENTS.md docs/architecture.md docs/recipes.md || true)"
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter run --dart-define-from-file=config/dev.json
```

The expected result is a runnable app with shared infrastructure intact, no
reference source/routes/tests/localization, a neutral authenticated home screen,
and the existing unauthenticated entry screen.
