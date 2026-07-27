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

- [Architecture](docs/architecture.md)
- [Configuration](docs/configuration.md)
- [Localization](docs/localization.md)
- [Observability](docs/observability.md)
- [Security](docs/security.md)
- [Release](docs/release.md)
