import 'package:flutter_test/flutter_test.dart';
import 'package:app/models/activity.dart';

void main() {
  test('Benchmark lastWhere performance', () {
    final activities = List.generate(
      1000,
      (i) => Activity(
        id: '$i',
        type: i == 999 ? ActivityType.planning : ActivityType.execution,
        description: 'Activity $i',
        timestamp: DateTime.now(),
        metadata: {},
      ),
    );

    // Baseline: current implementation
    final stopwatch = Stopwatch()..start();
    for (int i = 0; i < 100; i++) {
      activities.lastWhere(
        (a) => a.type == ActivityType.planning,
        orElse: () => Activity(
          id: '',
          type: ActivityType.planning,
          description: 'No plan generated yet.',
          timestamp: DateTime.now(),
          metadata: {},
        ),
      );
    }
    stopwatch.stop();
    print('Baseline (O(N) search) took: ${stopwatch.elapsedMicroseconds} microseconds for 100 iterations');

    // Memoized version (simulated)
    Activity? memoizedPlan;
    List<Activity>? lastActivities;

    Activity getLatestPlan(List<Activity> currentActivities) {
      if (lastActivities == currentActivities && memoizedPlan != null) {
        return memoizedPlan!;
      }
      lastActivities = currentActivities;
      memoizedPlan = currentActivities.lastWhere(
        (a) => a.type == ActivityType.planning,
        orElse: () => Activity(
          id: '',
          type: ActivityType.planning,
          description: 'No plan generated yet.',
          timestamp: DateTime.now(),
          metadata: {},
        ),
      );
      return memoizedPlan!;
    }

    final stopwatch2 = Stopwatch()..start();
    for (int i = 0; i < 100; i++) {
      getLatestPlan(activities);
    }
    stopwatch2.stop();
    print('Optimized (Memoized) took: ${stopwatch2.elapsedMicroseconds} microseconds for 100 iterations');
  });
}
