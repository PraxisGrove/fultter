import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/src/features/reference/data/reference_repository_provider.dart';
import 'package:{{app_name}}/src/features/reference/domain/reference_item.dart';
import 'package:{{app_name}}/src/features/reference/domain/reference_repository.dart';

void main() {
  test('repository implementation can be replaced through Riverpod', () {
    final replacement = _ReplacementRepository();
    final container = ProviderContainer(
      overrides: [referenceRepositoryProvider.overrideWithValue(replacement)],
    );
    addTearDown(container.dispose);

    expect(container.read(referenceRepositoryProvider), same(replacement));
  });
}

final class _ReplacementRepository implements ReferenceRepository {
  @override
  Future<ReferenceItem> fetchById(ReferenceItemId id) =>
      throw UnimplementedError();

  @override
  Future<ReferencePage> fetchPage(ReferencePageRequest request) =>
      throw UnimplementedError();

  @override
  Future<ReferenceItem> save(ReferenceItemUpdate update) =>
      throw UnimplementedError();
}
