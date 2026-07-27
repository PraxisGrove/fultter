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

- [Project rules for humans and AI tools](AGENTS.md)
- [Architecture](docs/architecture.md)
- [Development recipes](docs/recipes.md)
- [Remove the reference feature](docs/remove-reference-feature.md)
- [External integration template](docs/external-integration.md)
- [Configuration](docs/configuration.md)
- [Localization](docs/localization.md)
- [Authentication and route guards](docs/authentication.md)
- [Networking and failures](docs/networking.md)
- [Observability](docs/observability.md)
- [Security](docs/security.md)
- [Release](docs/release.md)
