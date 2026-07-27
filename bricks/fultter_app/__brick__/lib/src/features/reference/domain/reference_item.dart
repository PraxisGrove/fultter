final class ReferenceItem {
  const ReferenceItem({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;

  ReferenceItem copyWith({String? title, String? description}) {
    return ReferenceItem(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
    );
  }

  @override
  bool operator ==(Object other) {
    return other is ReferenceItem &&
        other.id == id &&
        other.title == title &&
        other.description == description;
  }

  @override
  int get hashCode => Object.hash(id, title, description);
}
