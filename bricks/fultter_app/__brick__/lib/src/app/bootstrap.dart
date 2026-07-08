import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/config/app_config.dart';
import '../core/logging/app_logging.dart';
import '../core/observability/observability.dart';
import 'app.dart';
import 'providers.dart';

Future<void> bootstrap() async {
  final config = AppConfig.fromEnvironment();
  final observability = createObservability(config);

  configureLogging(
    enableConsoleLogs: config.enableNetworkLogs || config.isDebugLike,
    observability: observability,
  );

  await runZonedGuarded(
    () async {
      await observability.init();

      FlutterError.onError = (details) {
        FlutterError.presentError(details);
        observability.captureFlutterError(details);
      };

      runApp(
        ProviderScope(
          overrides: [
            appConfigProvider.overrideWithValue(config),
            observabilityProvider.overrideWithValue(observability),
          ],
          child: const App(),
        ),
      );
    },
    (error, stackTrace) {
      observability.captureException(error, stackTrace);
    },
  );
}
