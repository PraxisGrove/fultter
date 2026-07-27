import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/src/core/security/secure_storage.dart';
import 'package:{{app_name}}/src/features/auth/data/secure_auth_credential_store.dart';
import 'package:{{app_name}}/src/features/auth/domain/auth.dart';

void main() {
  test('reads, writes, and clears through SecureStorage', () async {
    final storage = _MemorySecureStorage();
    final store = SecureAuthCredentialStore(storage, storageKey: 'test_auth');

    expect(await store.read(), isNull);

    await store.write(const AuthCredential('opaque-value'));
    expect(storage.values['test_auth'], 'opaque-value');
    expect((await store.read())?.value, 'opaque-value');

    await store.clear();
    expect(storage.values, isEmpty);
  });
}

class _MemorySecureStorage implements SecureStorage {
  final Map<String, String> values = {};

  @override
  Future<void> delete(String key) async {
    values.remove(key);
  }

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async {
    values[key] = value;
  }
}
