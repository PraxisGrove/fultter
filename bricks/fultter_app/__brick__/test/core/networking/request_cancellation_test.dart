import 'package:flutter_test/flutter_test.dart';
import 'package:{{app_name}}/src/core/networking/request_cancellation.dart';

void main() {
  test('notifies listeners once and retains the cancellation reason', () {
    final controller = RequestCancellationController();
    final reasons = <String?>[];
    controller.token.addListener(reasons.add);

    controller.cancel('screen disposed');
    controller.cancel('ignored');

    expect(controller.token.isCancelled, isTrue);
    expect(controller.token.reason, 'screen disposed');
    expect(reasons, ['screen disposed']);
  });

  test('immediately notifies listeners added after cancellation', () {
    final controller = RequestCancellationController();
    controller.cancel('already done');
    String? reason;

    controller.token.addListener((value) => reason = value);

    expect(reason, 'already done');
  });
}
