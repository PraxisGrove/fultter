import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:{{app_name}}/src/core/failures/failure.dart';
import 'package:{{app_name}}/src/core/networking/dio_api_client.dart';
import 'package:{{app_name}}/src/core/networking/dio_failure_mapper.dart';
import 'package:{{app_name}}/src/core/networking/request_cancellation.dart';

void main() {
  late Dio dio;
  late DioApiClient client;

  setUpAll(() {
    registerFallbackValue(CancelToken());
  });

  setUp(() {
    dio = _MockDio();
    client = DioApiClient(dio, const DioFailureMapper());
  });

  test('returns JSON object responses', () async {
    when(
      () => dio.get<Object?>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer(
      (_) async => Response<Object?>(
        requestOptions: RequestOptions(path: '/resource'),
        data: <String, Object?>{'id': 1},
      ),
    );

    final result = await client.getJson('/resource');

    expect(result, {'id': 1});
  });

  test('maps malformed response payloads to serialization failures', () async {
    when(
      () => dio.get<Object?>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer(
      (_) async => Response<Object?>(
        requestOptions: RequestOptions(path: '/resource'),
        data: const ['not', 'an', 'object'],
      ),
    );

    await expectLater(
      client.getJson('/resource'),
      throwsA(isA<SerializationFailure>()),
    );
  });

  test('does not expose Dio exceptions to callers', () async {
    final request = RequestOptions(path: '/resource');
    when(
      () => dio.get<Object?>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenThrow(
      DioException(
        requestOptions: request,
        type: DioExceptionType.connectionError,
      ),
    );

    await expectLater(
      client.getJson('/resource'),
      throwsA(isA<TransportFailure>()),
    );
  });

  test('bridges backend-neutral cancellation to Dio', () async {
    final pending = Completer<Response<Object?>>();
    when(
      () => dio.get<Object?>(
        any(),
        queryParameters: any(named: 'queryParameters'),
        cancelToken: any(named: 'cancelToken'),
      ),
    ).thenAnswer((invocation) {
      final cancelToken =
          invocation.namedArguments[#cancelToken]! as CancelToken;
      cancelToken.whenCancel.then((error) {
        pending.completeError(error, error.stackTrace);
      });
      return pending.future;
    });
    final cancellation = RequestCancellationController();

    final request = client.getJson(
      '/resource',
      cancellationToken: cancellation.token,
    );
    cancellation.cancel('screen disposed');

    await expectLater(request, throwsA(isA<CancellationFailure>()));
  });
}

class _MockDio extends Mock implements Dio {}
