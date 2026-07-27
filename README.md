# Fultter

Mason bricks for starting Flutter mobile apps with logging, observability, basic security, networking, routing, CI, and release workflow scaffolding.

## Bricks

- `fultter_app`: Generates a mobile-first Flutter app skeleton.

## Requirements

- Flutter stable SDK
- Dart SDK bundled with Flutter
- Mason CLI

Install Mason:

```sh
dart pub global activate mason_cli
```

## Use Locally

```sh
mason get
mason make fultter_app
```

Recommended answers:

```txt
app_name: my_app
app_display_name: My App
bundle_id: com.example.myapp
org_domain: com.example
use_sentry: false
```

The brick generates app code first, then its post-generation hook runs `flutter create` to create Android/iOS platform folders from your local Flutter SDK.

Generation validates `app_name`, `org_domain`, and `bundle_id` before invoking
Flutter. See `bricks/fultter_app/README.md` for the accepted formats and the
exact dev, staging, prod, analysis, and test commands printed after success.

## Scope

This template intentionally focuses on infrastructure:

- Dart `logging` abstraction
- no-op observability by default, with optional Sentry integration behind a small interface
- Riverpod dependency wiring
- Dio networking
- basic security: redaction, secure storage, HTTPS guardrails
- go_router
- environment configuration with `--dart-define-from-file`
- GitHub Actions for CI, integration tests, release builds, and manual deploy workflows

It does not generate concrete business features such as login, profile, orders, or payments.
