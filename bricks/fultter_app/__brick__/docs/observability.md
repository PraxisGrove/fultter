# Observability

Observability is accessed through `Observability`, never directly through a
provider SDK. The generated default is `NoopObservability`, so startup and error
capture require no account, credential, network service, analytics, or tracking.

```txt
logging package
  -> configureLogging()
  -> Observability
  -> RedactingObservability
  -> Noop or an opt-in provider
```

`createObservability()` is the injection boundary. It selects the generated
provider and always wraps it with `RedactingObservability`, so application call
sites do not change when a provider is added. To inject another provider, make
it implement `Observability` and pass it as the `provider` argument. Keep SDK
imports inside that provider implementation.

Provider initialization errors are provider behavior; the default no-op
implementation completes initialization and capture calls without external
setup.

{{#use_sentry}}
## Sentry

This app was generated with the optional `sentry_flutter` integration. Set its
public client DSN at build time or in the relevant config file:

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

Sentry is disabled when `SENTRY_DSN` is empty. `sendDefaultPii` remains disabled.
{{/use_sentry}}
{{^use_sentry}}
## Adding a Provider

This app contains no provider SDK. Add the provider package explicitly, create
an `Observability` implementation under `lib/src/core/observability`, and inject
it through `createObservability()`. Document its public client settings, native
setup, failure behavior, and verification steps before enabling it.
{{/use_sentry}}
