# fultter_app

Generates a Flutter mobile app skeleton with infrastructure defaults:

- logging with Dart `logging`
- no-op observability by default, with Sentry as an opt-in integration
- dependency wiring with Riverpod
- networking with Dio
- routing with go_router
- basic security with redaction and secure storage
- dev/staging/prod configuration
- CI, release build, integration test, and manual deployment workflow templates

The supported toolchain is Flutter 3.44.x stable with its bundled Dart 3.12.x.
Generated workflows pin Flutter 3.44.8.

## Generate

```sh
mason make fultter_app
```

The supported profile generates Android and iOS projects. It has no edition or
library selector and requires no API key, signing credential, provider account,
or runtime service.

Metadata must use these formats:

- `app_name`: starts with a lowercase letter and contains only lowercase
  letters, digits, and underscores, for example `my_app`.
- `org_domain`: a lowercase reverse domain with at least two segments, for
  example `com.example`.
- `bundle_id`: a reverse-domain identifier with at least two segments; each
  segment starts with a lowercase letter and contains lowercase letters,
  digits, or underscores, for example `com.example.my_app`.

The post-generation hook validates all metadata before invoking Flutter, then
runs the equivalent of:

```sh
flutter create --project-name my_app --org com.example --platforms android,ios --no-pub .
```

It applies the requested Android/iOS identity and display name while restoring
all template-owned files. Missing tools or failed commands stop generation and
include command output in the error.

After a successful generation, the hook prints these run and verification
commands:

```sh
flutter run --dart-define-from-file=config/dev.json
flutter run --dart-define-from-file=config/staging.json
flutter run --dart-define-from-file=config/prod.json
flutter analyze
flutter test
```
