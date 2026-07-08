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

Business features should not import Sentry, Dio, or secure storage directly unless there is a clear reason. Prefer depending on small interfaces exposed from `core`.

## Dependency Injection

Riverpod is used for dependency wiring. Infrastructure services are provided from `lib/src/app/providers.dart`, which makes them easy to override in tests.
