import 'package:dio/dio.dart';

import '../failures/failure.dart';
import 'api_client.dart';
import 'request_cancellation.dart';

class DioApiClient implements ApiClient {
  DioApiClient(this._dio, this._failureMapper);

  final Dio _dio;
  final FailureMapper _failureMapper;

  @override
  Future<Map<String, Object?>> getJson(
    String path, {
    Map<String, Object?> queryParameters = const {},
    RequestCancellationToken? cancellationToken,
  }) async {
    final dioCancelToken = cancellationToken == null ? null : CancelToken();
    void cancelRequest(String? reason) {
      if (dioCancelToken?.isCancelled == false) {
        dioCancelToken?.cancel(reason ?? 'Request cancelled.');
      }
    }

    cancellationToken?.addListener(cancelRequest);
    try {
      final response = await _dio.get<Object?>(
        path,
        queryParameters: queryParameters,
        cancelToken: dioCancelToken,
      );

      final data = response.data;
      if (data is Map<String, Object?>) {
        return data;
      }

      throw const SerializationFailure();
    } on Object catch (error, stackTrace) {
      throw _failureMapper.map(error, stackTrace);
    } finally {
      cancellationToken?.removeListener(cancelRequest);
    }
  }
}
