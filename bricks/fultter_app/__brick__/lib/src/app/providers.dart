import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/failures/failure.dart';
import '../core/networking/api_client.dart';
import '../core/networking/dio_api_client.dart';
import '../core/networking/dio_factory.dart';
import '../core/networking/dio_failure_mapper.dart';
import '../core/networking/network_config.dart';
import '../core/observability/observability.dart';
import '../core/security/secure_storage.dart';
import '../features/auth/data/secure_auth_credential_store.dart';
import '../features/auth/domain/auth.dart';
import '../features/auth/presentation/auth_controller.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  throw UnimplementedError('AppConfig must be overridden during bootstrap.');
});

final observabilityProvider = Provider<Observability>((ref) {
  throw UnimplementedError(
    'Observability must be overridden during bootstrap.',
  );
});

final secureStorageProvider = Provider<SecureStorage>((ref) {
  return FlutterSecureStorageAdapter();
});

final authCredentialStoreProvider = Provider<AuthCredentialStore>((ref) {
  return SecureAuthCredentialStore(ref.watch(secureStorageProvider));
});

final authControllerProvider = Provider<AuthController>((ref) {
  final controller = AuthController(ref.watch(authCredentialStoreProvider));
  unawaited(controller.initialize());
  ref.onDispose(controller.dispose);
  return controller;
});

final dioProvider = Provider<Dio>((ref) {
  final config = ref.watch(appConfigProvider);
  final observability = ref.watch(observabilityProvider);

  return createDio(NetworkConfig.fromAppConfig(config), observability);
});

final failureMapperProvider = Provider<FailureMapper>((ref) {
  return const DioFailureMapper();
});

final apiClientProvider = Provider<ApiClient>((ref) {
  return DioApiClient(ref.watch(dioProvider), ref.watch(failureMapperProvider));
});
