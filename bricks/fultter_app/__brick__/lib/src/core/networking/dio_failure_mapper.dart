import 'dart:io';

import 'package:dio/dio.dart';

import '../failures/failure.dart';

class DioFailureMapper implements FailureMapper {
  const DioFailureMapper();

  @override
  Failure map(Object error, StackTrace? stackTrace) {
    if (error is Failure) {
      return error;
    }
    if (error is FormatException) {
      return const SerializationFailure();
    }
    if (error is! DioException) {
      return const UnknownFailure();
    }

    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout ||
      DioExceptionType.transformTimeout => const TimeoutFailure(),
      DioExceptionType.cancel => const CancellationFailure(),
      DioExceptionType.connectionError ||
      DioExceptionType.badCertificate => const TransportFailure(),
      DioExceptionType.badResponse => _mapResponse(error.response?.statusCode),
      DioExceptionType.unknown => _mapUnknown(error.error),
    };
  }

  Failure _mapResponse(int? statusCode) {
    return switch (statusCode) {
      401 || 403 => UnauthorizedFailure(statusCode: statusCode),
      400 || 422 => ValidationFailure(statusCode: statusCode),
      int code when code >= 500 && code <= 599 => ServerFailure(
        statusCode: code,
      ),
      _ => UnknownFailure(statusCode: statusCode),
    };
  }

  Failure _mapUnknown(Object? cause) {
    if (cause is FormatException) {
      return const SerializationFailure();
    }
    if (cause is SocketException || cause is HandshakeException) {
      return const TransportFailure();
    }
    return const UnknownFailure();
  }
}
