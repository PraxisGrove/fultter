import '../../../core/failures/failure.dart';
import '../domain/reference_item.dart';
import '../domain/reference_item_edit.dart';
import '../domain/reference_page.dart';
import '../domain/reference_repository.dart';

enum FakeReferenceState { success, empty, failure }

final class FakeReferenceRepository implements ReferenceRepository {
  FakeReferenceRepository({Iterable<ReferenceItem>? seed})
    : _seed = _deduplicate(seed ?? defaultReferenceItems) {
    reset();
  }

  static final List<ReferenceItem> defaultReferenceItems = List.unmodifiable(
    List.generate(
      25,
      (index) => ReferenceItem(
        id: 'reference-${index + 1}',
        title: 'Reference item ${index + 1}',
        description: 'Local example ${index + 1}',
      ),
    ),
  );

  final List<ReferenceItem> _seed;
  final Map<String, ReferenceItem> _items = {};

  FakeReferenceState state = FakeReferenceState.success;
  Failure forcedFailure = const ServerFailure(
    message: 'The reference data source was forced to fail.',
  );

  static List<ReferenceItem> _deduplicate(Iterable<ReferenceItem> items) {
    final uniqueItems = <String, ReferenceItem>{};
    for (final item in items) {
      uniqueItems.putIfAbsent(item.id, () => item);
    }
    return List.unmodifiable(uniqueItems.values);
  }

  @override
  Future<ReferencePage> fetchPage({
    required int page,
    required int pageSize,
  }) async {
    _throwWhenForced();
    if (page < 1 || pageSize < 1) {
      throw const ValidationFailure(
        message: 'Page and page size must be greater than zero.',
      );
    }
    if (state == FakeReferenceState.empty) {
      return ReferencePage(items: const [], page: page, hasMore: false);
    }

    final values = _items.values.toList(growable: false);
    final start = (page - 1) * pageSize;
    if (start >= values.length) {
      return ReferencePage(items: const [], page: page, hasMore: false);
    }
    final requestedEnd = start + pageSize;
    final end = requestedEnd < values.length ? requestedEnd : values.length;
    return ReferencePage(
      items: List.unmodifiable(values.sublist(start, end)),
      page: page,
      hasMore: end < values.length,
    );
  }

  @override
  Future<ReferenceItem> fetchById(String id) async {
    _throwWhenForced();
    final item = _items[id];
    if (item == null || state == FakeReferenceState.empty) {
      throw UnknownFailure(
        message: 'Reference item "$id" was not found.',
        statusCode: 404,
      );
    }
    return item;
  }

  @override
  Future<ReferenceItem> save(ReferenceItemEdit edit) async {
    _throwWhenForced();
    final current = _items[edit.id];
    if (current == null || state == FakeReferenceState.empty) {
      throw UnknownFailure(
        message: 'Reference item "${edit.id}" was not found.',
        statusCode: 404,
      );
    }
    final updated = current.copyWith(
      title: edit.title,
      description: edit.description,
    );
    _items[edit.id] = updated;
    return updated;
  }

  void reset() {
    _items
      ..clear()
      ..addEntries(_seed.map((item) => MapEntry(item.id, item)));
    state = FakeReferenceState.success;
    forcedFailure = const ServerFailure(
      message: 'The reference data source was forced to fail.',
    );
  }

  void _throwWhenForced() {
    if (state == FakeReferenceState.failure) {
      throw forcedFailure;
    }
  }
}
