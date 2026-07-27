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
      connectTimeout: config.connectTimeout,
      receiveTimeout: config.receiveTimeout,
      sendTimeout: config.sendTimeout,
      transformTimeout: config.transformTimeout,
      headers: config.defaultHeaders,
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final safeUri = Redactor.redactUri(options.uri);
        observability.addBreadcrumb(
          message: '${options.method} $safeUri',
          category: 'http',
          level: 'INFO',
        );

        if (config.enableNetworkLogs) {
          _log.info(
            'HTTP ${options.method} $safeUri '
            'headers=${Redactor.redactMap(options.headers)}',
          );
        }

        handler.next(options);
      },
      onError: (error, handler) {
        final safeUri = Redactor.redactUri(error.requestOptions.uri);
        _log.warning(
          'HTTP error ${error.requestOptions.method} '
          '$safeUri: ${Redactor.redact(error.message)}',
        );
        handler.next(error);
      },
    ),
  );

  return dio;
}
