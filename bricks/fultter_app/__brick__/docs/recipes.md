# Development recipes

Use the reference feature as the executable pattern. Replace `catalog` and the
example type names below with product-neutral names appropriate to the feature.

## Add a feature

1. Create `lib/src/features/catalog/{domain,data,application,presentation}`.
2. In `domain`, define immutable entities, input values, and an abstract
   repository. Return domain values and throw or surface shared `Failure`
   values; import no Flutter, Riverpod, Dio, storage implementation, DTO, or
   provider SDK.
3. In `data`, add validated DTOs/mappers and a repository implementation. Map
   transport and serialization errors to `Failure` before they cross the data
   boundary.
4. In `application`, add `catalogRepositoryProvider` and focused controllers.
   Controllers expose explicit loading/data/empty/failure states and guard
   concurrent requests or submissions.
5. In `presentation`, render those states and call controller methods for user
   intent. Localize all visible text and add semantics to actionable controls.
6. Add the route using the route recipe below.
7. Mirror each layer under `test/features/catalog` and run the quality commands.

Do not add a layer that is empty or only forwards one call. Keep the dependency
direction `presentation -> application -> domain <- data`.

## Add a route

1. Add a constant to `AppRoutes` in `lib/src/app/router.dart`. For parameters,
   add a path builder that applies `Uri.encodeComponent`.
2. Add a `GoRoute` to `routerProvider` and read required path parameters with a
   non-null assertion only when the route pattern guarantees them.
3. Decide whether the route is public, an entry/loading route, or protected.
   Protected is the default. If public, update `AuthRouteRedirector` explicitly;
   do not infer public access from a path prefix.
4. Keep `from` return locations local and protected. Do not allow a scheme,
   authority, protocol-relative URL, or entry/loading/public loop.
5. Extend `test/app/router_redirect_test.dart` for every auth state, deep links,
   and unsafe return locations. Add a widget navigation test for the user flow.

## Add tests

1. Put unit/widget tests under the path matching the source file.
2. Build an in-memory fake that implements the domain contract, or override the
   relevant Riverpod provider. Do not mock Dio in a controller or widget test.
3. Cover success plus meaningful loading, empty, validation, failure, retry,
   cancellation, and concurrency behavior.
4. Use `Completer` to hold pending operations when testing duplicate-request
   protection; do not use sleeps.
5. For UI, test semantics, both locales when strings change, and 200% text scale
   for changed controls.
6. Run the focused test, then `dart format --set-exit-if-changed .`,
   `flutter analyze`, and `flutter test`.

## Replace a fake repository with Dio

1. Keep the domain repository unchanged. Add the remote DTO and a Dio-backed
   implementation under the feature's `data` directory.
2. Inject `ApiClient`, not a newly constructed `Dio`, into the implementation.
   Pass cancellation tokens through long-lived operations where appropriate.
3. Validate response shapes in DTO mapping. Map API-specific error envelopes
   inside the data layer and expose only shared or feature-domain failures.
4. Change the feature repository provider to construct the remote repository:

   ```dart
   final catalogRepositoryProvider = Provider<CatalogRepository>((ref) {
     return DioCatalogRepository(ref.watch(apiClientProvider));
   });
   ```

5. Keep the fake for deterministic tests and override the provider in widget
   tests. Add data-layer tests for paths, payloads, malformed responses, mapped
   failures, and cancellation.
6. Update `docs/networking.md` if the API introduces new headers or an error
   envelope. Never log bodies or credentials.

## Add a locale

1. Copy `lib/l10n/app_en.arb` to `lib/l10n/app_<locale>.arb`.
2. Set `@@locale`, preserve every key, and translate every message.
3. Run `flutter gen-l10n` and use `AppLocalizations.of(context)!` in widgets.
4. Add a widget test that selects the locale through `localeProvider`, and
   retain the English fallback test for unsupported locales.
5. Run format, analysis, and all tests. See `docs/localization.md` for the
   fallback contract.

## Add an external integration

Complete every field and gate in `docs/external-integration.md` before enabling
the provider. At minimum: add and justify the package, classify client settings
versus secrets, document native changes, implement behind an existing or small
backend-neutral interface, define absence/initialization/runtime failure
behavior, redact provider output, and add deterministic verification without a
real account.
