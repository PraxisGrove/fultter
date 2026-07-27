import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/src/core/failures/failure.dart';
import 'package:{{app_name}}/src/features/reference/application/reference_detail_controller.dart';
import 'package:{{app_name}}/src/features/reference/application/reference_edit_controller.dart';
import 'package:{{app_name}}/src/features/reference/application/reference_list_controller.dart';
import 'package:{{app_name}}/src/features/reference/domain/reference_item.dart';
import 'package:{{app_name}}/src/features/reference/domain/reference_item_edit.dart';
import 'package:{{app_name}}/src/features/reference/domain/reference_page.dart';
import 'package:{{app_name}}/src/features/reference/domain/reference_repository.dart';

void main() {
  group('ReferenceListController', () {
    test('loads, deduplicates, and detects the end of the list', () async {
      final repository = _StubRepository(
        fetchPageHandler: ({required page, required pageSize}) async {
          return switch (page) {
            1 => const ReferencePage(
              items: [
                ReferenceItem(id: 'a', title: 'A', description: ''),
                ReferenceItem(id: 'a', title: 'A newer', description: ''),
              ],
              page: 1,
              hasMore: true,
            ),
            _ => const ReferencePage(
              items: [ReferenceItem(id: 'b', title: 'B', description: '')],
              page: 2,
              hasMore: false,
            ),
          };
        },
      );
      final controller = ReferenceListController(repository);
      addTearDown(controller.dispose);

      await controller.loadInitial();
      await controller.loadNextPage();

      expect(controller.state.phase, ReferenceListPhase.data);
      expect(controller.state.items.map((item) => item.id), ['a', 'b']);
      expect(controller.state.items.first.title, 'A newer');
      expect(controller.state.hasMore, isFalse);
      expect(repository.pageRequests, [1, 2]);
    });

    test('suppresses concurrent initial and next-page requests', () async {
      final firstPage = Completer<ReferencePage>();
      final secondPage = Completer<ReferencePage>();
      final repository = _StubRepository(
        fetchPageHandler: ({required page, required pageSize}) {
          return page == 1 ? firstPage.future : secondPage.future;
        },
      );
      final controller = ReferenceListController(repository);
      addTearDown(controller.dispose);

      final initialOne = controller.loadInitial();
      final initialTwo = controller.loadInitial();
      firstPage.complete(
        const ReferencePage(
          items: [ReferenceItem(id: 'a', title: 'A', description: '')],
          page: 1,
          hasMore: true,
        ),
      );
      await Future.wait([initialOne, initialTwo]);

      final nextOne = controller.loadNextPage();
      controller.replace(
        const ReferenceItem(id: 'a', title: 'Updated A', description: ''),
      );
      final nextTwo = controller.loadNextPage();
      secondPage.complete(
        const ReferencePage(items: [], page: 2, hasMore: false),
      );
      await Future.wait([nextOne, nextTwo]);

      expect(repository.pageRequests, [1, 2]);
      expect(controller.state.hasMore, isFalse);
      expect(controller.state.items.first.title, 'Updated A');
    });

    test('preserves existing items when a page fails and retries it', () async {
      var failNextPage = true;
      final repository = _StubRepository(
        fetchPageHandler: ({required page, required pageSize}) async {
          if (page == 1) {
            return const ReferencePage(
              items: [ReferenceItem(id: 'a', title: 'A', description: '')],
              page: 1,
              hasMore: true,
            );
          }
          if (failNextPage) {
            failNextPage = false;
            throw const TransportFailure(message: 'offline');
          }
          return const ReferencePage(
            items: [ReferenceItem(id: 'b', title: 'B', description: '')],
            page: 2,
            hasMore: false,
          );
        },
      );
      final controller = ReferenceListController(repository);
      addTearDown(controller.dispose);

      await controller.loadInitial();
      await controller.loadNextPage();

      expect(controller.state.items.single.id, 'a');
      expect(controller.state.nextPageFailure, isA<TransportFailure>());

      await controller.retryNextPage();

      expect(controller.state.items.map((item) => item.id), ['a', 'b']);
      expect(repository.pageRequests, [1, 2, 2]);
    });

    test('exposes deterministic empty and retryable error states', () async {
      var fails = true;
      final repository = _StubRepository(
        fetchPageHandler: ({required page, required pageSize}) async {
          if (fails) {
            throw const ServerFailure(message: 'unavailable');
          }
          return const ReferencePage(items: [], page: 1, hasMore: false);
        },
      );
      final controller = ReferenceListController(repository);
      addTearDown(controller.dispose);

      await controller.loadInitial();
      expect(controller.state.phase, ReferenceListPhase.failure);

      fails = false;
      await controller.retryInitial();
      expect(controller.state.phase, ReferenceListPhase.empty);
    });
  });

  group('ReferenceDetailController', () {
    test('retries a failed detail request', () async {
      var fails = true;
      final repository = _StubRepository(
        fetchByIdHandler: (id) async {
          if (fails) {
            throw const ServerFailure(message: 'unavailable');
          }
          return ReferenceItem(id: id, title: 'Loaded', description: 'Detail');
        },
      );
      final controller = ReferenceDetailController(repository, 'a');
      addTearDown(controller.dispose);

      await controller.load();
      expect(controller.state.phase, ReferenceDetailPhase.failure);

      fails = false;
      await controller.retry();
      expect(controller.state.item?.title, 'Loaded');
      expect(repository.detailRequests, 2);
    });
  });

  group('ReferenceEditController', () {
    test('rejects invalid input without writing', () async {
      final repository = _StubRepository(
        fetchByIdHandler: (id) async =>
            ReferenceItem(id: id, title: 'A', description: ''),
      );
      final controller = ReferenceEditController(
        repository,
        'a',
        onSaved: (_) {},
      );
      addTearDown(controller.dispose);
      await controller.load();

      final result = await controller.submit(title: '  ', description: '');

      expect(result, isNull);
      expect(repository.saveRequests, 0);
      expect(
        controller.state.submissionPhase,
        ReferenceSubmissionPhase.failure,
      );
    });

    test('suppresses duplicate saves and publishes the saved item', () async {
      final save = Completer<ReferenceItem>();
      final savedItems = <ReferenceItem>[];
      final repository = _StubRepository(
        fetchByIdHandler: (id) async =>
            ReferenceItem(id: id, title: 'A', description: ''),
        saveHandler: (edit) => save.future,
      );
      final controller = ReferenceEditController(
        repository,
        'a',
        onSaved: savedItems.add,
      );
      addTearDown(controller.dispose);
      await controller.load();

      final first = controller.submit(
        title: ' Updated ',
        description: ' Body ',
      );
      final second = controller.submit(title: 'Ignored', description: '');
      save.complete(
        const ReferenceItem(id: 'a', title: 'Updated', description: 'Body'),
      );
      await Future.wait([first, second]);

      expect(repository.saveRequests, 1);
      expect(savedItems.single.title, 'Updated');
      expect(
        controller.state.submissionPhase,
        ReferenceSubmissionPhase.success,
      );
    });

    test('preserves the editable item after a save failure', () async {
      final repository = _StubRepository(
        fetchByIdHandler: (id) async =>
            ReferenceItem(id: id, title: 'A', description: ''),
        saveHandler: (edit) async {
          throw const ServerFailure(message: 'unavailable');
        },
      );
      final controller = ReferenceEditController(
        repository,
        'a',
        onSaved: (_) {},
      );
      addTearDown(controller.dispose);
      await controller.load();

      await controller.submit(title: 'Updated', description: '');

      expect(controller.state.item?.title, 'A');
      expect(
        controller.state.submissionPhase,
        ReferenceSubmissionPhase.failure,
      );
    });
  });
}

