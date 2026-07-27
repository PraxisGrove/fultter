import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:{{app_name}}/l10n/app_localizations.dart';

import '../application/reference_edit_controller.dart';
import '../application/reference_providers.dart';

class ReferenceEditPage extends ConsumerStatefulWidget {
  const ReferenceEditPage({required this.id, super.key});

  final String id;

  @override
  ConsumerState<ReferenceEditPage> createState() => _ReferenceEditPageState();
}

class _ReferenceEditPageState extends ConsumerState<ReferenceEditPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String? _syncedItemId;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(
      ref.read(referenceEditControllerProvider(widget.id)).load,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final controller = ref.watch(referenceEditControllerProvider(widget.id));
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final state = controller.state;
        _syncFields(state);
        return Scaffold(
          appBar: AppBar(title: Text(localizations.referenceEditTitle)),
          body: switch (state.phase) {
            ReferenceEditPhase.initial => const SizedBox(
              key: Key('reference-edit-initial'),
            ),
            ReferenceEditPhase.loading => Center(
              key: const Key('reference-edit-loading'),
              child: CircularProgressIndicator(
                semanticsLabel: localizations.referenceEditLoading,
              ),
            ),
            ReferenceEditPhase.failure => _EditLoadFailure(
              message: localizations.referenceDetailError,
              retryLabel: localizations.retryAction,
              onRetry: controller.retryLoad,
            ),
            ReferenceEditPhase.ready => _buildForm(
              context,
              localizations,
              controller,
              state,
            ),
          },
        );
      },
    );
  }

  void _syncFields(ReferenceEditState state) {
    final item = state.item;
    if (item == null || _syncedItemId == item.id) {
      return;
    }
    _syncedItemId = item.id;
    _titleController.text = item.title;
    _descriptionController.text = item.description;
  }

  Widget _buildForm(
    BuildContext context,
    AppLocalizations localizations,
    ReferenceEditController controller,
    ReferenceEditState state,
  ) {
    final submitting =
        state.submissionPhase == ReferenceSubmissionPhase.submitting;
    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                key: const Key('reference-edit-form'),
                padding: const EdgeInsets.all(24),
                children: [
                  TextFormField(
                    key: const Key('reference-title-field'),
                    controller: _titleController,
                    enabled: !submitting,
                    textInputAction: TextInputAction.next,
                    maxLength: ReferenceEditValidation.titleMaxLength,
                    decoration: InputDecoration(
                      labelText: localizations.referenceTitleLabel,
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return localizations.referenceTitleRequired;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    key: const Key('reference-description-field'),
                    controller: _descriptionController,
                    enabled: !submitting,
                    minLines: 4,
                    maxLines: 8,
                    maxLength: ReferenceEditValidation.descriptionMaxLength,
                    decoration: InputDecoration(
                      labelText: localizations.referenceDescriptionLabel,
                      alignLabelWithHint: true,
                    ),
                  ),
                  if (state.submissionPhase ==
                      ReferenceSubmissionPhase.failure) ...[
                    const SizedBox(height: 16),
                    Text(
                      key: const Key('reference-save-error'),
                      localizations.referenceSaveError,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  if (state.submissionPhase ==
                      ReferenceSubmissionPhase.success) ...[
                    const SizedBox(height: 16),
                    Semantics(
                      liveRegion: true,
                      child: Text(
                        key: const Key('reference-save-success'),
                        localizations.referenceSaveSuccess,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const Key('reference-save-button'),
                onPressed: submitting ? null : () => _submit(controller),
                icon: submitting
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: Text(
                  submitting
                      ? localizations.referenceSaving
                      : localizations.referenceSaveAction,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _submit(ReferenceEditController controller) async {
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    await controller.submit(
      title: _titleController.text,
      description: _descriptionController.text,
    );
  }
}

class _EditLoadFailure extends StatelessWidget {
  const _EditLoadFailure({
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
      key: const Key('reference-edit-error'),
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
