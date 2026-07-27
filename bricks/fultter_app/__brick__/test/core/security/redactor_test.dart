import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/src/core/security/redactor.dart';

void main() {
  group('Redactor', () {
    test('redacts sensitive message values', () {
      final output = Redactor.redact(
        'Authorization: Bearer secret-token password=secret token=abc',
      );

      expect(output, isNot(contains('secret-token')));
      expect(output, isNot(contains('secret')));
      expect(output, contains('[REDACTED]'));
    });

    test('redacts JSON-shaped message values', () {
      final output = Redactor.redact(
        '{"access_token":"secret-token","safe":"value"}',
      );

      expect(output, isNot(contains('secret-token')));
      expect(output, contains('"safe":"value"'));
    });

    test('redacts sensitive map values', () {
      final output = Redactor.redactMap({
        'authorization': 'Bearer secret',
        'x-api-key': 'key',
        'safe': 'value',
      });

      expect(output['authorization'], '[REDACTED]');
      expect(output['x-api-key'], '[REDACTED]');
      expect(output['safe'], 'value');
    });

    test('redacts nested values and common key variants', () {
      final output = Redactor.redactMap({
        'profile': {
          'access_token': 'access-secret',
          'nested': [
            {'apiKey': 'api-secret'},
            {'client-secret': 'client-secret-value'},
          ],
        },
        'count': 2,
      });

      expect(output.toString(), isNot(contains('access-secret')));
      expect(output.toString(), isNot(contains('api-secret')));
      expect(output.toString(), isNot(contains('client-secret-value')));
      expect(output.toString(), contains('[REDACTED]'));
      expect(output['count'], 2);
    });

    test('redacts sensitive URI query parameters', () {
      final output = Redactor.redactUri(
        Uri.parse(
          'https://api.example.com/items?access_token=secret&safe=value',
        ),
      );

      expect(output, isNot(contains('secret')));
      expect(output, contains('safe=value'));
    });
  });
}
