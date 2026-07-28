# Project Rules

This file is the implementation contract for humans and AI coding tools working
in this generated Flutter application. Read it before changing code. The
reference feature is the normative example; follow its boundaries unless a
requirement explicitly needs a different design.

## Architecture and placement

```txt
lib/src/
  app/                         # bootstrap wiring, router, theme, locale
  core/                        # backend-neutral shared infrastructure
  features/<feature>/
    domain/                    # entities and abstract repositories
    data/                      # DTOs and repository implementations
    application/               # state/controllers and feature providers
    presentation/              # Flutter pages and widgets
```

- Put business behavior in `features/<feature>`, not `app` or `core`.
- Start small, but use the four feature layers when a feature has persistence,
  remote data, or non-trivial state. Do not create generic base repositories,
  controllers, or widgets without two concrete consumers.
- Domain code may import other domain code and
  `lib/src/core/failures/failure.dart`. It must not import Flutter, Riverpod,
  Dio, secure-storage implementations, DTOs, Sentry, or another provider SDK.
- Data code implements domain contracts. Keep Dio calls, wire formats, DTO
  validation, and transport-to-`Failure` conversion here.
- Application code owns asynchronous state and concurrency guards. It depends
  on domain contracts, never on a concrete repository.
- Presentation code renders application state and sends user intent to
  controllers. Do not call Dio, storage, or provider SDKs from widgets.
- Register application-wide infrastructure in
  `lib/src/app/providers.dart`. Register feature repositories and controllers
  in the feature's `application/*_providers.dart`. Override providers at the
  nearest `ProviderScope`; do not add a mutable global service locator.
- Define route names and route construction in `lib/src/app/router.dart`.
  Preserve the auth redirect rules and reject external return locations.
- Put every user-visible string in `lib/l10n/app_en.arb` and translate it in
  every supported ARB file. Do not add string literals to widgets.

## Required behavior

- Expose expected loading, data, empty, failure, and retry states.
- Preserve existing list data when a later page fails. Suppress concurrent
  pagination and duplicate form submissions.
- Map infrastructure errors to `Failure`; never expose `DioException` through
  domain, application, or presentation APIs.
- Keep cancellation distinct from retryable transport failures.
- Treat every client configuration value as public. Never commit credentials,
  signing material, private keys, admin tokens, or server secrets.
- Keep production network-body logging disabled and redact sensitive metadata.
- External services are opt-in. Their absence or initialization failure must
  follow the documented failure behavior and must not silently weaken privacy.
- Keep controls usable with meaningful semantics and at 200% text scale.

## Commands

Run from the generated project root:

```sh
flutter pub get
flutter run --dart-define-from-file=config/dev.json
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Use `flutter test test/path/to/file_test.dart` while iterating, then run the
complete quality sequence before finishing. Run `flutter gen-l10n` after ARB
changes when no build or test command has generated localization output yet.

## Tests

- Mirror `lib/src/...` under `test/...` and name tests `*_test.dart`.
- Unit-test domain mapping, repositories, controller transitions, concurrency,
  validation, failure, and retry behavior.
- Widget-test primary user flows, navigation, empty/error states, both reference
  locales, theme behavior, semantics, and 200% text scaling where UI changes.
- Override repository and infrastructure providers with deterministic fakes.
  Tests must not require public APIs, sleeps, secrets, accounts, or network
  services.

## Prohibited patterns

- Raw `DioException`, DTO, or provider SDK types crossing a data boundary.
- Network, storage, or service-locator calls from widgets or domain code.
- Secrets in `config/*.json`, source, tests, logs, or workflow files.
- Unredacted request/response bodies or sensitive headers in logs.
- Timing-dependent tests, arbitrary delays, or live third-party calls.
- A new framework, state system, router, or architecture alongside the existing
  Riverpod/go_router/layered feature structure.
- Unrelated refactors or speculative abstractions in a feature change.

## Completion criteria

A change is complete only when placement and dependency direction follow these
rules; user-visible text is localized; failure, loading, retry, and concurrency
behavior is covered as applicable; docs reflect changed commands or contracts;
and format, analysis, and all tests pass. Follow `docs/recipes.md` for common
changes, `docs/remove-reference-feature.md` to remove the example, and
`docs/external-integration.md` before adding an external provider.
