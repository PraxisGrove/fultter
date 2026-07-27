import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/src/core/config/app_config.dart';
import 'package:{{app_name}}/src/core/config/app_environment.dart';
import 'package:{{app_name}}/src/core/observability/observability.dart';

void main() {
  const config = AppConfig(
    environment: AppEnvironment.prod,
    apiBaseUrl: 'https://api.example.com',
    enableNetworkLogs: false,
    allowInsecureHttpForDebug: false,
  );

  test('default provider is safe when no integration is configured', () async {
    final observability = createObservability(config);

    await expectLater(observability.init(), completes);
    expect(
      () => observability.addBreadcrumb(
        message: 'token=secret',
        category: 'test',
        level: 'INFO',
      ),
      returnsNormally,
    );
    expect(
      () => observability.captureException('password=secret', null),
      returnsNormally,
    );
  });

  test('injected provider receives only redacted values', () async {
    final provider = _RecordingObservability();
    final observability = createObservability(config, provider: provider);

    await observability.init();
    observability.addBreadcrumb(
      message: 'access_token=breadcrumb-secret',
      category: 'auth token=category-secret',
      level: 'WARNING',
    );
    const exception = {
      'password': 'password-secret',
      'nested': {'apiKey': 'api-secret'},
    };
    observability.captureException(exception, null);
    observability.captureFlutterError(
      const FlutterErrorDetails(exception: 'token=flutter-secret'),
    );

    expect(provider.initialized, isTrue);
    expect(provider.breadcrumbMessage, isNot(contains('breadcrumb-secret')));
    expect(provider.breadcrumbCategory, isNot(contains('category-secret')));
    expect(provider.exception.toString(), isNot(contains('password-secret')));
    expect(provider.exception.toString(), isNot(contains('api-secret')));
    expect(
      provider.flutterError?.exception.toString(),
      isNot(contains('flutter-secret')),
    );
  });
}

class _RecordingObservability implements Observability {
  bool initialized = false;
  String? breadcrumbMessage;
  String? breadcrumbCategory;
  Object? exception;
  FlutterErrorDetails? flutterError;

  @override
  Future<void> init() async {
    initialized = true;
  }

  @override
  void addBreadcrumb({
    required String message,
    required String category,
    required String level,
  }) {
    breadcrumbMessage = message;
    breadcrumbCategory = category;
  }

  @override
  void captureException(Object error, StackTrace? stackTrace) {
    exception = error;
  }

  @override
  void captureFlutterError(FlutterErrorDetails details) {
    flutterError = details;
  }
}
