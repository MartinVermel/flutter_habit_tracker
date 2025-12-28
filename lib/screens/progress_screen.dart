import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';

class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _service = HabitService();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── Bar chart data ────────────────────────────────────────────────────────

  /// Builds BarChartGroupData for a single habit over the past 7 days.
  /// Each bar's x value is 0..6 (Mon..Sun this week).
  /// fl_chart requires all series to share the same x positions, so we
  /// build one BarChartRodData per habit at each x, grouped in a single
  /// BarChartGroupData per day.
  List<BarChartGroupData> _buildWeeklyBarGroups(List<Habit> habits) {
    final result = <BarChartGroupData>[];

    for (int dayIndex = 0; dayIndex < 7; dayIndex++) {
      final rods = <BarChartRodData>[];

      for (final habit in habits.take(4)) {
        // Show max 4 habits to keep bars readable
        final weekData =
            _service.getWeeklyCompletions(habit.id, days: 7);
        final entries = weekData.entries.toList();
        final value = entries.length > dayIndex
            ? weekData.values.toList()[dayIndex].toDouble()
            : 0.0;

        rods.add(BarChartRodData(
          toY: value,
          color: Color(habit.colorValue),
          width: 10,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
        ));
      }

      result.add(BarChartGroupData(x: dayIndex, barRods: rods));
    }
    return result;
  }

  // ── Line chart data ───────────────────────────────────────────────────────

  /// 30-day cumulative completion rate — produces a smooth trend line.
  List<FlSpot> _buildStreakLine(Habit habit) {
    final spots = <FlSpot>[];
    final today = DateTime.now();
    int runningTotal = 0;

    for (int i = 29; i >= 0; i--) {
      final day = DateTime(today.year, today.month, today.day)
          .subtract(Duration(days: i));
      if (_service.isCompletedOn(habit.id, day)) runningTotal++;
      spots.add(FlSpot((29 - i).toDouble(), runningTotal.toDouble()));
    }
    return spots;
  }

  Widget _buildWeeklyChart(List<Habit> habits) {
    if (habits.isEmpty) {
      return const Center(child: Text('Add habits to see your chart'));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This week',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Daily completions per habit',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline)),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                barGroups: _buildWeeklyBarGroups(habits),
                borderData: FlBorderData(show: false),
                gridData: const FlGridData(
                  show: true,
                  drawVerticalLine: false,
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Text(days[value.toInt()],
                            style: const TextStyle(fontSize: 12));
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      if (rodIndex >= habits.length) return null;
                      return BarTooltipItem(
                        habits[rodIndex].name,
                        TextStyle(
                          color: Color(habits[rodIndex].colorValue),
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: habits.take(4).map((h) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Color(h.colorValue),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text('${h.emoji} ${h.name}',
                      style: Theme.of(context).textTheme.bodySmall),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildTrendChart(List<Habit> habits) {
    if (habits.isEmpty) {
      return const Center(child: Text('Add habits to see trends'));
    }

    // Build one LinChartBarData per habit
    final lineBars = habits.take(4).map((habit) {
      return LineChartBarData(
        spots: _buildStreakLine(habit),
        isCurved: true,
        color: Color(habit.colorValue),
        barWidth: 2.5,
        dotData: const FlDotData(show: false),
        belowBarData: BarAreaData(
          show: true,
          color: Color(habit.colorValue).withOpacity(0.08),
        ),
      );
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('30-day trend',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text('Cumulative completions',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: Theme.of(context).colorScheme.outline)),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: LineChart(
              LineChartData(
                lineBarsData: lineBars,
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: Theme.of(context).dividerColor,
                    strokeWidth: 0.8,
                  ),
                ),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 7,
                      getTitlesWidget: (value, meta) {
                        final day = DateTime.now()
                            .subtract(Duration(days: 29 - value.toInt()));
                        return Text(DateFormat('MMd').format(day),
                            style: const TextStyle(fontSize: 10));
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 28,
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Summary cards
          ...habits.map((h) {
            final rate = _service.getCompletionRate(h.id);
            final streak = _service.getCurrentStreak(h.id);
            final habitColor = Color(h.colorValue);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: habitColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Text(h.emoji, style: const TextStyle(fontSize: 24)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(h.name,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(rate * 100).toStringAsFixed(0)}%',
                        style: TextStyle(
                          color: habitColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('$streak day streak',
                          style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final habits = _service.getAllHabits();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Progress'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart), text: 'Weekly'),
            Tab(icon: Icon(Icons.show_chart), text: 'Trend'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(child: _buildWeeklyChart(habits)),
          SingleChildScrollView(child: _buildTrendChart(habits)),
        ],
      ),
    );
  }
}
