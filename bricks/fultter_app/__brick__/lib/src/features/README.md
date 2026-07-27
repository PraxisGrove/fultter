# Features

Put product-specific features here.

Recommended shape for a complex feature:

```txt
features/example/
  data/
  domain/
  application/
  presentation/
```

For small features, keep the structure simple and add layers only when they remove real complexity.

Use `features/reference` as the normative vertical-slice example and follow
`docs/recipes.md` for placement, dependency direction, routes, repository
replacement, and tests. Follow `docs/remove-reference-feature.md` when the
example is no longer needed.
