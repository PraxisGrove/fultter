import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:{{app_name}}/l10n/app_localizations.dart';

import '../../../app/display_settings.dart';
import '../../../app/router.dart';
import '../application/reference_list_controller.dart';
import '../application/reference_providers.dart';
import '../domain/reference_item.dart';

class ReferenceListPage extends ConsumerStatefulWidget {
  const ReferenceListPage({super.key});

  @override
  ConsumerState<ReferenceListPage> createState() => _ReferenceListPageState();
}

class _ReferenceListPageState extends ConsumerState<ReferenceListPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_loadMoreNearEnd);
    scheduleMicrotask(ref.read(referenceListControllerProvider).loadInitial);
  }

  void _loadMoreNearEnd() {
    if (!_scrollController.hasClients ||
        _scrollController.position.extentAfter > 240) {
      return;
    }
    unawaited(ref.read(referenceListControllerProvider).loadNextPage());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final controller = ref.watch(referenceListControllerProvider);
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.referenceListTitle),
        actions: [
          PopupMenuButton<ThemeMode>(
            initialValue: themeMode,
            tooltip: localizations.themeMenuTooltip,
            icon: const Icon(Icons.brightness_6_outlined),
            onSelected: ref.read(themeModeProvider.notifier).setThemeMode,
            itemBuilder: (context) => [
              _themeMenuItem(
                mode: ThemeMode.system,
                selectedMode: themeMode,
                label: localizations.themeSystem,
              ),
              _themeMenuItem(
                mode: ThemeMode.light,
                selectedMode: themeMode,
                label: localizations.themeLight,
              ),
              _themeMenuItem(
                mode: ThemeMode.dark,
                selectedMode: themeMode,
                label: localizations.themeDark,
              ),
            ],
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: controller,
        builder: (context, _) => _buildBody(context, localizations, controller),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations localizations,
    ReferenceListController controller,
  ) {
    final state = controller.state;
    return switch (state.phase) {
      ReferenceListPhase.initial => const SizedBox(
        key: Key('reference-list-initial'),
      ),
      ReferenceListPhase.loading => Center(
        key: const Key('reference-list-loading'),
        child: CircularProgressIndicator(
          semanticsLabel: localizations.referenceListLoading,
        ),
      ),
      ReferenceListPhase.empty => _EmptyList(
        key: const Key('reference-list-empty'),
        title: localizations.referenceListEmptyTitle,
        message: localizations.referenceListEmptyMessage,
      ),
      ReferenceListPhase.failure => _InitialFailure(
        key: const Key('reference-list-error'),
        message: localizations.referenceListError,
        retryLabel: localizations.retryAction,
        onRetry: controller.retryInitial,
      ),
      ReferenceListPhase.data => _ReferenceItems(
        controller: _scrollController,
        state: state,
        onLoadMore: controller.loadNextPage,
        onRetryNextPage: controller.retryNextPage,
      ),
    };
  }
}

class _ReferenceItems extends StatelessWidget {
  const _ReferenceItems({
    required this.controller,
    required this.state,
    required this.onLoadMore,
    required this.onRetryNextPage,
  });

  final ScrollController controller;
  final ReferenceListState state;
  final Future<void> Function() onLoadMore;
  final Future<void> Function() onRetryNextPage;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final showFooter = state.hasMore || state.nextPageFailure != null;
    return ListView.separated(
      key: const Key('reference-list-data'),
      controller: controller,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: state.items.length + (showFooter ? 1 : 0),
      separatorBuilder: (context, index) => const Divider(height: 1),
      itemBuilder: (context, index) {
        if (index < state.items.length) {
          return _ReferenceTile(item: state.items[index]);
        }
        if (state.nextPageFailure != null) {
          return Padding(
            key: const Key('reference-next-page-error'),
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              children: [
                Text(
                  localizations.referenceNextPageError,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: onRetryNextPage,
                  icon: const Icon(Icons.refresh),
                  label: Text(localizations.retryAction),
                ),
              ],
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Center(
            child: state.isLoadingNextPage
                ? CircularProgressIndicator(
                    key: const Key('reference-next-page-loading'),
                    semanticsLabel: localizations.referenceNextPageLoading,
                  )
                : FilledButton.tonalIcon(
                    key: const Key('reference-load-more'),
                    onPressed: onLoadMore,
                    icon: const Icon(Icons.expand_more),
                    label: Text(localizations.referenceLoadMore),
                  ),
          ),
        );
      },
    );
  }
}

class _ReferenceTile extends StatelessWidget {
  const _ReferenceTile({required this.item});

  final ReferenceItem item;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    void openDetail() {
      context.push(AppRoutes.referenceDetailPath(item.id));
    }

    return Semantics(
      button: true,
      excludeSemantics: true,
      label: '${item.title}. ${item.description}',
      onTap: openDetail,
      child: ListTile(
        key: Key('reference-item-${item.id}'),
        contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        title: Text(item.title),
        subtitle: item.description.isEmpty ? null : Text(item.description),
        trailing: Icon(
          Icons.chevron_right,
          semanticLabel: localizations.referenceOpenDetail,
        ),
        onTap: openDetail,
      ),
    );
  }
}

class _EmptyList extends StatelessWidget {
  const _EmptyList({required this.title, required this.message, super.key});

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 48),
            const SizedBox(height: 16),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

class _InitialFailure extends StatelessWidget {
  const _InitialFailure({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
    super.key,
  });

  final String message;
  final String retryLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(retryLabel),
            ),
          ],
        ),
      ),
    );
  }
}

PopupMenuItem<ThemeMode> _themeMenuItem({
  required ThemeMode mode,
  required ThemeMode selectedMode,
  required String label,
}) {
  return PopupMenuItem<ThemeMode>(
    value: mode,
    child: Row(
      children: [
        Icon(
          mode == selectedMode
              ? Icons.radio_button_checked
              : Icons.radio_button_unchecked,
        ),
        const SizedBox(width: 12),
        Flexible(child: Text(label)),
      ],
    ),
  );
}
