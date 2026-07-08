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
    final formatted = _format(record, redactedMessage);

    if (enableConsoleLogs) {
      developer.log(
        formatted,
        name: record.loggerName,
        level: record.level.value,
        error: record.error,
        stackTrace: record.stackTrace,
      );
    }

    observability.addBreadcrumb(
      message: redactedMessage,
      category: record.loggerName,
      level: record.level.name,
    );

    if (record.level >= Level.SEVERE) {
      final error = record.error ?? redactedMessage;
      observability.captureException(error, record.stackTrace);
    }
  });
}

String _format(LogRecord record, String message) {
  return '[${record.level.name}] ${record.time.toIso8601String()} '
      '${record.loggerName}: $message';
}
