# Networking and failures

`NetworkConfig` owns the API base URL, timeouts, default headers, debug logging,
and the development-only HTTP exception. `createDio` applies that configuration
and logs only redacted request metadata. Request and response bodies are not
logged.

## Failure boundary

Feature code handles `Failure` values from `core/failures/failure.dart`. It must
not catch or expose `DioException` in domain or presentation public APIs.
`DioFailureMapper` uses these deterministic mappings:

| Input | Shared failure | Retryable |
| --- | --- | --- |
| Connection, certificate, or socket error | `TransportFailure` | Yes |
| Connect, send, receive, or transform timeout | `TimeoutFailure` | Yes |
| HTTP 401 or 403 | `UnauthorizedFailure` | No |
| HTTP 400 or 422 | `ValidationFailure` | No |
| HTTP 500-599 | `ServerFailure` | Yes |
| Cancelled request | `CancellationFailure` | No |
| Malformed JSON or unexpected payload shape | `SerializationFailure` | No |
| Any unclassified error or response | `UnknownFailure` | No |

The shared failures intentionally contain no backend error-envelope model. A
feature may map its own validated error payload inside its data layer without
changing the core contract.

## Cancellation

Create a `RequestCancellationController` for an operation, pass its `token` to
`ApiClient`, and call `cancel` when the operation is no longer needed. The Dio
adapter bridges that token to Dio's `CancelToken`; callers receive a distinct
`CancellationFailure`, so cancellation is not offered as a retryable transport
error.

```dart
final cancellation = RequestCancellationController();

final request = apiClient.getJson(
  '/items',
  cancellationToken: cancellation.token,
);

cancellation.cancel('screen disposed');
```
