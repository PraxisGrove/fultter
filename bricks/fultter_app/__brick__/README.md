# {{app_display_name}}

{{description}}

## Run

```sh
flutter run --dart-define-from-file=config/dev.json
```

## Quality

```sh
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

## Documentation

Start here:

- [Project rules for humans and AI tools](AGENTS.md)
- [Development recipes](docs/recipes.md)

Read by scenario:

- [Architecture](docs/architecture.md)
- [Authentication and route guards](docs/authentication.md)
- [Networking and failures](docs/networking.md)
- [Configuration](docs/configuration.md)
- [Observability](docs/observability.md)
- [Security](docs/security.md)
- [Release](docs/release.md)
- [External integration template](docs/external-integration.md)
- [Remove the reference feature](docs/remove-reference-feature.md)
