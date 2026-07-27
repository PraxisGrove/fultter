# Architecture

This project uses a light layered structure.

```txt
lib/
  main.dart
  src/
    app/
      app.dart
      bootstrap.dart
      providers.dart
      router.dart
    core/
      config/
      failures/
      logging/
      networking/
      observability/
      security/
    features/
```

## Boundaries

- `app`: startup, dependency wiring, routing, and top-level UI.
- `core`: shared infrastructure used across features.
- `features`: product-specific code.

Domain and presentation public contracts must not import Flutter, Dio, secure
storage implementations, Sentry, DTOs, or provider SDKs. Domain code may depend
on the backend-neutral failure contract. Keep Dio, DTO conversion, and response
mapping in data or infrastructure implementations.

## Dependency Injection

Riverpod is used for dependency wiring. Infrastructure services are provided from `lib/src/app/providers.dart`, which makes them easy to override in tests.

`apiClientProvider` and `failureMapperProvider` expose replaceable interfaces.
Override providers at the nearest `ProviderScope`; do not add a mutable global
service locator.
