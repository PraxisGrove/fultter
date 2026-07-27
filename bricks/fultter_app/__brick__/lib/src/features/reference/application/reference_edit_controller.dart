import 'package:flutter/foundation.dart';

import '../../../core/failures/failure.dart';
import '../domain/reference_item.dart';
import '../domain/reference_item_edit.dart';
import '../domain/reference_repository.dart';

enum ReferenceEditPhase { initial, loading, ready, failure }

enum ReferenceSubmissionPhase { idle, submitting, failure, success }

abstract final class ReferenceEditValidation {
  static const titleMaxLength = 80;
  static const descriptionMaxLength = 500;

  static bool isValid({required String title, required String description}) {
    final normalizedTitle = title.trim();
    return normalizedTitle.isNotEmpty &&
        normalizedTitle.length <= titleMaxLength &&
        description.trim().length <= descriptionMaxLength;
  }
}

@immutable
final class ReferenceEditState {
  const ReferenceEditState({
    this.phase = ReferenceEditPhase.initial,
    this.submissionPhase = ReferenceSubmissionPhase.idle,
    this.item,
    this.loadFailure,
    this.submissionFailure,
  });

  final ReferenceEditPhase phase;
  final ReferenceSubmissionPhase submissionPhase;
  final ReferenceItem? item;
  final Object? loadFailure;
  final Object? submissionFailure;
}

final class ReferenceEditController extends ChangeNotifier {
  ReferenceEditController(this._repository, this.id, {required this.onSaved});

  final ReferenceRepository _repository;
  final String id;
  final void Function(ReferenceItem item) onSaved;

  ReferenceEditState _state = const ReferenceEditState();
  bool _loadInFlight = false;
  bool _disposed = false;

  ReferenceEditState get state => _state;

  Future<void> load() async {
    if (_state.phase != ReferenceEditPhase.initial) {
      return;
    }
    await _fetch();
  }

  Future<void> retryLoad() async {
    if (_state.phase != ReferenceEditPhase.failure) {
      return;
    }
    await _fetch();
  }

  Future<void> _fetch() async {
    if (_loadInFlight) {
      return;
    }
    _loadInFlight = true;
    _setState(const ReferenceEditState(phase: ReferenceEditPhase.loading));
    try {
      final item = await _repository.fetchById(id);
      _setState(
        ReferenceEditState(phase: ReferenceEditPhase.ready, item: item),
      );
    } on Object catch (error) {
      _setState(
        ReferenceEditState(
          phase: ReferenceEditPhase.failure,
          loadFailure: error,
        ),
      );
    } finally {
      _loadInFlight = false;
    }
  }

  Future<ReferenceItem?> submit({
    required String title,
    required String description,
  }) async {
    final current = _state;
    if (current.phase != ReferenceEditPhase.ready ||
        current.submissionPhase == ReferenceSubmissionPhase.submitting) {
      return null;
    }

    final normalizedTitle = title.trim();
    final normalizedDescription = description.trim();
    if (!ReferenceEditValidation.isValid(
      title: normalizedTitle,
      description: normalizedDescription,
    )) {
      _setState(
        ReferenceEditState(
          phase: ReferenceEditPhase.ready,
          item: current.item,
          submissionPhase: ReferenceSubmissionPhase.failure,
          submissionFailure: const ValidationFailure(
            message: 'The reference item contains invalid fields.',
          ),
        ),
      );
      return null;
    }

    _setState(
      ReferenceEditState(
        phase: ReferenceEditPhase.ready,
        item: current.item,
        submissionPhase: ReferenceSubmissionPhase.submitting,
      ),
    );
    try {
      final saved = await _repository.save(
        ReferenceItemEdit(
          id: id,
          title: normalizedTitle,
          description: normalizedDescription,
        ),
      );
      onSaved(saved);
      _setState(
        ReferenceEditState(
          phase: ReferenceEditPhase.ready,
          item: saved,
          submissionPhase: ReferenceSubmissionPhase.success,
        ),
      );
      return saved;
    } on Object catch (error) {
      _setState(
        ReferenceEditState(
          phase: ReferenceEditPhase.ready,
          item: current.item,
          submissionPhase: ReferenceSubmissionPhase.failure,
          submissionFailure: error,
        ),
      );
      return null;
    }
  }

  void _setState(ReferenceEditState nextState) {
    if (_disposed) {
      return;
    }
    _state = nextState;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
