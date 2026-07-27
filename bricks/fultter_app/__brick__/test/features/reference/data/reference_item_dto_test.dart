import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/src/core/failures/failure.dart';
import 'package:{{app_name}}/src/features/reference/data/reference_item_dto.dart';
import 'package:{{app_name}}/src/features/reference/domain/reference_item.dart';

void main() {
  test('maps between wire and domain representations', () {
    const item = ReferenceItem(
      id: 'reference-1',
      title: 'Reference item',
      description: 'Local example',
    );

    final dto = ReferenceItemDto.fromDomain(item);

    expect(dto.toDomain(), item);
    expect(ReferenceItemDto.fromJson(dto.toJson()).toDomain(), item);
  });

  test('maps malformed wire data to the shared serialization failure', () {
    expect(
      () => ReferenceItemDto.fromJson(const {'id': 'reference-1'}),
      throwsA(isA<SerializationFailure>()),
    );
  });
}
