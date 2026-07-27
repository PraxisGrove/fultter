import 'dart:developer' as developer;

import 'package:logging/logging.dart';

import '../observability/observability.dart';
import '../security/redactor.dart';

void configureLogging({
  required bool enableConsoleLogs,
  required Observability observability,
}) {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    final redactedMessage = Redactor.redact(record.message);
    final redactedError = Redactor.redactObject(record.error);
    final redactedLoggerName = Redactor.redact(record.loggerName);
    final formatted = _format(record, redactedLoggerName, redactedMessage);

    if (enableConsoleLogs) {
      developer.log(
        formatted,
        name: redactedLoggerName,
        level: record.level.value,
        error: redactedError,
        stackTrace: record.stackTrace,
      );
    }

    observability.addBreadcrumb(
      message: redactedMessage,
      category: redactedLoggerName,
      level: record.level.name,
    );

    if (record.level >= Level.SEVERE) {
      final error = redactedError ?? redactedMessage;
      observability.captureException(error, record.stackTrace);
    }
  });
}

String _format(LogRecord record, String loggerName, String message) {
  return '[${record.level.name}] ${record.time.toIso8601String()} '
      '$loggerName: $message';
}
