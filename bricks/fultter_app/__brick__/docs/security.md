# Security

This template implements Level 1 mobile security defaults.

Included:

- secure storage abstraction backed by `flutter_secure_storage`
- log redaction
- network header redaction
- HTTPS guardrail for `API_BASE_URL` in staging and production
- debug/release logging separation through config
- timeouts for network requests

Not included by default:

- certificate pinning
- root or jailbreak detection
- screenshot protection
- anti-tamper checks
- encrypted database

## Redaction

Sensitive fields are recursively redacted before console output or provider
delivery. URL query parameters and nested map/list values use the same rules:

- `authorization`
- `cookie`
- `password`
- `passcode`
- `token`
- `access_token` / `accessToken`
- `refresh_token` / `refreshToken`
- `api_key` / `apiKey`
- `x-api-key`
- `client_secret` / `clientSecret`

Extend `Redactor` if your backend uses additional sensitive field names.

Network request and response bodies are never logged by the generated client.
Network metadata logs can be enabled for dev or staging, but are forced off in
production even if `ENABLE_NETWORK_LOGS` is set to `true`.

Insecure HTTP is accepted only when `APP_ENV=dev` and
`ALLOW_INSECURE_HTTP_FOR_DEBUG=true`. Staging and production reject insecure
base URLs even if that flag is accidentally enabled.
