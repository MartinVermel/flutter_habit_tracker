import 'package:flutter/material.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import '../models/habit.dart';
import '../services/habit_service.dart';

// A curated set of emoji for quick selection — avoids building a full emoji
// keyboard while still giving the user a fun choice.
const _kEmojiOptions = [
  '🏃', '💪', '📚', '🧘', '💧', '🥗', '😴', '✍️',
  '🎸', '🌿', '🧹', '💊', '🚴', '🎯', '🌅', '🧠',
  '🫁', '🛁', '☀️', '🌙', '🍎', '🏋️', '📝', '🎨',
];

class AddHabitScreen extends StatefulWidget {
  const AddHabitScreen({super.key});

  @override
  State<AddHabitScreen> createState() => _AddHabitScreenState();
}

class _AddHabitScreenState extends State<AddHabitScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _service = HabitService();

  String _selectedEmoji = '🏃';
  Color _selectedColor = const Color(0xFF6750A4); // M3 seed purple
  Frequency _selectedFrequency = Frequency.daily;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickColor() async {
    Color pickedColor = _selectedColor;

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Pick a color'),
        content: SingleChildScrollView(
          // BlockPicker renders a grid of preset swatches —
          // simpler than the full hue/saturation wheel for this use case.
          child: BlockPicker(
            pickerColor: _selectedColor,
            onColorChanged: (c) => pickedColor = c,
            availableColors: const [
              Color(0xFF6750A4),
              Color(0xFF0288D1),
              Color(0xFF2E7D32),
              Color(0xFFE65100),
              Color(0xFFC62828),
              Color(0xFF4A148C),
              Color(0xFF00695C),
              Color(0xFF37474F),
              Color(0xFFF57F17),
              Color(0xFFAD1457),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              setState(() => _selectedColor = pickedColor);
              Navigator.pop(context);
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    await _service.createHabit(
      name: _nameController.text.trim(),
      emoji: _selectedEmoji,
      colorValue: _selectedColor.value,
      frequency: _selectedFrequency,
    );

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New habit'),
        actions: [
          FilledButton(
            onPressed: _isSaving ? null : _save,
            child: _isSaving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Preview card
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _selectedColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: _selectedColor.withOpacity(0.4), width: 1.5),
              ),
              child: Row(
                children: [
                  Text(_selectedEmoji,
                      style: const TextStyle(fontSize: 40)),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      _nameController.text.isEmpty
                          ? 'Your habit name'
                          : _nameController.text,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: _selectedColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Name field
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Habit name',
                hintText: 'e.g. Morning run',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit_outlined),
              ),
              textCapitalization: TextCapitalization.sentences,
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 20),

            // Emoji picker
            Text('Choose an emoji',
                style: theme.textTheme.labelLarge),
            const SizedBox(height: 10),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 8,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: _kEmojiOptions.length,
              itemBuilder: (context, index) {
                final emoji = _kEmojiOptions[index];
                final isSelected = emoji == _selectedEmoji;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEmoji = emoji),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? _selectedColor.withOpacity(0.2)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: isSelected
                          ? Border.all(color: _selectedColor, width: 2)
                          : null,
                    ),
                    child: Center(
                      child: Text(emoji,
                          style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),

            // Color picker
            Row(
              children: [
                Text('Color', style: theme.textTheme.labelLarge),
                const Spacer(),
                GestureDetector(
                  onTap: _pickColor,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: _selectedColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: theme.colorScheme.outline, width: 2),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                TextButton(
                    onPressed: _pickColor,
                    child: const Text('Change')),
              ],
            ),
            const SizedBox(height: 20),

            // Frequency selector
            Text('Frequency', style: theme.textTheme.labelLarge),
            const SizedBox(height: 10),
            SegmentedButton<Frequency>(
              segments: const [
                ButtonSegment(
                  value: Frequency.daily,
                  label: Text('Daily'),
                  icon: Icon(Icons.today),
                ),
                ButtonSegment(
                  value: Frequency.weekly,
                  label: Text('Weekly'),
                  icon: Icon(Icons.view_week),
                ),
              ],
              selected: {_selectedFrequency},
              onSelectionChanged: (s) =>
                  setState(() => _selectedFrequency = s.first),
            ),
          ],
        ),
      ),
    );
  }
}
