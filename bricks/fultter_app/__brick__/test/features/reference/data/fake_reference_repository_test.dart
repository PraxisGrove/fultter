import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/src/core/failures/failure.dart';
import 'package:{{app_name}}/src/features/reference/data/fake_reference_repository.dart';
import 'package:{{app_name}}/src/features/reference/domain/reference_item.dart';
import 'package:{{app_name}}/src/features/reference/domain/reference_item_edit.dart';

void main() {
  late FakeReferenceRepository repository;

  setUp(() {
    repository = FakeReferenceRepository(
      seed: const [
        ReferenceItem(id: 'one', title: 'One', description: 'First'),
        ReferenceItem(id: 'two', title: 'Two', description: 'Second'),
        ReferenceItem(id: 'two', title: 'Duplicate', description: 'Ignored'),
        ReferenceItem(id: 'three', title: 'Three', description: 'Third'),
        ReferenceItem(id: 'four', title: 'Four', description: 'Fourth'),
        ReferenceItem(id: 'five', title: 'Five', description: 'Fifth'),
      ],
    );
  });

  test(
    'paginates deterministic deduplicated seed data at boundaries',
    () async {
      final first = await repository.fetchPage(page: 1, pageSize: 2);
      final second = await repository.fetchPage(page: 2, pageSize: 2);
      final third = await repository.fetchPage(page: 3, pageSize: 2);

      expect(first.items.map((item) => item.id), ['one', 'two']);
      expect(first.hasMore, isTrue);
      expect(second.items.map((item) => item.id), ['three', 'four']);
      expect(second.hasMore, isTrue);
      expect(third.items.map((item) => item.id), ['five']);
      expect(third.hasMore, isFalse);
      expect((await repository.fetchPage(page: 4, pageSize: 2)).items, isEmpty);
    },
  );

  test('rejects invalid pagination inputs with a shared failure', () async {
    expect(
      repository.fetchPage(page: 0, pageSize: 2),
      throwsA(isA<ValidationFailure>()),
    );
    expect(
      repository.fetchPage(page: 1, pageSize: 0),
      throwsA(isA<ValidationFailure>()),
    );
  });

  test('supports explicit empty and forced failure states', () async {
    repository.state = FakeReferenceState.empty;
    expect((await repository.fetchPage(page: 1, pageSize: 2)).items, isEmpty);

    repository
      ..state = FakeReferenceState.failure
      ..forcedFailure = const TransportFailure(message: 'Offline test');
    expect(
      repository.fetchPage(page: 1, pageSize: 2),
      throwsA(isA<TransportFailure>()),
    );
    expect(repository.fetchById('one'), throwsA(isA<TransportFailure>()));
  });

  test('maps missing detail and edit targets to a 404 failure', () async {
    for (final operation in <Future<Object> Function()>[
      () => repository.fetchById('missing'),
      () => repository.save(
        const ReferenceItemEdit(
          id: 'missing',
          title: 'Missing',
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

  test('saved edits are visible in subsequent detail and list reads', () async {
    const edit = ReferenceItemEdit(
      id: 'two',
      title: 'Updated',
      description: 'Updated locally',
    );

    expect(await repository.save(edit), await repository.fetchById('two'));
    final page = await repository.fetchPage(page: 1, pageSize: 5);
    expect(page.items.singleWhere((item) => item.id == 'two').title, 'Updated');
  });

  test(
    'reset restores seed values, success state, and default failure',
    () async {
      await repository.save(
        const ReferenceItemEdit(
          id: 'one',
          title: 'Changed',
          description: 'Changed',
        ),
      );
      repository
        ..state = FakeReferenceState.failure
        ..forcedFailure = const TransportFailure();

      repository.reset();

      expect((await repository.fetchById('one')).title, 'One');
      expect(repository.state, FakeReferenceState.success);
      expect(repository.forcedFailure, isA<ServerFailure>());
    },
  );
}
