import 'package:dio/dio.dart';

import 'api_client.dart';

class DioApiClient implements ApiClient {
  DioApiClient(this._dio);

  final Dio _dio;

  @override
  Future<Map<String, Object?>> getJson(
    String path, {
    Map<String, Object?> queryParameters = const {},
  }) async {
    final response = await _dio.get<Object?>(
      path,
      queryParameters: queryParameters,
    );

    final data = response.data;
    if (data is Map<String, Object?>) {
      return data;
    }

    throw const ApiClientException('Expected JSON object response.');
  }
}

class ApiClientException implements Exception {
  const ApiClientException(this.message);

  final String message;

  @override
  String toString() => 'ApiClientException: $message';
}
