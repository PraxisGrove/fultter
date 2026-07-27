import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/src/core/failures/failure.dart';
import 'package:{{app_name}}/src/core/networking/dio_failure_mapper.dart';

void main() {
  const mapper = DioFailureMapper();
  final request = RequestOptions(path: '/resource');

  DioException dioError(
    DioExceptionType type, {
    int? statusCode,
    Object? error,
  }) {
    return DioException(
      requestOptions: request,
      response: statusCode == null
          ? null
          : Response<void>(requestOptions: request, statusCode: statusCode),
      type: type,
      error: error,
    );
  }

  test('maps every timeout variant to a retryable timeout failure', () {
    for (final type in [
      DioExceptionType.connectionTimeout,
      DioExceptionType.sendTimeout,
      DioExceptionType.receiveTimeout,
      DioExceptionType.transformTimeout,
    ]) {
      final failure = mapper.map(dioError(type), StackTrace.empty);

      expect(failure, isA<TimeoutFailure>());
      expect(failure.isRetryable, isTrue);
    }
  });

  test('maps transport errors', () {
    for (final error in [
      dioError(DioExceptionType.connectionError),
      dioError(DioExceptionType.badCertificate),
      dioError(
        DioExceptionType.unknown,
        error: const SocketException('offline'),
      ),
    ]) {
      expect(mapper.map(error, StackTrace.empty), isA<TransportFailure>());
    }
  });

  test('maps unauthorized responses without retaining response bodies', () {
    for (final statusCode in [401, 403]) {
      final failure = mapper.map(
        dioError(DioExceptionType.badResponse, statusCode: statusCode),
        StackTrace.empty,
      );

      expect(failure, isA<UnauthorizedFailure>());
      expect(failure.statusCode, statusCode);
      expect(failure.isRetryable, isFalse);
    }
  });

  test('maps validation responses', () {
    for (final statusCode in [400, 422]) {
      final failure = mapper.map(
        dioError(DioExceptionType.badResponse, statusCode: statusCode),
        StackTrace.empty,
      );

      expect(failure, isA<ValidationFailure>());
      expect(failure.statusCode, statusCode);
    }
  });

  test('maps server responses to retryable failures', () {
    final failure = mapper.map(
      dioError(DioExceptionType.badResponse, statusCode: 503),
      StackTrace.empty,
    );

    expect(failure, isA<ServerFailure>());
    expect(failure.statusCode, 503);
    expect(failure.isRetryable, isTrue);
  });

  test('maps cancellation separately from transport failures', () {
    final failure = mapper.map(
      dioError(DioExceptionType.cancel),
      StackTrace.empty,
    );

    expect(failure, isA<CancellationFailure>());
    expect(failure.isRetryable, isFalse);
  });

  test('maps malformed data to serialization failures', () {
    expect(
      mapper.map(const FormatException('invalid JSON'), StackTrace.empty),
      isA<SerializationFailure>(),
    );
    expect(
      mapper.map(
        dioError(
          DioExceptionType.unknown,
          error: const FormatException('invalid JSON'),
        ),
        StackTrace.empty,
      ),
      isA<SerializationFailure>(),
    );
  });

  test('maps unclassified errors to unknown failures', () {
    expect(
      mapper.map(StateError('unexpected'), StackTrace.empty),
      isA<UnknownFailure>(),
    );
    expect(
      mapper.map(
        dioError(DioExceptionType.badResponse, statusCode: 404),
        StackTrace.empty,
      ),
      isA<UnknownFailure>(),
    );
  });
}
