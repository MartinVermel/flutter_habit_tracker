import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'services/habit_service.dart';
import 'screens/habit_list_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Boot Hive and register all TypeAdapters before the widget tree mounts.
  // HabitService.init() is a static helper that centralises the setup so
  // main() stays clean — a pattern worth noting in code review.
  await HabitService.init();

  runApp(const HabitTrackerApp());
}

class HabitTrackerApp extends StatelessWidget {
  const HabitTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Habit Tracker',
      debugShowCheckedModeBanner: false,
      // Material 3 with a custom seed color
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6750A4),
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: const Color(0xFF6750A4),
        brightness: Brightness.dark,
      ),
      home: const HabitListScreen(),
    );
  }
}
