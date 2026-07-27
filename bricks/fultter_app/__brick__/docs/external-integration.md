# External integration template

External services are opt-in. Complete this document for each analytics,
observability, identity, payments, maps, messaging, or other provider before
enabling it. Do not add an SDK directly to widgets or domain code.

## Decision record

| Field | Required content |
| --- | --- |
| Capability | User need and why local/existing code cannot satisfy it |
| Package | Package name, pinned compatible range, license, maintainer/status, and security review |
| Platforms | Android/iOS support and minimum OS/toolchain constraints |
| Data flow | Data sent, purpose, retention/region controls, and user consent requirement |
| Lock-in | Backend-neutral contract, replacement boundary, and migration/export implications |
| Cost | Free/paid limits and expected operational ownership |

Reject the integration if maintenance, license, security, privacy, platform
compatibility, or failure behavior is unresolved.

## Configuration and credentials

List every setting and classify it:

| Setting | Client-public or secret | Source by environment | Required at runtime |
| --- | --- | --- | --- |
| Example public client ID | Client-public | `config/*.json` / dart define | No |
| Example signing key | Secret | CI encrypted secret store only | Release only |

Values packaged in the app, including DSNs and mobile API keys, are recoverable
and must not be described as secrets. Server credentials, private keys, admin
tokens, signing material, and provider-management tokens must never enter
client config, source, tests, logs, or artifacts. Document rotation and local
development behavior without publishing credential values.

## Native changes

Record exact Android and iOS files, manifest/plist entries, URL schemes,
entitlements, capabilities, Gradle/CocoaPods settings, minimum OS changes, and
privacy declarations. State whether the Mason post-generation hook must apply
the change so fresh output is complete.

## Injection boundary

1. Define or reuse a backend-neutral interface in the owning feature or
   `lib/src/core` only when multiple features consume it.
2. Keep all provider imports in one adapter implementation.
3. Construct the adapter in a Riverpod provider or the existing factory
   boundary, such as `createObservability()`.
4. Keep call sites unchanged when selecting the no-op, fake, or real adapter.

Document the exact interface, implementation path, provider/factory path, and
selection rule. Do not add a mutable global singleton.

## Failure behavior

Define behavior for missing configuration, initialization timeout/failure,
offline operation, cancellation, provider rejection/rate limits, malformed
responses, and unavailable SDK services. State which failures are user-visible,
retryable, captured as redacted diagnostics, or deliberately no-op. A
non-essential integration must not block app startup. Authentication, payment,
or data-integrity boundaries must fail closed rather than silently proceed.

## Security and privacy checks

- Enumerate payload fields and redact configured sensitive values before logs
  or observability delivery.
- Disable provider debug/body logging in production.
- Record consent, deletion, retention, regional, child-safety, and store privacy
  disclosures when applicable.
- Verify least-privilege native permissions and backend authorization. Client
  route visibility or an embedded key is not an authorization control.

## Verification

Provide deterministic tests for the interface, no-op/fake behavior, missing
configuration, initialization failure, mapping/redaction, and provider adapter.
Provider contract tests must use a fake transport or SDK facade and require no
real account, network, or credential. Record manual sandbox steps separately
when provider-owned behavior cannot be automated.

Before merge, run:

```sh
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Also verify fresh Android and iOS generation/build when native files or the
post-generation hook changed. Update configuration, security, observability,
release, and store-disclosure documentation affected by the integration.
