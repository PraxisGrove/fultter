import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:{{app_name}}/l10n/app_localizations.dart';
import 'package:{{app_name}}/src/core/failures/failure.dart';
import 'package:{{app_name}}/src/features/reference/application/reference_providers.dart';
import 'package:{{app_name}}/src/features/reference/domain/reference_item.dart';
import 'package:{{app_name}}/src/features/reference/domain/reference_item_edit.dart';
import 'package:{{app_name}}/src/features/reference/domain/reference_page.dart';
import 'package:{{app_name}}/src/features/reference/domain/reference_repository.dart';
import 'package:{{app_name}}/src/features/reference/presentation/reference_detail_page.dart';
import 'package:{{app_name}}/src/features/reference/presentation/reference_edit_page.dart';
import 'package:{{app_name}}/src/features/reference/presentation/reference_list_page.dart';

void main() {
  testWidgets(
    'shows loading, error, retry, and empty states deterministically',
    (tester) async {
      final firstRequest = Completer<ReferencePage>();
      var request = 0;
      final repository = _TestRepository(
        fetchPageHandler: ({required page, required pageSize}) {
          request += 1;
          if (request == 1) {
            return firstRequest.future;
          }
          return Future.value(
            const ReferencePage(items: [], page: 1, hasMore: false),
          );
        },
      );
      await _pumpReferenceApp(tester, repository);

      expect(find.byKey(const Key('reference-list-loading')), findsOneWidget);

      firstRequest.completeError(const TransportFailure(message: 'offline'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reference-list-error')), findsOneWidget);

      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reference-list-empty')), findsOneWidget);
      expect(repository.pageRequests, [1, 1]);
    },
  );

  testWidgets('page failure preserves prior items and can retry', (
    tester,
  ) async {
    var failSecondPage = true;
    final repository = _TestRepository(
      fetchPageHandler: ({required page, required pageSize}) async {
        if (page == 1) {
          return const ReferencePage(
            items: [ReferenceItem(id: 'a', title: 'Alpha', description: 'One')],
            page: 1,
            hasMore: true,
          );
        }
        if (failSecondPage) {
          failSecondPage = false;
          throw const TransportFailure(message: 'offline');
        }
        return const ReferencePage(
          items: [ReferenceItem(id: 'b', title: 'Beta', description: 'Two')],
          page: 2,
          hasMore: false,
        );
      },
    );
    await _pumpReferenceApp(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reference-load-more')));
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.byKey(const Key('reference-next-page-error')), findsOneWidget);

    await tester.tap(find.text('Try again'));
    await tester.pumpAndSettle();
    expect(find.text('Alpha'), findsOneWidget);
    expect(find.text('Beta'), findsOneWidget);
    expect(repository.pageRequests, [1, 2, 2]);
  });

  testWidgets('navigates through detail and edit, validates, and refreshes', (
    tester,
  ) async {
    final repository = _TestRepository.fromItems(const [
      ReferenceItem(id: 'a', title: 'Alpha', description: 'One'),
    ]);
    final semantics = tester.ensureSemantics();
    await _pumpReferenceApp(tester, repository);
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Alpha. One'), findsOneWidget);
    await tester.tap(find.text('Alpha'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reference-detail-data')), findsOneWidget);

    await tester.tap(find.byTooltip('Edit reference'));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reference-edit-form')), findsOneWidget);

    await tester.enterText(
      find.byKey(const Key('reference-title-field')),
      '   ',
    );
    await tester.tap(find.byKey(const Key('reference-save-button')));
    await tester.pump();
    expect(find.text('Enter a title.'), findsOneWidget);
    expect(repository.saveRequests, 0);

    await tester.enterText(
      find.byKey(const Key('reference-title-field')),
      'Updated alpha',
    );
    await tester.enterText(
      find.byKey(const Key('reference-description-field')),
      'Updated description',
    );
    await tester.tap(find.byKey(const Key('reference-save-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reference-save-success')), findsOneWidget);
    expect(repository.saveRequests, 1);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Updated alpha'), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.text('Updated alpha'), findsOneWidget);
    semantics.dispose();
  });

  testWidgets('disables the save action while a write is pending', (
    tester,
  ) async {
    final save = Completer<ReferenceItem>();
    final repository = _TestRepository.fromItems(
      const [ReferenceItem(id: 'a', title: 'Alpha', description: 'One')],
      saveHandler: (edit) {
        return save.future;
      },
    );
    await _pumpReferenceApp(
      tester,
      repository,
      initialLocation: '/references/a/edit',
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('reference-save-button')));
    await tester.pump();
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.tap(find.byKey(const Key('reference-save-button')));
    expect(repository.saveRequests, 1);

    save.complete(
      const ReferenceItem(id: 'a', title: 'Alpha', description: 'One'),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('reference-save-success')), findsOneWidget);
  });

  testWidgets(
    'list and edit controls do not overflow at 200 percent text scale',
    (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1;
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final repository = _TestRepository.fromItems(const [
        ReferenceItem(
          id: 'a',
          title: 'A reference title that wraps',
          description:
              'A description that remains readable when text is large.',
        ),
      ]);
      await _pumpReferenceApp(tester, repository);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('A reference title that wraps'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Edit reference'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('reference-save-button')), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('adapts to small portrait, landscape, and tablet viewports', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;
    final repository = _TestRepository.fromItems(const [
      ReferenceItem(id: 'a', title: 'Alpha', description: 'One'),
    ]);

    for (final size in const [
      Size(375, 667),
      Size(800, 375),
      Size(1024, 768),
    ]) {
      tester.view.physicalSize = size;
      await _pumpReferenceApp(tester, repository);
      await tester.pumpAndSettle();

      expect(find.text('References'), findsOneWidget);
      expect(find.text('Alpha'), findsOneWidget);
      expect(tester.takeException(), isNull, reason: 'viewport $size');
    }
  });
}

Future<void> _pumpReferenceApp(
  WidgetTester tester,
  ReferenceRepository repository, {
  String initialLocation = '/',
}) async {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const ReferenceListPage(),
      ),
      GoRoute(
        path: '/references/:id/edit',
        builder: (context, state) =>
            ReferenceEditPage(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/references/:id',
        builder: (context, state) =>
            ReferenceDetailPage(id: state.pathParameters['id']!),
      ),
    ],
  );
  addTearDown(router.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [referenceRepositoryProvider.overrideWithValue(repository)],
      child: MaterialApp.router(
        routerConfig: router,
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    ),
  );
  await tester.pump();
}

typedef _FetchPage =
    Future<ReferencePage> Function({
      required int page,
      required int pageSize,
    });

final class _TestRepository implements ReferenceRepository {
  _TestRepository({
    required this.fetchPageHandler,
    this.fetchByIdHandler,
    this.saveHandler,
  });

  factory _TestRepository.fromItems(
    List<ReferenceItem> items, {
    Future<ReferenceItem> Function(ReferenceItemEdit edit)? saveHandler,
  }) {
    final stored = {for (final item in items) item.id: item};
    return _TestRepository(
      fetchPageHandler: ({required page, required pageSize}) async {
        return ReferencePage(
          items: List.unmodifiable(stored.values),
          page: page,
          hasMore: false,
        );
      },
      fetchByIdHandler: (id) async => stored[id]!,
      saveHandler:
          saveHandler ??
          (edit) async {
            final saved = ReferenceItem(
              id: edit.id,
              title: edit.title,
              description: edit.description,
            );
            stored[edit.id] = saved;
            return saved;
          },
    );
  }

  final _FetchPage fetchPageHandler;
  final Future<ReferenceItem> Function(String id)? fetchByIdHandler;
  final Future<ReferenceItem> Function(ReferenceItemEdit edit)? saveHandler;

  final List<int> pageRequests = [];
  int saveRequests = 0;

  @override
  Future<ReferencePage> fetchPage({required int page, required int pageSize}) {
    pageRequests.add(page);
    return fetchPageHandler(page: page, pageSize: pageSize);
  }

  @override
  Future<ReferenceItem> fetchById(String id) {
    return fetchByIdHandler!(id);
  }

  @override
  Future<ReferenceItem> save(ReferenceItemEdit edit) {
    saveRequests += 1;
    return saveHandler!(edit);
  }
}
