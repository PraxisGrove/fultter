import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/src/core/config/app_config.dart';
import 'package:{{app_name}}/src/core/config/app_environment.dart';

void main() {
  test('uses safe defaults when dart defines are absent', () {
    final config = AppConfig.fromEnvironment();

    expect(config.environment, AppEnvironment.dev);
    expect(config.apiBaseUrl, startsWith('https://'));
    expect(config.enableNetworkLogs, isTrue);
    expect(config.allowInsecureHttpForDebug, isFalse);
  });
}
