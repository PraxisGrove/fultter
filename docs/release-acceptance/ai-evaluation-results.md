# SC-005 AI coding evaluation results

Date: 2026-07-28

Result: **3/3 conforming runs passed**

## Controlled method

- Generated one default `quality_gate_app` baseline from revision
  `71ddbea64d74094a3695ecd3c570b7d23b017ea3`.
- Copied that unmodified baseline three times. Runs did not inherit another
  run's code or conversation.
- Supplied only each generated repository and the fixed brief in
  `sc-005-feature-brief.md`.
- Used Codex CLI 0.145.0 with `gpt-5.6-sol`, medium reasoning, and no approval
  prompts. No run used network services, credentials, or added packages.
- Independently reran format, analysis, and the full test suite after every AI
  session. Run 1's isolated session could not bind Flutter's loopback test
  socket, so its full suite was rerun immediately from the host and passed.

Fixed brief SHA-256:
`a07352844a718749d42fae43433757b07d32214aebfd83bc645c52643e6ce161`

## Outcomes

| Run | Result | Independent output | Quality gates | Result record SHA-256 |
| --- | --- | --- | --- | --- |
| 1 | Pass | Notes domain/data/application/presentation, 15 deterministic notes, protected list/detail/edit routes, localization, retry/paging/edit tests | Format: 65 files unchanged; analysis: no issues; tests: 94/94 | `e3f9ef55450aa298506b3fe3a4bde73d220351eb2c8d0196d870d78f336b83f4` |
| 2 | Pass | Commit `ef28e0c`, 28 files, 25 deterministic notes, independent Notes contracts/controllers/pages/tests | Format: 75 files unchanged; analysis: no issues; tests: 104/104 | `ec321a39c0496397db4b5cfc190766553a74b01c8b7a148829a81142b70813ea` |
| 3 | Pass | Commit `f734400`, 25 files, deterministic in-memory Notes slice with independent controllers/pages/tests | Format: 72 files unchanged; analysis: no issues; tests: 88/88 | `b74b3e8978c176aa2398b594f871d3204295d132e56b135e5f8e89f9e4ebcd2d` |

The result hashes identify the captured final AI summaries in the ignored local
acceptance workspace. This document retains the release-relevant result record;
generated evaluation repositories are deliberately not product source.

## Architecture checklist

All three runs passed every item:

- Feature resides under `lib/src/features/notes` with domain, data,
  application, and presentation layers.
- Domain imports only its own Dart models/contracts; no Flutter, Riverpod, Dio,
  DTO, storage implementation, provider SDK, or concrete repository leaks.
- Repository and controllers are injected through Riverpod replacement points.
- In-memory data is deterministic, has at least 12 notes, performs no network
  access, and persists edits for later list/detail reads.
- List/detail/edit routes are protected through the existing `go_router` and
  use encoded path builders.
- Initial loading, empty, initial failure, next-page failure, retry,
  end-of-list, data preservation, deduplication, concurrent-load suppression,
  title validation, duplicate-save suppression, and edit propagation are
  implemented and tested.
- All new interface copy is localized in English and Simplified Chinese, with
  actionable semantics and text-scaling coverage.
- Existing reference behavior remains intact.
- `pubspec.yaml` is byte-identical to the clean baseline in every run.

## Equivalence assessment

The implementations differ legitimately in naming, file granularity, seed
count, and controller organization, but expose the same required vertical-slice
behavior and preserve the same architecture boundaries. This is the intended
SC-005 outcome: the generated instructions and executable reference feature
are sufficient for an AI tool to add a conforming second slice repeatedly
without hidden project context.
