# SC-005 fixed feature brief

Add a second business-neutral vertical slice named **Notes** to this generated
Flutter application. Read and follow the repository's `AGENTS.md` and existing
documentation before changing code.

The feature must:

- use `lib/src/features/notes/{domain,data,application,presentation}` with the
  documented dependency direction;
- define a backend-neutral repository contract and a deterministic in-memory
  implementation with at least 12 seed notes;
- provide paged list, detail, and edit flows reachable through named paths in
  the existing `go_router` configuration;
- expose loading, empty, initial-load failure, next-page failure, retry, and
  end-of-list behavior without sleeps or network access;
- preserve loaded notes when a later page fails, suppress concurrent page
  loads, validate a non-empty title, suppress duplicate saves, and reflect a
  successful edit in later list and detail reads;
- inject the repository and controllers with Riverpod and expose no concrete
  repository, DTO, Dio, Flutter, storage, or provider SDK type through the
  domain public API;
- localize every new visible string in English and Simplified Chinese and add
  meaningful semantics to actionable controls;
- add focused repository/controller tests plus widget coverage for the primary
  list-detail-edit flow, validation, retry, and preserved-data pagination
  failure.

Do not add packages, external services, credentials, a second state-management
or routing framework, generic base classes, or unrelated refactors. Keep the
existing reference feature intact. Run and pass:

```sh
dart format --set-exit-if-changed .
flutter analyze
flutter test
```

Finish with a concise summary of files changed and checks run.
