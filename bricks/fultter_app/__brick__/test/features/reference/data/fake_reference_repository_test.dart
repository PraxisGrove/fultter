import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/src/core/failures/failure.dart';
import 'package:{{app_name}}/src/features/reference/data/fake_reference_repository.dart';
import 'package:{{app_name}}/src/features/reference/data/reference_item_dto.dart';
import 'package:{{app_name}}/src/features/reference/domain/reference_item.dart';
import 'package:{{app_name}}/src/features/reference/domain/reference_repository.dart';

void main() {
  const items = [
    ReferenceItemDto(id: 'a', name: 'Alpha', description: 'First'),
    ReferenceItemDto(id: 'b', name: 'Beta', description: 'Second'),
    ReferenceItemDto(id: 'b', name: 'Duplicate', description: 'Ignored'),
    ReferenceItemDto(id: 'c', name: 'Gamma', description: 'Third'),
    ReferenceItemDto(id: 'd', name: 'Delta', description: 'Fourth'),
    ReferenceItemDto(id: 'e', name: 'Epsilon', description: 'Fifth'),
  ];

  late FakeReferenceRepositoryControl control;
  late FakeReferenceRepository repository;

  setUp(() {
    control = FakeReferenceRepositoryControl();
    repository = FakeReferenceRepository(seedItems: items, control: control);
  });

  test(
    'pages deterministic deduplicated seed data across boundaries',
    () async {
      final first = await repository.fetchPage(
        ReferencePageRequest(offset: 0, limit: 2),
      );
      final second = await repository.fetchPage(
        ReferencePageRequest(offset: first.nextOffset!, limit: 2),
      );
      final finalPage = await repository.fetchPage(
        ReferencePageRequest(offset: second.nextOffset!, limit: 2),
      );

      expect(first.items.map((item) => item.id.value), ['a', 'b']);
      expect(first.items.last.name, 'Beta');
      expect(second.items.map((item) => item.id.value), ['c', 'd']);
      expect(finalPage.items.map((item) => item.id.value), ['e']);
      expect(finalPage.nextOffset, isNull);
    },
  );

  test('returns an empty terminal page beyond the last item', () async {
    final page = await repository.fetchPage(
      ReferencePageRequest(offset: 10, limit: 2),
    );

    expect(page.items, isEmpty);
    expect(page.nextOffset, isNull);
  });

  test('saved edits are visible in detail and list reads', () async {
    const update = ReferenceItemUpdate(
      id: ReferenceItemId('b'),
      name: 'Updated',
      description: 'Updated details',
    );

    await repository.save(update);

    expect((await repository.fetchById(update.id)).name, 'Updated');
    final page = await repository.fetchPage(
      ReferencePageRequest(offset: 0, limit: 2),
    );
    expect(page.items.last.description, 'Updated details');
  });

  test('empty and forced failure states are explicit and immediate', () async {
    control.showEmpty();
    expect(
      (await repository.fetchPage(
        ReferencePageRequest(offset: 0, limit: 2),
      ))
          .items,
      isEmpty,
    );

    control.forceFailure(const TimeoutFailure(message: 'forced'));
    await expectLater(
      repository.fetchPage(ReferencePageRequest(offset: 0, limit: 2)),
      throwsA(isA<TimeoutFailure>()),
    );
  });

  test('missing detail and edit map to the shared failure contract', () async {
    for (final operation in <Future<Object> Function()>[
      () => repository.fetchById(const ReferenceItemId('missing')),
      () => repository.save(
            const ReferenceItemUpdate(
              id: ReferenceItemId('missing'),
              name: 'Missing',
              description: 'Missing',
            ),
          ),
    ]) {
      await expectLater(
        operation(),
        throwsA(
          isA<UnknownFailure>().having(
            (failure) => failure.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
    }
  });

  test('reset restores seed data and the initial control state', () async {
    await repository.save(
      const ReferenceItemUpdate(
        id: ReferenceItemId('a'),
        name: 'Changed',
        description: 'Changed',
      ),
    );
    control.forceFailure(const ServerFailure());

    repository.reset();

    expect(control.state, FakeReferenceState.success);
    expect(
      (await repository.fetchById(const ReferenceItemId('a'))).name,
      'Alpha',
    );
  });
}
