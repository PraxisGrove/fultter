import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../security/redactor.dart';
{{#use_sentry}}import 'sentry_observability.dart';{{/use_sentry}}

abstract interface class Observability {
  Future<void> init();

  void addBreadcrumb({
    required String message,
    required String category,
    required String level,
  });

  void captureFlutterError(FlutterErrorDetails details);

  void captureException(Object error, StackTrace? stackTrace);
}

Observability createObservability(
  AppConfig config, {
  Observability? provider,
}) {
  final selectedProvider = provider ??
      {{#use_sentry}}SentryObservability(config){{/use_sentry}}
      {{^use_sentry}}NoopObservability(){{/use_sentry}};
  return RedactingObservability(selectedProvider);
}

class NoopObservability implements Observability {
  @override
  Future<void> init() async {}

  @override
  void addBreadcrumb({
    required String message,
    required String category,
    required String level,
  }) {}

  @override
  void captureFlutterError(FlutterErrorDetails details) {}

  @override
  void captureException(Object error, StackTrace? stackTrace) {}
}

class RedactingObservability implements Observability {
  RedactingObservability(this._provider);

  final Observability _provider;

  @override
  Future<void> init() => _provider.init();

  @override
  void addBreadcrumb({
    required String message,
    required String category,
    required String level,
  }) {
    _provider.addBreadcrumb(
      message: Redactor.redact(message),
      category: Redactor.redact(category),
      level: level,
    );
  }

  @override
  void captureFlutterError(FlutterErrorDetails details) {
    _provider.captureFlutterError(
      FlutterErrorDetails(
        exception: Redactor.redactObject(details.exception)!,
        stack: details.stack,
        library: details.library == null
            ? null
            : Redactor.redact(details.library),
        silent: details.silent,
      ),
    );
  }

  @override
  void captureException(Object error, StackTrace? stackTrace) {
    _provider.captureException(Redactor.redactObject(error)!, stackTrace);
  }
}
