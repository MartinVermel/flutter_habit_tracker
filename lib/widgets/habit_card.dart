import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';

class HabitCard extends StatefulWidget {
  final Habit habit;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final int animationIndex;

  const HabitCard({
    super.key,
    required this.habit,
    required this.onDelete,
    required this.onTap,
    this.animationIndex = 0,
  });

  @override
  State<HabitCard> createState() => _HabitCardState();
}

class _HabitCardState extends State<HabitCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _checkController;
  late final Animation<double> _scaleAnim;
  final _service = HabitService();

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _checkController, curve: Curves.elasticOut),
    );
  }

  @override
  void dispose() {
    _checkController.dispose();
    super.dispose();
  }

  Future<void> _handleToggle() async {
    await _service.toggleCompletion(widget.habit.id);
    _checkController.forward().then((_) => _checkController.reverse());
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final habitColor = Color(widget.habit.colorValue);
    final isCompleted = _service.isCompletedToday(widget.habit.id);
    final streak = _service.getCurrentStreak(widget.habit.id);
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Slidable(
        key: ValueKey(widget.habit.id),
        // Swipe right → complete/uncomplete
        startActionPane: ActionPane(
          motion: const BehindMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) => _handleToggle(),
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              icon: isCompleted ? Icons.close : Icons.check,
              label: isCompleted ? 'Undo' : 'Done',
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(16),
              ),
            ),
          ],
        ),
        // Swipe left → delete
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) => widget.onDelete(),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline,
              label: 'Delete',
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(16),
              ),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: isCompleted
                  ? habitColor.withOpacity(0.15)
                  : theme.cardColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isCompleted ? habitColor : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Color dot + emoji
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: habitColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      widget.habit.emoji,
                      style: const TextStyle(fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.habit.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          decoration: isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                          color: isCompleted
                              ? theme.textTheme.titleMedium?.color
                                  ?.withOpacity(0.5)
                              : null,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.local_fire_department,
                              size: 14, color: habitColor),
                          const SizedBox(width: 4),
                          Text(
                            '$streak day streak',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: habitColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(Icons.repeat,
                              size: 14, color: theme.colorScheme.outline),
                          const SizedBox(width: 4),
                          Text(
                            widget.habit.frequency == Frequency.daily
                                ? 'Daily'
                                : 'Weekly',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                ScaleTransition(
                  scale: _scaleAnim,
                  child: GestureDetector(
                    onTap: _handleToggle,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted ? habitColor : Colors.transparent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isCompleted
                              ? habitColor
                              : theme.colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child: isCompleted
                          ? const Icon(Icons.check,
                              size: 18, color: Colors.white)
                          : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
