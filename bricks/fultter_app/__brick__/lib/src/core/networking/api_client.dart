import 'request_cancellation.dart';

abstract interface class ApiClient {
  Future<Map<String, Object?>> getJson(
    String path, {
    Map<String, Object?> queryParameters,
    RequestCancellationToken? cancellationToken,
  });
}
