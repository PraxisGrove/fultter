# Features

Put product-specific features here.

Recommended shape for a complex feature:

```txt
features/example/
  data/
  domain/
  presentation/
```

For small features, keep the structure simple and add layers only when they remove real complexity.

## Reference feature

`reference` is a removable, business-neutral example of a paged repository:

```txt
features/reference/
  domain/  # Pure Dart entities, paging values, and repository contract.
  data/    # DTO mapping, deterministic fake data, and provider selection.
```

The default `referenceRepositoryProvider` selects `FakeReferenceRepository`,
which requires no network or credentials. A future Dio-backed implementation
belongs in `data/` and implements `ReferenceRepository`; it may depend on
`ApiClient` and data-layer DTOs. Switch the implementation in
`reference_repository_provider.dart` (or override the provider at a
`ProviderScope`) without changing domain or presentation public contracts.

For deterministic tests, inject a `FakeReferenceRepositoryControl` and select
`showSuccess`, `showEmpty`, or `forceFailure`. Calling `reset` on the repository
restores its seed records, saved edits, and the control's initial state without
delays or network access.
