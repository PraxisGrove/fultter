# Release acceptance checklist

Date: 2026-07-28

Accepted base revision: `77079de8fad23bd3a1b5333403a96b2d82373da4`

SC-005 evaluation baseline: `71ddbea64d74094a3695ecd3c570b7d23b017ea3`

Decision: **GO**

All PRD v1.0 release criteria have reproducible evidence. There are no waived
requirements or approved deferrals. The local host lacks an Android SDK and a
complete Xcode/CocoaPods installation, so platform builds use the successful
GitHub Actions evidence from PR #12; all host-independent generation, removal,
format, analysis, and test checks were rerun locally.

## Toolchain

| Tool | Version |
| --- | --- |
| Flutter | 3.44.8 stable |
| Dart | 3.12.2 |
| Mason CLI | 0.1.2 |
| Codex CLI | 0.145.0 (`gpt-5.6-sol`) |

This matches the supported Flutter 3.44.x / Dart 3.12.x range documented in
`README.md` and `bricks/fultter_app/README.md`. CI pins Flutter 3.44.8.

## Results

| Area | Result | Evidence |
| --- | --- | --- |
| Hook metadata and failure handling | Pass, 6 tests | `bricks/fultter_app/hooks/test/post_gen_test.dart` |
| Default generation | Pass | `tool/generate_default_app.sh` generated a clean app without credentials or service configuration |
| Default formatting | Pass, 57 files unchanged | `dart format --set-exit-if-changed .` in the generated baseline |
| Default analysis | Pass, no issues | `flutter analyze` in the generated baseline |
| Default tests | Pass, 76 tests | `flutter test` in the generated baseline |
| Reference list/detail/edit flow | Pass | Generated repository, controller, route, and widget tests |
| Reference removal | Pass | `tool/remove_reference_feature.dart` completed from a fresh baseline and removed stale code, localization, tests, and guidance |
| Removed-app formatting | Pass, 40 files unchanged | `dart format --set-exit-if-changed .` |
| Removed-app analysis | Pass, no issues | `flutter analyze` |
| Removed-app tests | Pass, 51 tests | `flutter test` |
| Three clean AI evaluations | Pass | `ai-evaluation-results.md`; 94, 104, and 88 tests respectively |
| Default outbound telemetry | Pass, none | `NoopObservability`, empty external-integration defaults, observability tests, and generated docs |
| Android generated build | Pass in CI | PR #12 check `Generate, quality, removal, Android` |
| iOS generated build | Pass in CI | PR #12 check `Generate and build iOS` |

GitHub Actions run 30329668538 completed both generated-app jobs successfully
on PR #12. The same run also exercised default generation and reference
removal. Local Android build attempts stop before compilation with `No Android
SDK found`; local iOS attempts stop because Xcode is incomplete. These are host
prerequisite limitations, not product failures, and are covered by the CI jobs.

## Runtime and data safety

- The default generated configuration contains public client settings only.
- The default observability factory resolves to `NoopObservability`; no
  analytics, tracking, account, DSN, or network service is required.
- External integrations are opt-in and default generation does not include
  their SDKs or credential values.
- Production disables verbose network logging and rejects insecure HTTP.
- Repository, logs, configuration, workflows, evaluation prompt, and result
  summaries were inspected for credentials; none were introduced.

## Reproduction

From the repository root:

```sh
(cd bricks/fultter_app/hooks && dart pub get && dart test)
dart pub global run mason_cli:mason get
./tool/generate_default_app.sh build/release_candidate
cd build/release_candidate
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

From a fresh generated copy, verify removal:

```sh
dart run ../../tool/remove_reference_feature.dart .
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

For SC-005, copy the same unmodified baseline three times and run the fixed
brief in `sc-005-feature-brief.md` with a clean AI session for each copy. The
exact outcomes and integrity hashes are in `ai-evaluation-results.md`.

## Recommendation

Release the standard template. The default and removal paths pass their local
quality gates, both mobile platform builds pass pinned CI, all requirements are
traceable, and three independent AI runs produced conforming equivalent Notes
vertical slices without packages, services, secrets, or architecture drift.
