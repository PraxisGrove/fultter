final class ReferenceItemId {
  const ReferenceItemId(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReferenceItemId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

final class ReferenceItem {
  const ReferenceItem({
    required this.id,
    required this.name,
    required this.description,
  });

  final ReferenceItemId id;
  final String name;
  final String description;
}

final class ReferenceItemUpdate {
  const ReferenceItemUpdate({
    required this.id,
    required this.name,
    required this.description,
  });

  final ReferenceItemId id;
  final String name;
  final String description;
}
