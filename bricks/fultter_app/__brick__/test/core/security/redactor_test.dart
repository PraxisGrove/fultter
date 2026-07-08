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
  });
}
