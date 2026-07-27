import 'reference_item.dart';

final class ReferencePageRequest {
  ReferencePageRequest({required this.offset, required this.limit}) {
    if (offset < 0) {
      throw ArgumentError.value(offset, 'offset', 'Must not be negative.');
    }
    if (limit <= 0) {
      throw ArgumentError.value(limit, 'limit', 'Must be greater than zero.');
    }
  }

  final int offset;
  final int limit;
}

final class ReferencePage {
  ReferencePage({required List<ReferenceItem> items, required this.nextOffset})
      : items = List.unmodifiable(items);

  final List<ReferenceItem> items;
  final int? nextOffset;
}

abstract interface class ReferenceRepository {
  /// Returns a stable page or throws a shared `Failure` implementation.
  ///
  /// The failure type is intentionally documented rather than imported so
  /// this domain contract stays independent of shared infrastructure paths.
  Future<ReferencePage> fetchPage(ReferencePageRequest request);

  Future<ReferenceItem> fetchById(ReferenceItemId id);

  Future<ReferenceItem> save(ReferenceItemUpdate update);
}
