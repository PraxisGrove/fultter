import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/src/core/config/app_config.dart';
import 'package:{{app_name}}/src/core/config/app_environment.dart';
import 'package:{{app_name}}/src/core/networking/network_config.dart';

void main() {
  test('production disables network logs even when requested', () {
    const appConfig = AppConfig(
      environment: AppEnvironment.prod,
      apiBaseUrl: 'https://api.example.com',
      enableNetworkLogs: true,
      allowInsecureHttpForDebug: false,
    );

    final networkConfig = NetworkConfig.fromAppConfig(appConfig);

    expect(networkConfig.enableNetworkLogs, isFalse);
  });

  test('debug-like environments may explicitly enable network logs', () {
    const appConfig = AppConfig(
      environment: AppEnvironment.dev,
      apiBaseUrl: 'https://api.example.com',
      enableNetworkLogs: true,
      allowInsecureHttpForDebug: false,
    );

    final networkConfig = NetworkConfig.fromAppConfig(appConfig);

    expect(networkConfig.enableNetworkLogs, isTrue);
  });

  test('only development may explicitly allow insecure HTTP', () {
    for (final environment in [AppEnvironment.staging, AppEnvironment.prod]) {
      final appConfig = AppConfig(
        environment: environment,
        apiBaseUrl: 'http://api.example.com',
        enableNetworkLogs: false,
        allowInsecureHttpForDebug: true,
      );

      expect(
        NetworkConfig.fromAppConfig(appConfig).allowInsecureHttpForDebug,
        isFalse,
      );
    }

    const development = AppConfig(
      environment: AppEnvironment.dev,
      apiBaseUrl: 'http://localhost:8080',
      enableNetworkLogs: false,
      allowInsecureHttpForDebug: true,
    );
    expect(
      NetworkConfig.fromAppConfig(development).allowInsecureHttpForDebug,
      isTrue,
    );
  });
}
