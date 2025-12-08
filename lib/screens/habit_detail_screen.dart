import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';

class HabitDetailScreen extends StatelessWidget {
  final Habit habit;

  const HabitDetailScreen({super.key, required this.habit});

  @override
  Widget build(BuildContext context) {
    final service = HabitService();
    final habitColor = Color(habit.colorValue);
    final streak = service.getCurrentStreak(habit.id);
    final best = service.getBestStreak(habit.id);
    final rate = service.getCompletionRate(habit.id);
    final completions = service.getCompletionsForHabit(habit.id);
    final completedDates = completions.map((c) => c.date).toSet();

    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    // Calendar grid: pad to nearest Monday before the 1st
    final startPadding = (firstDay.weekday - 1) % 7;

    return Scaffold(
      appBar: AppBar(
        title: Text('${habit.emoji} ${habit.name}'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Stats row
            Row(
              children: [
                _StatCard(
                  label: 'Current streak',
                  value: '$streak',
                  unit: 'days',
                  color: habitColor,
                  icon: Icons.local_fire_department,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  label: 'Best streak',
                  value: '$best',
                  unit: 'days',
                  color: Colors.orange,
                  icon: Icons.emoji_events,
                ),
                const SizedBox(width: 10),
                _StatCard(
                  label: '30-day rate',
                  value: '${(rate * 100).toStringAsFixed(0)}%',
                  unit: '',
                  color: Colors.green,
                  icon: Icons.check_circle_outline,
                ),
              ],
            ),
            const SizedBox(height: 24),

            Text('This month',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            // Calendar grid — custom widget to show which days are done
            _CalendarGrid(
              year: now.year,
              month: now.month,
              completedDates: completedDates,
              habitColor: habitColor,
            ),

            const SizedBox(height: 24),
            Text('Recent activity',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),

            if (completions.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Text('No completions yet'),
                ),
              )
            else
              ...completions.reversed.take(10).map(
                    (c) => ListTile(
                      leading: CircleAvatar(
                        backgroundColor: habitColor.withOpacity(0.2),
                        child: Icon(Icons.check, color: habitColor, size: 18),
                      ),
                      title: Text(DateFormat('EEEE, MMM d').format(c.date)),
                      subtitle: Text(
                          'Logged at ${DateFormat.jm().format(c.completedAt)}'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            if (unit.isNotEmpty) Text(unit, style: const TextStyle(fontSize: 11)),
            Text(label,
                style: Theme.of(context).textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

class _CalendarGrid extends StatelessWidget {
  final int year;
  final int month;
  final Set<DateTime> completedDates;
  final Color habitColor;

  const _CalendarGrid({
    required this.year,
    required this.month,
    required this.completedDates,
    required this.habitColor,
  });

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    // Monday = 1; shift so grid aligns with Mon header
    final startOffset = (firstDay.weekday - 1) % 7;
    final today = DateTime.now();

    return Column(
      children: [
        // Day headers
        Row(
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map((d) => Expanded(
                    child: Center(
                      child: Text(d,
                          style: Theme.of(context).textTheme.labelSmall),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 4,
            crossAxisSpacing: 4,
          ),
          itemCount: startOffset + daysInMonth,
          itemBuilder: (context, index) {
            if (index < startOffset) return const SizedBox.shrink();
            final day = index - startOffset + 1;
            final date = DateTime.utc(year, month, day);
            final isCompleted = completedDates.contains(date);
            final isToday = today.year == year &&
                today.month == month &&
                today.day == day;

            return AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                color: isCompleted
                    ? habitColor
                    : isToday
                        ? habitColor.withOpacity(0.15)
                        : Colors.transparent,
                shape: BoxShape.circle,
                border: isToday && !isCompleted
                    ? Border.all(color: habitColor, width: 1.5)
                    : null,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isToday ? FontWeight.bold : FontWeight.normal,
                    color: isCompleted ? Colors.white : null,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
