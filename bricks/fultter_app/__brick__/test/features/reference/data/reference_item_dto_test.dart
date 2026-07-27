import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/src/features/reference/data/reference_item_dto.dart';
import 'package:{{app_name}}/src/features/reference/domain/reference_item.dart';

void main() {
  test('maps validated JSON to and from the domain entity', () {
    final dto = ReferenceItemDto.fromJson(const {
      'id': 'ref-100',
      'name': 'Reference',
      'description': 'Neutral details',
    });
    final item = dto.toDomain();

    expect(item.id, const ReferenceItemId('ref-100'));
    expect(item.name, 'Reference');
    expect(ReferenceItemDto.fromDomain(item).description, 'Neutral details');
  });

  test('rejects malformed payloads at the data boundary', () {
    expect(
      () => ReferenceItemDto.fromJson(const {
        'id': 100,
        'name': 'Reference',
        'description': 'Neutral details',
      }),
      throwsFormatException,
    );
  });
}
