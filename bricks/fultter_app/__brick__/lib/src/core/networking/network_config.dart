import '../config/app_config.dart';
import '../config/app_environment.dart';

class NetworkConfig {
  const NetworkConfig({
    required this.baseUrl,
    required this.enableNetworkLogs,
    required this.allowInsecureHttpForDebug,
    this.connectTimeout = const Duration(seconds: 15),
    this.receiveTimeout = const Duration(seconds: 30),
    this.sendTimeout = const Duration(seconds: 30),
    this.transformTimeout = const Duration(seconds: 30),
    this.defaultHeaders = const {'Accept': 'application/json'},
  });

  factory NetworkConfig.fromAppConfig(AppConfig config) {
    return NetworkConfig(
      baseUrl: config.apiBaseUrl,
      enableNetworkLogs: config.enableNetworkLogs && config.isDebugLike,
      allowInsecureHttpForDebug:
          config.environment == AppEnvironment.dev &&
          config.allowInsecureHttpForDebug,
    );
  }

  final String baseUrl;
  final bool enableNetworkLogs;
  final bool allowInsecureHttpForDebug;
  final Duration connectTimeout;
  final Duration receiveTimeout;
  final Duration sendTimeout;
  final Duration transformTimeout;
  final Map<String, Object> defaultHeaders;
}
