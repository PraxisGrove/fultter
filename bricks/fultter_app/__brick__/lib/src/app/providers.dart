import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/networking/api_client.dart';
import '../core/networking/dio_factory.dart';
import '../core/networking/dio_api_client.dart';
import '../core/networking/network_config.dart';
import '../core/observability/observability.dart';
import '../core/security/secure_storage.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('AppConfig must be overridden during bootstrap.');
});

final observabilityProvider = Provider<Observability>((ref) {
  throw UnimplementedError('Observability must be overridden during bootstrap.');
});

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return FlutterSecureStorageAdapter();
});

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final observability = ref.watch(observabilityProvider);

  return createDio(
    NetworkConfig.fromAppConfig(config),
    observability,
  );
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return DioApiClient(ref.watch(dioProvider));
});
