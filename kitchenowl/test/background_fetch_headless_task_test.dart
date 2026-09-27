import 'package:flutter_test/flutter_test.dart';
import 'package:kitchenowl/main.dart';

void main() {
  test('headless work completes before resources are released', () async {
    final events = <String>[];

    await handleBackgroundFetchHeadlessTask(
      'test-task',
      isTimeout: false,
      runTask: () async {
        events.add('started');
        await Future<void>.delayed(Duration.zero);
        events.add('completed');
      },
      dispose: () => events.add('disposed'),
      finish: (_) => events.add('finished'),
    );

    expect(events, ['started', 'completed', 'disposed', 'finished']);
  });

  test('headless task is finished when background work fails', () async {
    final events = <String>[];

    await expectLater(
      handleBackgroundFetchHeadlessTask(
        'test-task',
        isTimeout: false,
        runTask: () async {
          events.add('started');
          throw StateError('sync failed');
        },
        dispose: () => events.add('disposed'),
        finish: (_) => events.add('finished'),
      ),
      throwsStateError,
    );

    expect(events, ['started', 'disposed', 'finished']);
  });

  test('timed-out headless task finishes without starting new work', () async {
    final events = <String>[];

    await handleBackgroundFetchHeadlessTask(
      'test-task',
      isTimeout: true,
      runTask: () async => events.add('started'),
      dispose: () => events.add('disposed'),
      finish: (_) => events.add('finished'),
    );

    expect(events, ['finished']);
  });
}
