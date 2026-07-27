import '../config/app_config.dart';

class NetworkConfig {
  const NetworkConfig({
    required this.baseUrl,
    required this.enableNetworkLogs,
    required this.allowInsecureHttpForDebug,
  });

  factory NetworkConfig.fromAppConfig(AppConfig config) {
    return NetworkConfig(
      baseUrl: config.apiBaseUrl,
      enableNetworkLogs: config.enableNetworkLogs && config.isDebugLike,
      allowInsecureHttpForDebug: config.allowInsecureHttpForDebug,
    );
  }

  final String baseUrl;
  final bool enableNetworkLogs;
  final bool allowInsecureHttpForDebug;
}
