import 'package:flutter/foundation.dart';

import '../domain/reference_item.dart';
import '../domain/reference_repository.dart';

enum ReferenceListPhase { initial, loading, data, empty, failure }

@immutable
final class ReferenceListState {
  const ReferenceListState({
    this.phase = ReferenceListPhase.initial,
    this.items = const [],
    this.hasMore = false,
    this.isLoadingNextPage = false,
    this.initialFailure,
    this.nextPageFailure,
  });

  final ReferenceListPhase phase;
  final List<ReferenceItem> items;
  final bool hasMore;
  final bool isLoadingNextPage;
  final Object? initialFailure;
  final Object? nextPageFailure;
}

final class ReferenceListController extends ChangeNotifier {
  ReferenceListController(this._repository, {this.pageSize = 10});

  final ReferenceRepository _repository;
  final int pageSize;

  ReferenceListState _state = const ReferenceListState();
  int _nextPage = 1;
  bool _initialRequestInFlight = false;
  bool _nextPageRequestInFlight = false;
  bool _disposed = false;

  ReferenceListState get state => _state;

  Future<void> loadInitial() async {
    if (_state.phase != ReferenceListPhase.initial) {
      return;
    }
    await _loadFirstPage();
  }

  Future<void> retryInitial() async {
    if (_state.phase != ReferenceListPhase.failure) {
      return;
    }
    await _loadFirstPage();
  }

  Future<void> _loadFirstPage() async {
    if (_initialRequestInFlight) {
      return;
    }
    _initialRequestInFlight = true;
    _setState(const ReferenceListState(phase: ReferenceListPhase.loading));
    try {
      final page = await _repository.fetchPage(page: 1, pageSize: pageSize);
      final items = _deduplicate(page.items);
      _nextPage = 2;
      _setState(
        items.isEmpty
            ? const ReferenceListState(phase: ReferenceListPhase.empty)
            : ReferenceListState(
                phase: ReferenceListPhase.data,
                items: items,
                hasMore: page.hasMore && page.items.isNotEmpty,
              ),
      );
    } on Object catch (error) {
      _setState(
        ReferenceListState(
          phase: ReferenceListPhase.failure,
          initialFailure: error,
        ),
      );
    } finally {
      _initialRequestInFlight = false;
    }
  }

  Future<void> loadNextPage() async {
    final current = _state;
    if (current.phase != ReferenceListPhase.data ||
        !current.hasMore ||
        _nextPageRequestInFlight) {
      return;
    }

    _nextPageRequestInFlight = true;
    _setState(
      ReferenceListState(
        phase: ReferenceListPhase.data,
        items: current.items,
        hasMore: current.hasMore,
        isLoadingNextPage: true,
      ),
    );
    try {
      final requestedPage = _nextPage;
      final page = await _repository.fetchPage(
        page: requestedPage,
        pageSize: pageSize,
      );
      final latest = _state.phase == ReferenceListPhase.data ? _state : current;
      final merged = _deduplicate([...latest.items, ...page.items]);
      _nextPage = requestedPage + 1;
      _setState(
        ReferenceListState(
          phase: ReferenceListPhase.data,
          items: merged,
          hasMore: page.hasMore && page.items.isNotEmpty,
        ),
      );
    } on Object catch (error) {
      final latest = _state.phase == ReferenceListPhase.data ? _state : current;
      _setState(
        ReferenceListState(
          phase: ReferenceListPhase.data,
          items: latest.items,
          hasMore: latest.hasMore,
          nextPageFailure: error,
        ),
      );
    } finally {
      _nextPageRequestInFlight = false;
    }
  }

  Future<void> retryNextPage() => loadNextPage();

  void replace(ReferenceItem updated) {
    if (_state.phase != ReferenceListPhase.data) {
      return;
    }
    var changed = false;
    final items = _state.items
        .map((item) {
          if (item.id != updated.id) {
            return item;
          }
          changed = item != updated;
          return updated;
        })
        .toList(growable: false);
    if (!changed) {
      return;
    }
    _setState(
      ReferenceListState(
        phase: ReferenceListPhase.data,
        items: List.unmodifiable(items),
        hasMore: _state.hasMore,
        isLoadingNextPage: _state.isLoadingNextPage,
        nextPageFailure: _state.nextPageFailure,
      ),
    );
  }

  List<ReferenceItem> _deduplicate(Iterable<ReferenceItem> items) {
    final unique = <String, ReferenceItem>{};
    for (final item in items) {
      unique[item.id] = item;
    }
    return List.unmodifiable(unique.values);
  }

  void _setState(ReferenceListState nextState) {
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
