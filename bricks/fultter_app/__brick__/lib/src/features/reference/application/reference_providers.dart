import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/fake_reference_repository.dart';
import '../domain/reference_repository.dart';

final referenceRepositoryProvider = Provider<ReferenceRepository>((ref) {
  return FakeReferenceRepository();
});
