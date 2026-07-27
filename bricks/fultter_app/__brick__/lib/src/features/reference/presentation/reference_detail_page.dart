import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:{{app_name}}/l10n/app_localizations.dart';

import '../../../app/router.dart';
import '../application/reference_detail_controller.dart';
import '../application/reference_providers.dart';

class ReferenceDetailPage extends ConsumerStatefulWidget {
  const ReferenceDetailPage({required this.id, super.key});

  final String id;

  @override
  ConsumerState<ReferenceDetailPage> createState() =>
      _ReferenceDetailPageState();
}

class _ReferenceDetailPageState extends ConsumerState<ReferenceDetailPage> {
  @override
  void initState() {
    super.initState();
    scheduleMicrotask(
      ref.read(referenceDetailControllerProvider(widget.id)).load,
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final controller = ref.watch(referenceDetailControllerProvider(widget.id));
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;
        return Scaffold(
          appBar: AppBar(
            title: Text(localizations.referenceDetailTitle),
            actions: [
              if (state.phase == ReferenceDetailPhase.data)
                IconButton(
                  tooltip: localizations.referenceEditAction,
                  onPressed: () =>
                      context.push(AppRoutes.referenceEditPath(widget.id)),
                  icon: const Icon(Icons.edit_outlined),
                ),
            ],
          ),
          body: switch (state.phase) {
            ReferenceDetailPhase.initial => const SizedBox(
              key: Key('reference-detail-initial'),
            ),
            ReferenceDetailPhase.loading => Center(
              key: const Key('reference-detail-loading'),
              child: CircularProgressIndicator(
                semanticsLabel: localizations.referenceDetailLoading,
              ),
            ),
            ReferenceDetailPhase.failure => _DetailFailure(
              message: localizations.referenceDetailError,
              retryLabel: localizations.retryAction,
              onRetry: controller.retry,
            ),
            ReferenceDetailPhase.data => _DetailContent(
              title: state.item!.title,
              description: state.item!.description,
            ),
          },
        );
      },
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({required this.title, required this.description});

  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return ListView(
      key: const Key('reference-detail-data'),
      padding: const EdgeInsets.all(24),
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineSmall),
        const SizedBox(height: 24),
        Text(
          localizations.referenceDescriptionLabel,
          style: Theme.of(context).textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Text(
          description.isEmpty
              ? localizations.referenceNoDescription
              : description,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    );
  }
}

class _DetailFailure extends StatelessWidget {
  const _DetailFailure({
    required this.message,
    required this.retryLabel,
    required this.onRetry,
  });

  final String message;
  final String retryLabel;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      key: const Key('reference-detail-error'),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
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
