enum FailureCategory {
  transport,
  timeout,
  unauthorized,
  validation,
  server,
  cancellation,
  serialization,
  unknown,
}

sealed class Failure implements Exception {
  const Failure({
    required this.category,
    required this.message,
    required this.isRetryable,
    this.statusCode,
  });

  final FailureCategory category;
  final String message;
  final bool isRetryable;
  final int? statusCode;

  @override
  String toString() => '$runtimeType: $message';
}

final class TransportFailure extends Failure {
  const TransportFailure({super.message = 'Unable to reach the service.'})
    : super(category: FailureCategory.transport, isRetryable: true);
}

final class TimeoutFailure extends Failure {
  const TimeoutFailure({super.message = 'The request timed out.'})
    : super(category: FailureCategory.timeout, isRetryable: true);
}

final class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure({
    super.message = 'Authentication is required.',
    super.statusCode,
  }) : super(category: FailureCategory.unauthorized, isRetryable: false);
}

final class ValidationFailure extends Failure {
  const ValidationFailure({
    super.message = 'The request is not valid.',
    super.statusCode,
  }) : super(category: FailureCategory.validation, isRetryable: false);
}

final class ServerFailure extends Failure {
  const ServerFailure({
    super.message = 'The service could not complete the request.',
    super.statusCode,
  }) : super(category: FailureCategory.server, isRetryable: true);
}

final class CancellationFailure extends Failure {
  const CancellationFailure({super.message = 'The request was cancelled.'})
    : super(category: FailureCategory.cancellation, isRetryable: false);
}

final class SerializationFailure extends Failure {
  const SerializationFailure({
    super.message = 'The service returned an unexpected response.',
  }) : super(category: FailureCategory.serialization, isRetryable: false);
}

final class UnknownFailure extends Failure {
  const UnknownFailure({
    super.message = 'An unexpected error occurred.',
    super.statusCode,
  }) : super(category: FailureCategory.unknown, isRetryable: false);
}

abstract interface class FailureMapper {
  Failure map(Object error, StackTrace? stackTrace);
}