typedef _FetchPage =
    Future<ReferencePage> Function({required int page, required int pageSize});

final class _StubRepository implements ReferenceRepository {
  _StubRepository({
    this.fetchPageHandler,
    this.fetchByIdHandler,
    this.saveHandler,
  });

  final _FetchPage? fetchPageHandler;
  final Future<ReferenceItem> Function(String id)? fetchByIdHandler;
  final Future<ReferenceItem> Function(ReferenceItemEdit edit)? saveHandler;

  final List<int> pageRequests = [];
  int detailRequests = 0;
  int saveRequests = 0;

  @override
  Future<ReferencePage> fetchPage({required int page, required int pageSize}) {
    pageRequests.add(page);
    final handler = fetchPageHandler;
    if (handler == null) {
      throw UnimplementedError();
    }
    return handler(page: page, pageSize: pageSize);
  }

  @override
  Future<ReferenceItem> fetchById(String id) {
    detailRequests += 1;
    final handler = fetchByIdHandler;
    if (handler == null) {
      throw UnimplementedError();
    }
    return handler(id);
  }

  @override
  Future<ReferenceItem> save(ReferenceItemEdit edit) {
    saveRequests += 1;
    final handler = saveHandler;
    if (handler == null) {
      throw UnimplementedError();
    }
    return handler(edit);
  }
}
