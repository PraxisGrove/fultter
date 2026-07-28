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
      auth/
        data/
        domain/
        presentation/
      reference/
        data/
        domain/
        application/
        presentation/
```

## Boundaries

- `app`: startup, dependency wiring, routing, and top-level UI.
- `core`: shared infrastructure used across features.
- `features`: product-specific code.

For data-backed features, dependency direction is:

```txt
presentation -> application -> domain <- data
                                  ^
                                  |
                         core/failures only
```

Domain and presentation public contracts must not import Flutter, Dio, secure
storage implementations, Sentry, DTOs, or provider SDKs. Domain code may depend
on the backend-neutral failure contract. Keep Dio, DTO conversion, and response
mapping in data or infrastructure implementations.

## Dependency Injection

Riverpod is used for dependency wiring. Infrastructure services are provided from `lib/src/app/providers.dart`, which makes them easy to override in tests.

`apiClientProvider` and `failureMapperProvider` expose replaceable interfaces.
Override providers at the nearest `ProviderScope`; do not add a mutable global
service locator.

`authCredentialStoreProvider` keeps credential persistence replaceable, while
`authControllerProvider` owns backend-neutral session state. See
`docs/authentication.md` for the state and routing contracts.

The reference feature is the executable example for repository contracts,
provider replacement, controllers, pagination, forms, and widget tests. Follow
`docs/recipes.md` to build an equivalent feature. If the product does not need
the example, follow `docs/remove-reference-feature.md`; do not remove shared
infrastructure along with it.
