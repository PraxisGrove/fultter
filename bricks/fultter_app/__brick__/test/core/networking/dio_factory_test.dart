import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/src/core/networking/dio_factory.dart';
import 'package:{{app_name}}/src/core/networking/network_config.dart';
import 'package:{{app_name}}/src/core/observability/observability.dart';

void main() {
  test('applies centralized headers and timeouts', () {
    const config = NetworkConfig(
      baseUrl: 'https://api.example.com',
      enableNetworkLogs: false,
      allowInsecureHttpForDebug: false,
      connectTimeout: Duration(seconds: 4),
      receiveTimeout: Duration(seconds: 5),
      sendTimeout: Duration(seconds: 6),
      transformTimeout: Duration(seconds: 7),
      defaultHeaders: {'Accept': 'application/vnd.example+json'},
    );

    final dio = createDio(config, NoopObservability());

    expect(dio.options.baseUrl, config.baseUrl);
    expect(dio.options.connectTimeout, config.connectTimeout);
    expect(dio.options.receiveTimeout, config.receiveTimeout);
    expect(dio.options.sendTimeout, config.sendTimeout);
    expect(dio.options.transformTimeout, config.transformTimeout);
    expect(dio.options.headers['Accept'], 'application/vnd.example+json');
  });

  test('rejects insecure base URLs unless explicitly allowed', () {
    expect(
      () => createDio(
        const NetworkConfig(
          baseUrl: 'http://api.example.com',
          enableNetworkLogs: false,
          allowInsecureHttpForDebug: false,
        ),
        NoopObservability(),
      ),
      throwsStateError,
    );
  });
}
