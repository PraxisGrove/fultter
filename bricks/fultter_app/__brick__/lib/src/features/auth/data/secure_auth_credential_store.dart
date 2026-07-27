import '../../../core/security/secure_storage.dart';
import '../domain/auth.dart';

final class SecureAuthCredentialStore implements AuthCredentialStore {
  SecureAuthCredentialStore(
    this._storage, {
    this.storageKey = 'auth_credential',
  });

  final SecureStorage _storage;
  final String storageKey;

  @override
  Future<AuthCredential?> read() async {
    final value = await _storage.read(storageKey);
    return value == null ? null : AuthCredential(value);
  }

  @override
  Future<void> write(AuthCredential credential) {
    return _storage.write(storageKey, credential.value);
  }

  @override
  Future<void> clear() {
    return _storage.delete(storageKey);
  }
}
