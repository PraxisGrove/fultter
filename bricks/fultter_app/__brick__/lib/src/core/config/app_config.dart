import 'app_environment.dart';

class AppConfig {
  const AppConfig({
    required this.environment,
    required this.apiBaseUrl,
    required this.sentryDsn,
    required this.enableNetworkLogs,
    required this.allowInsecureHttpForDebug,
  });

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      environment: AppEnvironment.parse(
        const String.fromEnvironment('APP_ENV', defaultValue: 'dev'),
      ),
      apiBaseUrl: const String.fromEnvironment(
        'API_BASE_URL',
        defaultValue: 'https://api-dev.example.com',
      ),
      sentryDsn: const String.fromEnvironment('SENTRY_DSN'),
      enableNetworkLogs: const bool.fromEnvironment(
        'ENABLE_NETWORK_LOGS',
        defaultValue: true,
      ),
      allowInsecureHttpForDebug: const bool.fromEnvironment(
        'ALLOW_INSECURE_HTTP_FOR_DEBUG',
      ),
    );
  }

  final AppEnvironment environment;
  final String apiBaseUrl;
  final String sentryDsn;
  final bool enableNetworkLogs;
  final bool allowInsecureHttpForDebug;

  bool get isDebugLike => environment != AppEnvironment.prod;
}
