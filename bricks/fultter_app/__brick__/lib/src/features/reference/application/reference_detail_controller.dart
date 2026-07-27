import 'package:flutter/foundation.dart';

import '../domain/reference_item.dart';
import '../domain/reference_repository.dart';

enum ReferenceDetailPhase { initial, loading, data, failure }

@immutable
final class ReferenceDetailState {
  const ReferenceDetailState({
    this.phase = ReferenceDetailPhase.initial,
    this.item,
    this.failure,
  });

  final ReferenceDetailPhase phase;
  final ReferenceItem? item;
  final Object? failure;
}

final class ReferenceDetailController extends ChangeNotifier {
  ReferenceDetailController(this._repository, this.id);

  final ReferenceRepository _repository;
  final String id;

  ReferenceDetailState _state = const ReferenceDetailState();
  bool _requestInFlight = false;
  bool _disposed = false;

  ReferenceDetailState get state => _state;

  Future<void> load() async {
    if (_state.phase != ReferenceDetailPhase.initial) {
      return;
    }
    await _fetch();
  }

  Future<void> retry() async {
    if (_state.phase != ReferenceDetailPhase.failure) {
      return;
    }
    await _fetch();
  }

  Future<void> _fetch() async {
    if (_requestInFlight) {
      return;
    }
    _requestInFlight = true;
    _setState(const ReferenceDetailState(phase: ReferenceDetailPhase.loading));
    try {
      final item = await _repository.fetchById(id);
      _setState(
        ReferenceDetailState(phase: ReferenceDetailPhase.data, item: item),
      );
    } on Object catch (error) {
      _setState(
        ReferenceDetailState(
          phase: ReferenceDetailPhase.failure,
          failure: error,
        ),
      );
    } finally {
      _requestInFlight = false;
    }
  }

  void replace(ReferenceItem updated) {
    if (updated.id != id || _state.item == updated) {
      return;
    }
    _setState(
      ReferenceDetailState(phase: ReferenceDetailPhase.data, item: updated),
    );
  }

  void _setState(ReferenceDetailState nextState) {
    if (_disposed) {
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
