<div align="center">

<img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/flutter/flutter-original.svg" alt="Flutter" width="80" />

# Flutter Habit Tracker

**Offline-first habit tracking — no backend required**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Storage](https://img.shields.io/badge/Storage-Hive-FF7043)](https://pub.dev/packages/hive)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Track daily habits, visualize streaks, and explore 30-day progress charts — all stored locally on device using Hive. No account, no server, no network.

</div>

---

## Screenshots

<div align="center">

| Habit List | Add Habit | Weekly Progress | Habit Detail |
|:---:|:---:|:---:|:---:|
| <img src="docs/screenshots/habit_list.png" width="180" alt="Habit List" /> | <img src="docs/screenshots/add_habit.png" width="180" alt="Add Habit" /> | <img src="docs/screenshots/progress.png" width="180" alt="Progress Charts" /> | <img src="docs/screenshots/detail.png" width="180" alt="Habit Detail" /> |

> **Note:** Screenshots coming soon — run the app locally to see it in action (`flutter run`, no API key needed).

</div>

---

## Features

- ✅ **Swipe actions** — swipe right to complete, swipe left to delete via `flutter_slidable`
- 🎨 **Custom habit identity** — pick an emoji and a colour from a full HSV wheel
- 📊 **Progress charts** — weekly grouped bar chart and 30-day cumulative line chart (`fl_chart`)
- 🗓 **Calendar grid** — custom widget showing completed days at a glance
- 🔥 **Streak tracking** — current streak and all-time best streak, calculated in O(streak) time
- 💾 **100% offline** — Hive binary storage with hand-written `TypeAdapter`, no codegen needed
- ✨ **Staggered animations** — `animate_do` `FadeInLeft` entries with index-based delay

---

## Architecture

```
lib/
├── main.dart                      # App entry — Hive.initFlutter() + adapter registration
├── models/
│   ├── habit.dart                 # @HiveType(typeId: 0) — Habit
│   ├── habit_completion.dart      # @HiveType(typeId: 1) — HabitCompletion
│   └── habit.g.dart               # Hand-written TypeAdapters (no build_runner)
├── services/
│   └── habit_service.dart         # Singleton — CRUD, streak logic, weekly stats
├── screens/
│   ├── habit_list_screen.dart     # ValueListenableBuilder + Slidable list
│   ├── add_habit_screen.dart      # Form with EmojiGrid + BlockPicker
│   ├── progress_screen.dart       # fl_chart BarChart + LineChart
│   └── habit_detail_screen.dart   # Calendar grid + recent completions
└── widgets/
    ├── habit_card.dart            # Colour-coded card with streak badge
    ├── calendar_grid.dart         # Custom month-view completion grid
    └── stat_chip.dart             # Current streak / best streak pill
```

**Data flow:**
```
HiveBox<Habit>  +  HiveBox<HabitCompletion>
        ↓
  HabitService  (CRUD, streak, weekly stats)
        ↓
  ValueListenableBuilder  →  UI rebuilds on box changes
```

---

## Tech Stack

| Package | Version | Role |
|---|---|---|
| `hive_flutter` | ^1.1.0 | Local binary NoSQL storage |
| `fl_chart` | ^0.68.0 | Bar chart + line chart visualizations |
| `flutter_slidable` | ^3.1.0 | Swipe-to-action on list tiles |
| `animate_do` | ^3.3.4 | Staggered fade-in list animations |
| `flutter_colorpicker` | ^1.1.0 | Full HSV color wheel widget |
| `uuid` | ^4.4.0 | RFC 4122 IDs for Habit entities |
| `intl` | ^0.19.0 | Date formatting for chart axis labels |

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- No external API keys needed — fully offline

### Installation

```bash
git clone https://github.com/MartinVermel/flutter_habit_tracker.git
cd flutter_habit_tracker
flutter pub get
flutter run
```

That's it. No `.env` file, no account, no configuration.

---

## Key Implementation Notes

### Hive `typeId` immutability
```dart
@HiveType(typeId: 0)   // ← NEVER change once shipped
class Habit extends HiveObject {
  @HiveField(0) String id;
  @HiveField(3) int colorValue;  // Color stored as ARGB int
}
```
Hive uses `typeId` as a binary schema identifier. Changing it — or reordering `@HiveField` indices — silently corrupts all existing stored data. Field indices must be treated as immutable after the first production release. `Color` cannot be annotated directly; it's stored as `int colorValue` and reconstructed with `Color(colorValue)`.

### Streak algorithm — O(streak) with O(1) lookup
```dart
int getCurrentStreak(String habitId) {
  final dates = _completionBox.values
    .where((c) => c.habitId == habitId)
    .map((c) => c.date)
    .toSet();                            // O(1) contains()

  var day = DateTime.utc(now.year, now.month, now.day); // normalized
  int streak = 0;
  while (dates.contains(day)) {
    streak++;
    day = day.subtract(const Duration(days: 1));
  }
  return streak;
}
```
Two non-obvious details: (1) converting to a `Set` before the loop makes each day check O(1) instead of O(n); (2) `DateTime.utc(year, month, day)` normalizes to midnight UTC — without this, two completions on the "same calendar day" may not compare equal because `DateTime` equality checks microseconds.

### fl_chart grouped bar chart — inverted mental model
`BarChartGroupData` represents one **x-position** (a day), not one series (a habit). Each group holds multiple `BarChartRodData` items, one per habit. The outer loop iterates days; the inner loop iterates habits — the reverse of the intuitive "one dataset per series" framing.

---

## Project Structure Decisions

- **Why Hive over SQLite?** For small, schema-simple datasets like habits, Hive's binary storage is faster and requires zero SQL. The `TypeAdapter` pattern keeps serialization explicit and testable.
- **Why hand-written `TypeAdapter` instead of `build_runner`?** Removes the codegen step entirely and makes the binary field mapping visible in code review — important for a project where field index stability is a correctness constraint.
- **Why `ValueListenableBuilder` instead of a state management library?** Hive boxes expose a `Listenable` natively. For a single-screen CRUD app the extra indirection of a notifier adds complexity without benefit.

---

## License

MIT © [Martin Vermel](https://github.com/MartinVermel)
