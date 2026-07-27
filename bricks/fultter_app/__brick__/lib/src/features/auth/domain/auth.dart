enum AuthState {
  loading,
  unauthenticated,
  authenticated,
  sessionExpired,
}

final class AuthCredential {
  const AuthCredential(this.value);

  final String value;
}

abstract interface class AuthCredentialStore {
  Future<AuthCredential?> read();

  Future<void> write(AuthCredential credential);

  Future<void> clear();
}
