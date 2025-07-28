import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';

class AddHabit extends StatefulWidget {
  final Todo? existingHabit;

  const AddHabit({super.key, this.existingHabit});

  @override
  State<AddHabit> createState() => _AddHabitState();
}

class _AddHabitState extends State<AddHabit> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  String selectedEmoji = '';
  List<String> selectedDays = [];

  final List<String> emojis = ['🧘', '💧', '📖', '🏃', '💪', '🍎', '☀️', '🌙'];
  final List<String> weekDaysAbbr = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  final List<String> weekDaysFull = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  void initState() {
    super.initState();
    if (widget.existingHabit != null) {
      titleController.text = widget.existingHabit!.title;
      descriptionController.text = widget.existingHabit!.description;
      selectedEmoji = widget.existingHabit!.emoji;
      // Ensure we are working with a list of full day names
      selectedDays = widget.existingHabit!.frequency ?? [];
    }
  }

  void _toggleDay(int index) {
    final fullDayName = weekDaysFull[index];
    setState(() {
      if (selectedDays.contains(fullDayName)) {
        selectedDays.remove(fullDayName);
      } else {
        selectedDays.add(fullDayName);
      }
    });
  }

  void _handleSubmit() {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Habit title cannot be empty')),
      );
      return;
    }

    final habitToReturn = Todo(
      title: title,
      description: descriptionController.text.trim(),
      emoji: selectedEmoji,
      frequency: selectedDays, // This now saves the list of full day names
      type: 'Habit',
      date: DateFormat.yMMMd().format(DateTime.now()),
      time: '',
      priority: '',
      status: '',
    );

    Navigator.pop(context, habitToReturn);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFEB5E00),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Center(
                  child: Text(
                    widget.existingHabit == null ? 'New Habit' : 'Edit Habit',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'e.g., Morning Meditation',
                        border: InputBorder.none,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const Divider(),
                    TextField(
                      controller: descriptionController,
                      maxLines: 2,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Description (optional)',
                        border: InputBorder.none,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 16),
                    const Text('Frequency', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(weekDaysAbbr.length, (index) {
                        final dayAbbr = weekDaysAbbr[index];
                        final dayFull = weekDaysFull[index];
                        final isSelected = selectedDays.contains(dayFull);

                        return GestureDetector(
                          onTap: () => _toggleDay(index),
                          child: Container(
                            width: 40,
                            height: 40,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFEB5E00) : Colors.grey[200],
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              dayAbbr.substring(0, 1),
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 20),
                    const Text('Emoji', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: emojis.map((emoji) {
                        final isSelected = emoji == selectedEmoji;
                        return GestureDetector(
                          onTap: () => setState(() => selectedEmoji = emoji),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFEB5E00).withOpacity(0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _handleSubmit,
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFEB5E00),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: const Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
