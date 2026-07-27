import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/src/features/auth/domain/auth.dart';
import 'package:{{app_name}}/src/features/auth/presentation/auth_controller.dart';

void main() {
  test('restores an authenticated session from stored credentials', () async {
    final store = _MemoryCredentialStore(
      credential: const AuthCredential('stored'),
    );
    final controller = AuthController(store);
    addTearDown(controller.dispose);

    expect(controller.state, AuthState.loading);
    await controller.initialize();

    expect(controller.state, AuthState.authenticated);
    expect(store.readCount, 1);
  });

  test('restores an unauthenticated session when storage is empty', () async {
    final controller = AuthController(_MemoryCredentialStore());
    addTearDown(controller.dispose);

    await controller.initialize();

    expect(controller.state, AuthState.unauthenticated);
  });

  test('fails closed when credentials cannot be read', () async {
    final controller = AuthController(_MemoryCredentialStore(failRead: true));
    addTearDown(controller.dispose);

    await controller.initialize();

    expect(controller.state, AuthState.unauthenticated);
  });

  test('writes credentials before publishing authentication', () async {
    final store = _MemoryCredentialStore();
    final controller = AuthController(store);
    addTearDown(controller.dispose);
    await controller.initialize();

    await controller.authenticate(const AuthCredential('new'));

    expect(store.credential?.value, 'new');
    expect(controller.state, AuthState.authenticated);
  });

  test('expiry clears credentials and publishes session expiry', () async {
    final store = _MemoryCredentialStore(
      credential: const AuthCredential('stored'),
    );
    final controller = AuthController(store);
    addTearDown(controller.dispose);
    await controller.initialize();

    await controller.expireSession();

    expect(store.credential, isNull);
    expect(store.clearCount, 1);
    expect(controller.state, AuthState.sessionExpired);
  });

  test('sign-out clears credentials and publishes unauthenticated', () async {
    final store = _MemoryCredentialStore(
      credential: const AuthCredential('stored'),
    );
    final controller = AuthController(store);
    addTearDown(controller.dispose);
    await controller.initialize();

    await controller.signOut();

    expect(store.credential, isNull);
    expect(store.clearCount, 1);
    expect(controller.state, AuthState.unauthenticated);
  });

  test('serializes rapid authentication and expiry changes', () async {
    final store = _ControlledCredentialStore();
    final controller = AuthController(store);
    addTearDown(controller.dispose);
    await controller.initialize();

    final authentication = controller.authenticate(
      const AuthCredential('new'),
    );
    final expiry = controller.expireSession();
    await Future<void>.delayed(Duration.zero);

    expect(store.writeStarted, isTrue);
    expect(store.clearCount, 0);

    store.completeWrite();
    await Future.wait([authentication, expiry]);

    expect(store.credential, isNull);
    expect(store.clearCount, 1);
    expect(controller.state, AuthState.sessionExpired);
  });
}

class _MemoryCredentialStore implements AuthCredentialStore {
  _MemoryCredentialStore({
    this.credential,
    this.failRead = false,
  });

  AuthCredential? credential;
  final bool failRead;
  int readCount = 0;
  int clearCount = 0;

  @override
  Future<void> clear() async {
    clearCount += 1;
    credential = null;
  }

  @override
  Future<AuthCredential?> read() async {
    readCount += 1;
    if (failRead) {
      throw StateError('storage unavailable');
    }
    return credential;
  }

  @override
  Future<void> write(AuthCredential credential) async {
    this.credential = credential;
  }
}

class _ControlledCredentialStore extends _MemoryCredentialStore {
  final Completer<void> _writeCompleter = Completer<void>();
  bool writeStarted = false;

  @override
  Future<void> write(AuthCredential credential) async {
    writeStarted = true;
    await _writeCompleter.future;
    await super.write(credential);
  }

  void completeWrite() {
    _writeCompleter.complete();
  }
}
