import 'dart:io';

import 'package:dio/dio.dart';
import 'package:logging/logging.dart';

import '../observability/observability.dart';
import '../security/redactor.dart';
import 'network_config.dart';

final _log = Logger('Network');

Dio createDio(NetworkConfig config, Observability observability) {
  final baseUri = Uri.parse(config.baseUrl);
  if (baseUri.scheme != 'https' && !config.allowInsecureHttpForDebug) {
    throw StateError('API_BASE_URL must use HTTPS.');
  }

  final dio = Dio(
    BaseOptions(
      baseUrl: config.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        HttpHeaders.acceptHeader: 'application/json',
      },
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        observability.addBreadcrumb(
          message: '${options.method} ${options.uri}',
          category: 'http',
          level: 'INFO',
        );

        if (config.enableNetworkLogs) {
          _log.info(
            'HTTP ${options.method} ${options.uri} '
            'headers=${Redactor.redactMap(options.headers)}',
          );
        }

        handler.next(options);
      },
      onError: (error, handler) {
        _log.warning(
          'HTTP error ${error.requestOptions.method} '
          '${error.requestOptions.uri}: ${Redactor.redact(error.message)}',
          error,
          error.stackTrace,
        );
        handler.next(error);
      },
    ),
  );

  return dio;
}
