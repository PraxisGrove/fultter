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
}
