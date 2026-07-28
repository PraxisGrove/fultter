# Fultter

Mason bricks for starting Flutter mobile apps with logging, observability, basic security, networking, routing, CI, and release workflow scaffolding.

## Bricks

- `fultter_app`: Generates a mobile-first Flutter app skeleton.

## Requirements

- Flutter 3.44.x stable (CI pins 3.44.8)
- Dart 3.12.x bundled with Flutter
- Mason CLI 0.1.2

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

## Repository Quality Gate

Every pull request generates the single supported default profile with Sentry
disabled and without credentials, then runs dependency installation, formatting,
analysis, all unit/widget tests, and an Android debug build. A separate macOS job
generates the same profile and builds iOS without code signing. Each operation is
a separate workflow step so failures identify the broken stage.

The gate also removes the complete reference feature from a temporary generated
app, replaces it with a neutral authenticated home, and reruns formatting,
analysis, and the remaining tests. Run the same default generation locally with:

```sh
dart pub global activate mason_cli 0.1.2
tool/generate_default_app.sh build/generated_app
cd build/generated_app
flutter pub get
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug --dart-define-from-file=config/dev.json
```

Flutter 3.44.x with its bundled Dart 3.12.x is the supported toolchain range.
The pinned patch version is the release gate; changes to that pin require the
full generated Android and iOS jobs to pass.

## Scope

This template intentionally focuses on infrastructure:

- Dart `logging` abstraction
- no-op observability by default, with optional Sentry integration behind a small interface
- Riverpod dependency wiring
- Dio networking
- basic security: redaction, secure storage, HTTPS guardrails
- go_router
- environment configuration with `--dart-define-from-file`
- GitHub Actions for CI, an iOS release build, and Android internal-track deployment

It does not generate concrete business features such as login, profile, orders, or payments.
