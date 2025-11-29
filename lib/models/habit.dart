import 'package:hive/hive.dart';

part 'habit.g.dart';

/// Hive type IDs — keep these stable across app versions.
/// Changing them would invalidate all stored data.
const int kHabitTypeId = 0;
const int kHabitCompletionTypeId = 1;
const int kFrequencyTypeId = 2;

@HiveType(typeId: kFrequencyTypeId)
enum Frequency {
  @HiveField(0)
  daily,

  @HiveField(1)
  weekly,
}

@HiveType(typeId: kHabitTypeId)
class Habit extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String emoji;

  /// Stored as ARGB int to survive serialization.
  /// Reconstruct with Color(colorValue).
  @HiveField(3)
  int colorValue;

  @HiveField(4)
  Frequency frequency;

  @HiveField(5)
  DateTime createdAt;

  @HiveField(6)
  bool isArchived;

  Habit({
    required this.id,
    required this.name,
    required this.emoji,
    required this.colorValue,
    required this.frequency,
    required this.createdAt,
    this.isArchived = false,
  });
}

@HiveType(typeId: kHabitCompletionTypeId)
class HabitCompletion extends HiveObject {
  @HiveField(0)
  String habitId;

  /// Normalized to midnight UTC so date equality is straightforward.
  @HiveField(1)
  DateTime date;

  @HiveField(2)
  DateTime completedAt;

  HabitCompletion({
    required this.habitId,
    required this.date,
    required this.completedAt,
  });
}
