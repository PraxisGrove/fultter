import '../../../core/failures/failure.dart';
import '../domain/reference_item.dart';

final class ReferenceItemDto {
  const ReferenceItemDto({
    required this.id,
    required this.title,
    required this.description,
  });

  factory ReferenceItemDto.fromJson(Map<String, Object?> json) {
    try {
      return ReferenceItemDto(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
      );
    } on Object {
      throw const SerializationFailure(
        message: 'Reference item data has an unexpected shape.',
      );
    }
  }

  factory ReferenceItemDto.fromDomain(ReferenceItem item) {
    return ReferenceItemDto(
      id: item.id,
      title: item.title,
      description: item.description,
    );
  }

  final String id;
  final String title;
  final String description;

  ReferenceItem toDomain() {
    return ReferenceItem(id: id, title: title, description: description);
  }

  Map<String, Object?> toJson() {
    return {'id': id, 'title': title, 'description': description};
  }
}
