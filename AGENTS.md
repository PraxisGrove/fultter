# Repository Guidelines

## Project Structure & Module Organization

This repository is a Mason template repository, not a generated Flutter app. The root `mason.yaml` registers available bricks, and `bricks/fultter_app/brick.yaml` defines the scaffold variables. Template files live under `bricks/fultter_app/__brick__/`; these are copied into generated apps. The post-generation hook is `bricks/fultter_app/hooks/post_gen.dart`, with its own Dart package files in `bricks/fultter_app/hooks/`.

Generated Flutter source is templated under `__brick__/lib`, tests under `__brick__/test`, docs under `__brick__/docs`, environment config under `__brick__/config`, and GitHub workflows under `__brick__/.github/workflows`.

## Build, Test, and Development Commands

Install Mason if needed:

```sh
dart pub global activate mason_cli
```

Fetch local brick metadata:

```sh
mason get
```

Generate a sample app for verification:

```sh
mason make fultter_app -o /tmp/fultter_check
```

Inside the generated app, run:

```sh
flutter pub get
flutter analyze
flutter test
```

Use `dart format bricks/fultter_app/hooks bricks/fultter_app/__brick__/lib bricks/fultter_app/__brick__/test` after editing Dart files.

## Coding Style & Naming Conventions

Follow standard Dart formatting: two-space indentation, `lower_snake_case.dart` filenames, `UpperCamelCase` types, and `lowerCamelCase` members. Keep infrastructure concerns separated: logging in `core/logging`, observability in `core/observability`, networking in `core/networking`, security in `core/security`, and app wiring in `app`.

When editing Mustache templates, preserve variable names from `brick.yaml` and protect literal GitHub Actions syntax with the existing delimiter-switch pattern.

## Testing Guidelines

Tests use Flutter's built-in test runner and `mocktail` where mocks are needed. Add focused tests under the matching `__brick__/test/...` path, using `*_test.dart` filenames. For hook changes, verify by generating a fresh app and running `flutter analyze` plus `flutter test` in that generated output.

## Commit & Pull Request Guidelines

The current history uses concise imperative commits, for example `Create Flutter Mason template`. Keep commits focused on template files only; do not commit generated apps, local SDKs, `.mason`, or temporary outputs.

Pull requests should describe the scaffold behavior changed, list verification commands run, and call out any new generated files, variables, or CI secrets required.

## Security & Configuration Tips

Keep secrets out of the template. Use placeholders in `config/*.json` and document required GitHub Actions secrets in generated docs or workflow comments. Do not weaken the default Level 1 security guardrails: HTTPS enforcement, log/header redaction, secure storage abstraction, and network timeouts.
