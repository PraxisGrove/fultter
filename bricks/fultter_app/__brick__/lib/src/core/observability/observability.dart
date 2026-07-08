import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
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

Observability createObservability(AppConfig config) {
  {{#use_sentry}}return SentryObservability(config);{{/use_sentry}}
  {{^use_sentry}}return NoopObservability();{{/use_sentry}}
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
