# Observability

Observability is accessed through `Observability`, not directly through Sentry.

```txt
logging package
  -> configureLogging()
  -> Observability
  -> Sentry or Noop
```

## Sentry

Set `SENTRY_DSN` in the relevant config file:

```json
{
  "SENTRY_DSN": "https://example@sentry.io/123"
}
```

The app captures:

- Flutter framework errors
- uncaught zoned errors
- severe log records
- breadcrumbs from logs and network requests

Sentry is disabled when `SENTRY_DSN` is empty.
