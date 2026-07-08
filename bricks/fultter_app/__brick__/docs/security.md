# Security

This template implements Level 1 mobile security defaults.

Included:

- secure storage abstraction backed by `flutter_secure_storage`
- log redaction
- network header redaction
- HTTPS guardrail for `API_BASE_URL`
- debug/release logging separation through config
- timeouts for network requests

Not included by default:

- certificate pinning
- root or jailbreak detection
- screenshot protection
- anti-tamper checks
- encrypted database

## Redaction

Sensitive fields are redacted before logs are written or sent as observability breadcrumbs:

- `authorization`
- `cookie`
- `password`
- `token`
- `x-api-key`

Extend `Redactor` if your backend uses additional sensitive field names.
