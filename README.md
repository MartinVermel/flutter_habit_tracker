# Flutter Habit Tracker

A daily habit tracking app built with Flutter, showcasing local persistence, custom animations, Material 3 design, and data visualisation.

## Features

- **Habit management** — Create habits with a custom emoji, colour, and daily/weekly frequency
- **Swipe actions** — `flutter_slidable` powers swipe-right to complete and swipe-left to delete
- **Animated list** — `animate_do` staggers `FadeInLeft` entries so the list feels alive
- **Progress charts** — `fl_chart` renders a grouped bar chart (weekly completions) and a 30-day cumulative line chart
- **Calendar grid** — Custom widget showing which days a habit was completed this month
- **Streak tracking** — Current streak and best streak calculated in `HabitService`
- **Local persistence** — All data stored offline with `hive_flutter`; no backend needed

## Architecture

```
lib/
├── main.dart                  # App entry, Hive bootstrap
├── models/
│   ├── habit.dart             # Hive @HiveType annotated models
│   └── habit.g.dart           # TypeAdapters (written by hand, no codegen)
├── services/
│   └── habit_service.dart     # Singleton CRUD + streak logic
├── screens/
│   ├── habit_list_screen.dart # Home — ValueListenableBuilder + Slidable
│   ├── add_habit_screen.dart  # Form with BlockPicker and emoji grid
│   ├── habit_detail_screen.dart # Calendar grid + recent completions
│   └── progress_screen.dart  # fl_chart BarChart + LineChart
└── widgets/
    └── habit_card.dart        # Animated completion toggle
```

## Libraries used

| Package | Version | Purpose |
|---|---|---|
| `hive_flutter` | ^1.1.0 | Local NoSQL storage |
| `fl_chart` | ^0.68.0 | Bar chart & line chart |
| `flutter_slidable` | ^3.1.0 | Swipeable list items |
| `animate_do` | ^3.3.4 | Entrance animations |
| `intl` | ^0.19.0 | Date formatting |
| `uuid` | ^4.4.0 | Stable habit IDs |
| `flutter_colorpicker` | ^1.1.0 | Colour swatch picker |

## Getting started

```bash
flutter pub get
flutter run
```

Requires Flutter 3.x and Dart 3.x.

## Key implementation notes

### Hive TypeAdapters without codegen
`habit.g.dart` is written by hand. This is intentional for portfolio purposes — it shows understanding of how Hive serialises objects at the byte level (`writeByte`, `readByte`, field-count header) rather than relying on the generator as a black box.

### Streak calculation
`HabitService.getCurrentStreak` walks backwards from today in O(streak_length) time using a `Set<DateTime>` lookup rather than sorting and scanning the full completion list. `getBestStreak` requires a sort pass, but it is called only on the detail screen.

### Reactive UI with `ValueListenableBuilder`
`HabitListScreen` wraps its content in a `ValueListenableBuilder` on the Hive box. Hive boxes implement `Listenable`, so any write (add/delete/toggle) automatically rebuilds the list without `setState` or a state management library.

### animate_do stagger pattern
Each `HabitCard` is wrapped in `FadeInLeft` with `delay: Duration(milliseconds: index * 80)`. `animate_do` creates and disposes its own `AnimationController` internally, which keeps `HabitListScreen` free of controller boilerplate while still delivering per-item stagger.

## Screenshots

_Coming soon_
