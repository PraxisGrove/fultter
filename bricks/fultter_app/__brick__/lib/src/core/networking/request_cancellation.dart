typedef RequestCancellationListener = void Function(String? reason);

abstract interface class RequestCancellationToken {
  bool get isCancelled;
  String? get reason;

  void addListener(RequestCancellationListener listener);
  void removeListener(RequestCancellationListener listener);
}

class RequestCancellationController {
  RequestCancellationController();

  final _RequestCancellationToken _token = _RequestCancellationToken();

  RequestCancellationToken get token => _token;

  void cancel([String? reason]) => _token.cancel(reason);
}

class _RequestCancellationToken implements RequestCancellationToken {
  final Set<RequestCancellationListener> _listeners = {};

  @override
  bool get isCancelled => _isCancelled;
  bool _isCancelled = false;

  @override
  String? get reason => _reason;
  String? _reason;

  @override
  void addListener(RequestCancellationListener listener) {
    if (_isCancelled) {
      listener(_reason);
      return;
    }
    _listeners.add(listener);
  }

  @override
  void removeListener(RequestCancellationListener listener) {
    _listeners.remove(listener);
  }

  void cancel(String? reason) {
    if (_isCancelled) {
      return;
    }

    _isCancelled = true;
    _reason = reason;
    final listeners = List<RequestCancellationListener>.of(_listeners);
    _listeners.clear();
    for (final listener in listeners) {
      listener(reason);
    }
  }
}
