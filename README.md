<div align="center">

<img src="https://raw.githubusercontent.com/devicons/devicon/master/icons/flutter/flutter-original.svg" alt="Flutter" width="80" />

# Flutter Habit Tracker

**Offline-first habit tracking — no backend required**

[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Storage](https://img.shields.io/badge/Storage-Hive-FF7043)](https://pub.dev/packages/hive)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore-FFCA28?logo=firebase&logoColor=black)](https://firebase.google.com)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

Track daily habits, visualize streaks, and explore 30-day progress charts — stored locally with Hive and optionally synced across devices via Firebase Auth + Firestore.

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

- ☁️ **Firebase Auth** — email/password sign-in, anonymous mode, anonymous → permanent account upgrade
- 🔄 **Firestore sync** — write-through sync after every mutation; full download on new device sign-in
- 📡 **Sync status badge** — live AppBar chip showing "Synced / Syncing… / Local only"
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
| `firebase_core` | ^3.6.0 | Firebase SDK initialization |
| `firebase_auth` | ^5.3.1 | Email/password auth + anonymous sign-in |
| `cloud_firestore` | ^5.4.4 | Real-time NoSQL sync across devices |

---

## Getting Started

### Prerequisites

- Flutter SDK `>=3.0.0`
- A Firebase project (free Spark plan is enough)

### 1 — Clone and install

```bash
git clone https://github.com/MartinVermel/flutter_habit_tracker.git
cd flutter_habit_tracker
flutter pub get
```

### 2 — Connect Firebase

```bash
# Install the FlutterFire CLI (once)
dart pub global activate flutterfire_cli

# Generate firebase_options.dart for your project + target platforms
flutterfire configure
```

This overwrites `lib/firebase_options.dart` with real values for your project. Commit it — it contains no secrets.

### 3 — Enable Auth and Firestore in the Firebase Console

- **Authentication** → Sign-in method → enable **Email/Password** and **Anonymous**
- **Firestore Database** → Create database → start in **test mode** (tighten rules before shipping)

Recommended Firestore security rules:

```js
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{uid}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == uid;
    }
  }
}
```

### 4 — Run

```bash
flutter run
```

---

## Docker

The app ships as a Flutter **web** build served by nginx, using a multi-stage `Dockerfile` (Flutter SDK build stage, then a ~100 MB nginx:alpine runtime image).

```bash
docker compose up --build
```
Open http://localhost:8080.

Or without Compose:

```bash
docker build -t flutter_habit_tracker .
docker run -p 8080:80 flutter_habit_tracker
```

No secrets are needed at build time. Firebase values come from `lib/firebase_options.dart`.

| File | Purpose |
|---|---|
| `Dockerfile` | Stage 1 builds `flutter build web --release`, stage 2 copies the output into nginx |
| `nginx.conf` | SPA fallback to `index.html`, gzip, long-lived cache for assets, no-cache for the bootstrap files |
| `docker-compose.yml` | One-command run on port 8080 |
| `.dockerignore` | Keeps `.git`, `build/` and `.dart_tool/` out of the build context |

Docker serves the web target only. For Android/iOS builds use `flutter run` as above.

---

## Key Implementation Notes

### `StreamBuilder<User?>` as the root navigator
```dart
home: StreamBuilder<User?>(
  stream: AuthService().userStream,  // FirebaseAuth.authStateChanges()
  builder: (context, snapshot) {
    if (snapshot.data == null) return const AuthScreen();
    return const HabitListScreen();
  },
),
```
`authStateChanges()` emits whenever the auth state changes — sign-in, sign-out, token refresh. By making it the `home` of `MaterialApp`, the app reacts to auth state automatically with no manual `Navigator.pushReplacement`. When the user signs out, the widget tree swaps to `AuthScreen` without any explicit navigation code in the sign-out handler.

### Anonymous → permanent account upgrade
```dart
Future<UserCredential> linkWithEmail(String email, String password) {
  final credential =
      EmailAuthProvider.credential(email: email, password: password);
  return FirebaseAuth.instance.currentUser!.linkWithCredential(credential);
}
```
`linkWithCredential` converts an anonymous account into a permanent one while preserving the uid — which means all Firestore documents at `users/{uid}/...` are automatically inherited. No data migration needed. The user keeps their habits whether or not they had an account when they started.

### Write-through sync — `unawaited` for UI speed
```dart
Future<void> createHabit({...}) async {
  await _habitBox.put(habit.id, habit);  // local write completes first
  unawaited(_sync.upsertHabit(habit));   // Firestore write is fire-and-forget
  return habit;
}
```
Hive is the source of truth; Firestore is the backup. The UI never waits on the network. `unawaited()` (from `dart:async`) explicitly marks the Future as intentionally not awaited — this suppresses the linter warning and signals to reviewers that the fire-and-forget is deliberate, not an oversight.

### Atomic batch delete — habit + all its completions
```dart
Future<void> deleteHabit(String habitId) async {
  final batch = _db.batch();
  batch.delete(_habitsRef.doc(habitId));
  final completions = await _completionsRef
      .where('habitId', isEqualTo: habitId).get();
  for (final doc in completions.docs) {
    batch.delete(doc.reference);
  }
  await batch.commit(); // atomic — either all delete or nothing does
}
```
A Firestore `WriteBatch` applies all deletes in a single atomic operation. If the network drops mid-delete, Firestore either applies all of them or none — the habit and its completions are never left in an inconsistent state. Batches are also more efficient than individual deletes: one round trip instead of N.

---

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
