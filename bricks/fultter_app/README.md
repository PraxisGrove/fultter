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

## Generate

```sh
mason make fultter_app
```

The post-generation hook runs `flutter create --project-name <app_name> --org <org_domain> .` in the generated directory, then restores the templated files that should override Flutter defaults.
