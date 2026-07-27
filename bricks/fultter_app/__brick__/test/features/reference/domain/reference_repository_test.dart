import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/src/features/reference/domain/reference_repository.dart';

void main() {
  test('page request validates pagination boundaries', () {
    expect(
      () => ReferencePageRequest(offset: -1, limit: 1),
      throwsArgumentError,
    );
    expect(
      () => ReferencePageRequest(offset: 0, limit: 0),
      throwsArgumentError,
    );
    expect(
      () => ReferencePageRequest(offset: 0, limit: -1),
      throwsArgumentError,
    );
  });
}
