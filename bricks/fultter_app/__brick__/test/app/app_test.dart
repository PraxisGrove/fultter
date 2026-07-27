import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{app_name}}/src/app/app.dart';
import 'package:{{app_name}}/src/app/providers.dart';
import 'package:{{app_name}}/src/core/config/app_config.dart';
import 'package:{{app_name}}/src/core/config/app_environment.dart';
import 'package:{{app_name}}/src/core/observability/observability.dart';

void main() {
  testWidgets('renders starter home page', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appConfigProvider.overrideWithValue(
            const AppConfig(
              environment: AppEnvironment.dev,
              apiBaseUrl: 'https://api.example.com',
              enableNetworkLogs: true,
              allowInsecureHttpForDebug: false,
            ),
          ),
          observabilityProvider.overrideWithValue(NoopObservability()),
        ],
        child: const App(),
      ),
    );

    expect(find.text('Ready.'), findsOneWidget);
  });
}
