import '../../../core/failures/failure.dart';
import '../domain/reference_item.dart';
import '../domain/reference_repository.dart';
import 'reference_item_dto.dart';
import 'reference_item_fixtures.dart';

enum FakeReferenceState { success, empty, failure }

final class FakeReferenceRepositoryControl {
  FakeReferenceRepositoryControl({
    FakeReferenceState state = FakeReferenceState.success,
    Failure failure = const TransportFailure(),
  })  : _initialState = state,
        _initialFailure = failure,
        _state = state,
        _failure = failure;

  final FakeReferenceState _initialState;
  final Failure _initialFailure;
  FakeReferenceState _state;
  Failure _failure;

  FakeReferenceState get state => _state;
  Failure get failure => _failure;

  void showSuccess() => _state = FakeReferenceState.success;

  void showEmpty() => _state = FakeReferenceState.empty;

  void forceFailure([Failure failure = const TransportFailure()]) {
    _failure = failure;
    _state = FakeReferenceState.failure;
  }

  void reset() {
    _state = _initialState;
    _failure = _initialFailure;
  }
}

final class FakeReferenceRepository implements ReferenceRepository {
  FakeReferenceRepository({
    List<ReferenceItemDto> seedItems = referenceItemFixtures,
    FakeReferenceRepositoryControl? control,
  })  : _seedItems = List.unmodifiable(seedItems),
        control = control ?? FakeReferenceRepositoryControl() {
    _restoreItems();
  }

  final List<ReferenceItemDto> _seedItems;
  final FakeReferenceRepositoryControl control;
  final Map<String, ReferenceItemDto> _items = {};

  @override
  Future<ReferencePage> fetchPage(ReferencePageRequest request) async {
    _throwIfForcedFailure();
    if (control.state == FakeReferenceState.empty) {
      return ReferencePage(items: const [], nextOffset: null);
    }

    final items = _items.values.toList(growable: false);
    if (request.offset >= items.length) {
      return ReferencePage(items: const [], nextOffset: null);
    }

    final requestedEnd = request.offset + request.limit;
    final end = requestedEnd < items.length ? requestedEnd : items.length;
    return ReferencePage(
      items: items
          .sublist(request.offset, end)
          .map((item) => item.toDomain())
          .toList(growable: false),
      nextOffset: end < items.length ? end : null,
    );
  }

  @override
  Future<ReferenceItem> fetchById(ReferenceItemId id) async {
    _throwIfForcedFailure();
    final item =
        control.state == FakeReferenceState.empty ? null : _items[id.value];
    if (item == null) {
      throw const UnknownFailure(
        message: 'The reference item was not found.',
        statusCode: 404,
      );
    }
    return item.toDomain();
  }

  @override
  Future<ReferenceItem> save(ReferenceItemUpdate update) async {
    _throwIfForcedFailure();
    if (control.state == FakeReferenceState.empty ||
        !_items.containsKey(update.id.value)) {
      throw const UnknownFailure(
        message: 'The reference item was not found.',
        statusCode: 404,
      );
    }

    final saved = ReferenceItemDto(
      id: update.id.value,
      name: update.name,
      description: update.description,
    );
    _items[update.id.value] = saved;
    return saved.toDomain();
  }

  void reset() {
    _restoreItems();
    control.reset();
  }

  void _throwIfForcedFailure() {
    if (control.state == FakeReferenceState.failure) {
      throw control.failure;
    }
  }

  void _restoreItems() {
    _items.clear();
    for (final item in _seedItems) {
      _items.putIfAbsent(item.id, () => item);
    }
  }
}
