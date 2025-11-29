import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/habit.dart';

/// Names for Hive boxes — centralised here to avoid typos across the codebase.
const String kHabitBoxName = 'habits';
const String kCompletionBoxName = 'completions';

class HabitService {
  static final HabitService _instance = HabitService._internal();
  factory HabitService() => _instance;
  HabitService._internal();

  final _uuid = const Uuid();

  Box<Habit> get _habitBox => Hive.box<Habit>(kHabitBoxName);
  Box<HabitCompletion> get _completionBox =>
      Hive.box<HabitCompletion>(kCompletionBoxName);

  // ── Initialisation ────────────────────────────────────────────────────────

  static Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(FrequencyAdapter());
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(HabitCompletionAdapter());
    await Hive.openBox<Habit>(kHabitBoxName);
    await Hive.openBox<HabitCompletion>(kCompletionBoxName);
  }

  // ── CRUD ──────────────────────────────────────────────────────────────────

  List<Habit> getAllHabits() =>
      _habitBox.values.where((h) => !h.isArchived).toList()
        ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

  Future<Habit> createHabit({
    required String name,
    required String emoji,
    required int colorValue,
    required Frequency frequency,
  }) async {
    final habit = Habit(
      id: _uuid.v4(),
      name: name,
      emoji: emoji,
      colorValue: colorValue,
      frequency: frequency,
      createdAt: DateTime.now(),
    );
    await _habitBox.put(habit.id, habit);
    return habit;
  }

  Future<void> updateHabit(Habit habit) async {
    await habit.save();
  }

  Future<void> deleteHabit(String habitId) async {
    await _habitBox.delete(habitId);
    // Cascade-delete completions for this habit
    final toDelete = _completionBox.values
        .where((c) => c.habitId == habitId)
        .map((c) => c.key)
        .toList();
    await _completionBox.deleteAll(toDelete);
  }

  // ── Completions ───────────────────────────────────────────────────────────

  /// Returns today's midnight UTC, used as the canonical key for a day.
  DateTime _todayNormalized() {
    final now = DateTime.now();
    return DateTime.utc(now.year, now.month, now.day);
  }

  DateTime _normalizeDate(DateTime date) =>
      DateTime.utc(date.year, date.month, date.day);

  bool isCompletedOn(String habitId, DateTime date) {
    final normalized = _normalizeDate(date);
    return _completionBox.values.any(
      (c) => c.habitId == habitId && c.date == normalized,
    );
  }

  bool isCompletedToday(String habitId) =>
      isCompletedOn(habitId, _todayNormalized());

  Future<void> toggleCompletion(String habitId) async {
    final today = _todayNormalized();
    final existing = _completionBox.values.firstWhere(
      (c) => c.habitId == habitId && c.date == today,
      orElse: () => HabitCompletion(
        habitId: '',
        date: DateTime(0),
        completedAt: DateTime(0),
      ),
    );

    if (existing.habitId.isNotEmpty) {
      await existing.delete();
    } else {
      final completion = HabitCompletion(
        habitId: habitId,
        date: today,
        completedAt: DateTime.now(),
      );
      await _completionBox.put('${habitId}_${today.millisecondsSinceEpoch}',
          completion);
    }
  }

  List<HabitCompletion> getCompletionsForHabit(String habitId) =>
      _completionBox.values
          .where((c) => c.habitId == habitId)
          .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  // ── Streak calculation ────────────────────────────────────────────────────

  /// Walks backwards from today counting consecutive completed days.
  /// This is O(streak_length) rather than O(all_completions).
  int getCurrentStreak(String habitId) {
    final completedDates = _completionBox.values
        .where((c) => c.habitId == habitId)
        .map((c) => c.date)
        .toSet();

    int streak = 0;
    var day = _todayNormalized();

    while (completedDates.contains(day)) {
      streak++;
      day = day.subtract(const Duration(days: 1));
    }
    return streak;
  }

  int getBestStreak(String habitId) {
    final sorted = _completionBox.values
        .where((c) => c.habitId == habitId)
        .map((c) => c.date)
        .toList()
      ..sort();

    if (sorted.isEmpty) return 0;

    int best = 1;
    int current = 1;

    for (int i = 1; i < sorted.length; i++) {
      final diff = sorted[i].difference(sorted[i - 1]).inDays;
      if (diff == 1) {
        current++;
        if (current > best) best = current;
      } else if (diff > 1) {
        current = 1;
      }
    }
    return best;
  }

  /// Returns completion count per day for the past [days] days.
  /// Used to feed fl_chart data series.
  Map<DateTime, int> getWeeklyCompletions(String habitId, {int days = 7}) {
    final result = <DateTime, int>{};
    final today = _todayNormalized();

    for (int i = days - 1; i >= 0; i--) {
      final day = today.subtract(Duration(days: i));
      result[day] = isCompletedOn(habitId, day) ? 1 : 0;
    }
    return result;
  }

  double getCompletionRate(String habitId, {int days = 30}) {
    final today = _todayNormalized();
    int completed = 0;

    for (int i = 0; i < days; i++) {
      final day = today.subtract(Duration(days: i));
      if (isCompletedOn(habitId, day)) completed++;
    }
    return completed / days;
  }
}
