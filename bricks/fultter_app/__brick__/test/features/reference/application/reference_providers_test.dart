import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/src/features/reference/application/reference_providers.dart';
import 'package:{{app_name}}/src/features/reference/data/fake_reference_repository.dart';
import 'package:{{app_name}}/src/features/reference/domain/reference_item.dart';

void main() {
  test('uses the fake repository by default', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(
      container.read(referenceRepositoryProvider),
      isA<FakeReferenceRepository>(),
    );
  });

  test('allows repository replacement without changing the contract', () async {
    final replacement = FakeReferenceRepository(
      seed: const [
        ReferenceItem(id: 'replacement', title: 'Replacement', description: ''),
      ],
    );
    final container = ProviderContainer(
      overrides: [referenceRepositoryProvider.overrideWithValue(replacement)],
    );
    addTearDown(container.dispose);

    final repository = container.read(referenceRepositoryProvider);

    expect((await repository.fetchById('replacement')).title, 'Replacement');
  });
}
