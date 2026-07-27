import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/auth.dart';

final class AuthController extends ChangeNotifier {
  AuthController(this._credentialStore);

  final AuthCredentialStore _credentialStore;
  Future<void> _operationTail = Future<void>.value();
  AuthState _state = AuthState.loading;
  bool _initialized = false;
  bool _disposed = false;

  AuthState get state => _state;

  Future<void> initialize() {
    if (_initialized) {
      return _operationTail;
    }
    _initialized = true;

    return _serialize(() async {
      try {
        final credential = await _credentialStore.read();
        _setState(
          credential == null
              ? AuthState.unauthenticated
              : AuthState.authenticated,
        );
      } on Object {
        // Secure storage failures fail closed without leaving routing suspended.
        _setState(AuthState.unauthenticated);
      }
    });
  }

  Future<void> authenticate(AuthCredential credential) {
    return _serialize(() async {
      await _credentialStore.write(credential);
      _setState(AuthState.authenticated);
    });
  }

  Future<void> signOut() {
    return _serialize(() async {
      try {
        await _credentialStore.clear();
      } finally {
        _setState(AuthState.unauthenticated);
      }
    });
  }

  Future<void> expireSession() {
    return _serialize(() async {
      try {
        await _credentialStore.clear();
      } finally {
        _setState(AuthState.sessionExpired);
      }
    });
  }

  Future<void> _serialize(Future<void> Function() operation) {
    final completer = Completer<void>();
    _operationTail = _operationTail.then((_) async {
      try {
        await operation();
        completer.complete();
      } on Object catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      }
    });
    return completer.future;
  }

  void _setState(AuthState nextState) {
    if (_disposed || nextState == _state) {
      return;
    }
    _state = nextState;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
