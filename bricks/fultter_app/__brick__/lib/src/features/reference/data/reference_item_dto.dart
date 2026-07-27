import '../domain/reference_item.dart';

final class ReferenceItemDto {
  const ReferenceItemDto({
    required this.id,
    required this.name,
    required this.description,
  });

  factory ReferenceItemDto.fromJson(Map<String, Object?> json) {
    try {
      return ReferenceItemDto(
        id: json['id']! as String,
        name: json['name']! as String,
        description: json['description']! as String,
      );
    } on Object catch (error) {
      throw FormatException('Invalid reference item payload.', error);
    }
  }

  factory ReferenceItemDto.fromDomain(ReferenceItem item) {
    return ReferenceItemDto(
      id: item.id.value,
      name: item.name,
      description: item.description,
    );
  }

  final String id;
  final String name;
  final String description;

  ReferenceItem toDomain() {
    return ReferenceItem(
      id: ReferenceItemId(id),
      name: name,
      description: description,
    );
  }
}
