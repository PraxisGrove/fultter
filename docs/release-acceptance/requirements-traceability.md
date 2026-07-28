# PRD v1.0 requirements traceability

Status values are based on accepted repository revision
`77079de8fad23bd3a1b5333403a96b2d82373da4`, the SC-005 generated baseline at
`71ddbea64d74094a3695ecd3c570b7d23b017ea3`, and the acceptance runs recorded
on 2026-07-28. No requirement is deferred or waived.

## Functional requirements

| Requirement | Status | Implementation and verification evidence |
| --- | --- | --- |
| FR-GEN-001 | Pass | `bricks/fultter_app/brick.yaml` exposes one standard app profile and no architecture selector. |
| FR-GEN-002 | Pass | `hooks/post_gen.dart` validates app name, organization, and bundle ID; all validation tests pass. |
| FR-GEN-003 | Pass | The hook invokes Flutter, preserves template files, patches identity/display name, and propagates command failures; hook tests and generated Android/iOS CI builds pass. |
| FR-GEN-004 | Pass | Default generation and its 76 tests run without an API, secret, provider account, signing credential, or runtime service. |
| FR-ARC-001 | Pass | Generated `lib/src/features` is feature-first; reference and all three Notes evaluations use domain/data/application/presentation layers. |
| FR-ARC-002 | Pass | `AGENTS.md`, `docs/architecture.md`, and import scans enforce inward dependencies; reference and evaluated Notes domain code expose no Flutter, Dio, storage, DTO, or SDK types. |
| FR-ARC-003 | Pass | `lib/src/app/providers.dart` and feature providers use Riverpod replacement points; provider replacement tests pass. |
| FR-AI-001 | Pass | Generated `AGENTS.md` covers placement, boundaries, commands, tests, prohibited patterns, and completion checks. |
| FR-AI-002 | Pass | `docs/recipes.md`, `docs/networking.md`, and `docs/remove-reference-feature.md` cover feature creation, fake-to-Dio replacement, routing, tests, and removal. |
| FR-ENV-001 | Pass | `config/dev.json`, `config/staging.json`, `config/prod.json`, and `docs/configuration.md` separate public client configuration from secrets and provide run/build commands. |
| FR-UI-001 | Pass | `app_theme.dart`, `display_settings.dart`, and app widget tests cover system, light, and dark modes without an external provider. |
| FR-UI-002 | Pass | ARB resources provide English and Simplified Chinese; localization and 200% text-scale widget tests pass. |
| FR-NET-001 | Pass | `core/networking` centralizes Dio URL, timeouts, headers, cancellation, safe logging, and failure conversion; factory/client tests pass. |
| FR-NET-002 | Pass | `failure.dart` and `dio_failure_mapper.dart` cover timeout, transport, unauthorized, validation, server, cancellation, serialization, and unknown failures without leaking Dio to presentation. |
| FR-AUTH-001 | Pass | `features/auth` defines backend-neutral auth state and credential lifecycle over a replaceable storage boundary; controller/store tests pass. |
| FR-ROUTE-001 | Pass | `router.dart` demonstrates public, protected, entry/loading, return-location, expiry, and loop-safe redirects; redirect and app tests pass. |
| FR-STATE-001 | Pass | Reference controllers/pages explicitly cover initial, loading, data, empty, failure, and retry states in controller and widget tests. |
| FR-STATE-002 | Pass | Reference pagination tests verify duplicate-load suppression, data preservation, deduplication, end state, page failure, and same-page retry. |
| FR-FORM-001 | Pass | Reference edit controller/page tests cover validation, pending save, failure, success, and duplicate-submit suppression. |
| FR-REF-001 | Pass | `features/reference` provides deterministic local paged list, detail, and edit flows. |
| FR-REF-002 | Pass | `FakeReferenceRepository` exposes deterministic empty/failure controls; tests use no sleeps or public network. |
| FR-REF-003 | Pass | The documented removal command now updates routes, localization, tests, and guidance; the resulting neutral app passes format, analysis, and 51 tests. |
| FR-OBS-001 | Pass | `Redactor`, logging/observability wrappers, and tests redact configured sensitive values; production body logging is disabled. |
| FR-OBS-002 | Pass | `Observability` defaults to `NoopObservability`; provider SDK templates are opt-in and absent from default output. |
| FR-SEC-001 | Pass | `NetworkConfig` permits explicit insecure HTTP only in development and rejects it for staging/production; tests pass. |
| FR-SEC-002 | Pass | Config/workflow inspection and security docs confirm no secrets, keys, passwords, signing credentials, or admin tokens are stored. |
| FR-QA-001 | Pass | Default generated output passes format, analysis, and all 76 tests. |
| FR-QA-002 | Pass | `.github/workflows/generated_app_ci.yml` exercises integrations-off generation, format, analysis, tests, removal, Android, and iOS; PR #12 jobs pass. |
| FR-QA-003 | Pass | Tests cover config parsing, failure mapping, redaction, route guards, pagination, forms, repository behavior, and primary widget flows. |
| FR-EXT-001 | Pass | `docs/external-integration.md` records packages, public settings versus secrets, platform changes, implementation points, failure rules, and verification. |

## Business rules

| Rule | Status | Evidence |
| --- | --- | --- |
| BR-001 | Pass | One brick/profile is exposed; no product edition or architecture selector exists. |
| BR-002 | Pass | Default capabilities operate without external accounts; generation and baseline tests confirm this. |
| BR-003 | Pass | Sentry and other integrations are opt-in and do not affect default startup, tests, or CI. |
| BR-004 | Pass | Generated guidance permits omitted unused layers but enforces inward dependency direction; domain import scans pass. |
| BR-005 | Pass | Reference is isolated executable documentation; the automated documented removal leaves shared infrastructure and 51 passing tests. |
| BR-006 | Pass | Routing, lifecycle, context, cancellation, and mutable state remain explicit in standard Flutter/Riverpod APIs. |
| BR-007 | Pass | Generated environment files contain only public client settings; release signing values are encrypted-secret references only. |

## Success criteria

| Criterion | Status | Evidence |
| --- | --- | --- |
| SC-001 | Pass | Default output passes format, analysis, and 76 tests locally; pinned generated-app CI is green. |
| SC-002 | Pass | Reference repository/controller/widget flows complete with deterministic local data and no secrets, accounts, sleeps, or network service. |
| SC-003 | Pass | The documented removal path produces a neutral runnable app that passes format, analysis, and 51 tests. |
| SC-004 | Pass | `docs/recipes.md` documents the Dio adapter point; domain repository and presentation contracts stay backend-neutral, with provider replacement tests. |
| SC-005 | Pass | Three clean fixed-brief evaluations produced independent four-layer Notes slices; architecture checks, analysis, and 94/104/88 tests pass. |
