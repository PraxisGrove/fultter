import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fake_reference_repository.dart';
import '../domain/reference_repository.dart';
import 'reference_detail_controller.dart';
import 'reference_edit_controller.dart';
import 'reference_list_controller.dart';

final referenceRepositoryProvider = Provider<ReferenceRepository>((ref) {
  return FakeReferenceRepository();
});

final referenceListControllerProvider = Provider<ReferenceListController>((
  ref,
) {
  final controller = ReferenceListController(
    ref.watch(referenceRepositoryProvider),
  );
  ref.onDispose(controller.dispose);
  return controller;
});

final referenceDetailControllerProvider =
    Provider.family<ReferenceDetailController, String>((ref, id) {
      final controller = ReferenceDetailController(
        ref.watch(referenceRepositoryProvider),
        id,
      );
      ref.onDispose(controller.dispose);
      return controller;
    });

final referenceEditControllerProvider =
    Provider.family<ReferenceEditController, String>((ref, id) {
      final controller = ReferenceEditController(
        ref.watch(referenceRepositoryProvider),
        id,
        onSaved: (item) {
          ref.read(referenceListControllerProvider).replace(item);
          ref.read(referenceDetailControllerProvider(id)).replace(item);
        },
      );
      ref.onDispose(controller.dispose);
      return controller;
    });
