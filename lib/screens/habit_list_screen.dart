import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';
import '../widgets/habit_card.dart';
import 'add_habit_screen.dart';
import 'habit_detail_screen.dart';
import 'progress_screen.dart';

class HabitListScreen extends StatefulWidget {
  const HabitListScreen({super.key});

  @override
  State<HabitListScreen> createState() => _HabitListScreenState();
}

class _HabitListScreenState extends State<HabitListScreen> {
  final _service = HabitService();
  int _selectedIndex = 0;

  Future<void> _confirmDelete(Habit habit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete habit?'),
        content: Text('This will permanently delete "${habit.name}" '
            'and all its completion history.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: Theme.of(ctx).colorScheme.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _service.deleteHabit(habit.id);
      setState(() {});
    }
  }

  Widget _buildHabitList(List<Habit> habits) {
    if (habits.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('🌱', style: const TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'No habits yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first habit',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 100),
      itemCount: habits.length,
      itemBuilder: (context, index) {
        final habit = habits[index];
        // Stagger: each card animates in 80ms after the previous one.
        // animate_do handles the AnimationController lifecycle internally,
        // which is why we pass delay as a Duration here rather than
        // managing controllers ourselves.
        return FadeInLeft(
          key: ValueKey(habit.id),
          delay: Duration(milliseconds: index * 80),
          duration: const Duration(milliseconds: 400),
          child: HabitCard(
            habit: habit,
            animationIndex: index,
            onDelete: () => _confirmDelete(habit),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => HabitDetailScreen(habit: habit),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ValueListenableBuilder rebuilds whenever any Hive box changes.
    // This is Hive's reactive pattern — it's a Listenable backed by
    // the box's internal change notifier.
    return ValueListenableBuilder(
      valueListenable: Hive.box<Habit>('habits').listenable(),
      builder: (context, Box<Habit> box, _) {
        final habits = _service.getAllHabits();
        final completedCount = habits
            .where((h) => _service.isCompletedToday(h.id))
            .length;

        return Scaffold(
          appBar: AppBar(
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('My Habits'),
                Text(
                  '$completedCount / ${habits.length} completed today',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.outline,
                      ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.bar_chart_rounded),
                tooltip: 'Progress',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProgressScreen()),
                ),
              ),
            ],
          ),
          body: _buildHabitList(habits),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddHabitScreen()),
              );
              setState(() {});
            },
            icon: const Icon(Icons.add),
            label: const Text('New habit'),
          ),
        );
      },
    );
  }
}
