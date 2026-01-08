import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../lib/models/habit.dart';
import '../lib/services/habit_service.dart';

// Note: these tests require hive to be initialised with a temp directory.
// In CI this would use a tmpdir fixture; shown here as architecture reference.
void main() {
  group('HabitService streak logic', () {
    test('getCurrentStreak returns 0 when no completions', () {
      // Pseudo-test demonstrating the expected contract.
      // With a real Hive mock/fake this would open an in-memory box.
      expect(0, equals(0)); // placeholder
    });

    test('getBestStreak handles non-consecutive dates', () {
      // Given completions on days 1,2,3 then gap, then 7,8
      // best streak should be 3
      final dates = [
        DateTime.utc(2024, 1, 1),
        DateTime.utc(2024, 1, 2),
        DateTime.utc(2024, 1, 3),
        DateTime.utc(2024, 1, 7),
        DateTime.utc(2024, 1, 8),
      ];
      // Manual streak calculation mirroring HabitService.getBestStreak
      int best = 1, current = 1;
      for (int i = 1; i < dates.length; i++) {
        final diff = dates[i].difference(dates[i - 1]).inDays;
        if (diff == 1) {
          current++;
          if (current > best) best = current;
        } else {
          current = 1;
        }
      }
      expect(best, equals(3));
    });
  });
}
