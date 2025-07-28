import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/todo.dart';
import 'add_todo_helpers/pick_date_sheet.dart';
import 'add_todo_helpers/pick_priority_sheet.dart';
import 'add_todo_helpers/pick_time_sheet.dart';

class AddTodo extends StatefulWidget {
  final Todo? existingTodo;

  const AddTodo({super.key, this.existingTodo});

  @override
  State<AddTodo> createState() => _AddTodoState();
}

class _AddTodoState extends State<AddTodo> with SingleTickerProviderStateMixin {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final FocusNode titleFocusNode = FocusNode();
  final FocusNode descFocusNode = FocusNode();
  final ScrollController scrollController = ScrollController();

  String selectedEmoji = '';
  String selectedPriority = 'Low'; // Default priority changed to Low
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  final List<String> emojis = ['😀', '🤑', '😇', '🥰', '🙌', '👋', '😓', '✌️'];

  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    if (widget.existingTodo != null) {
      titleController.text = widget.existingTodo!.title;
      descriptionController.text = widget.existingTodo!.description;
      selectedEmoji = widget.existingTodo!.emoji;
      selectedPriority = widget.existingTodo!.priority;
      if (widget.existingTodo!.date.isNotEmpty) {
        try {
          selectedDate = DateFormat.yMMMd().parse(widget.existingTodo!.date);
        } catch (e) {
          print("Error parsing date: ${widget.existingTodo!.date}");
        }
      }
      if (widget.existingTodo!.time.isNotEmpty) {
        try {
          final timeParts = widget.existingTodo!.time.split(' ');
          final hm = timeParts[0].split(':');
          int hour = int.parse(hm[0]);
          int minute = int.parse(hm[1]);
          if (timeParts.length > 1 && timeParts[1].toLowerCase() == 'pm' && hour < 12) {
            hour += 12;
          }
          if (timeParts.length > 1 && timeParts[1].toLowerCase() == 'am' && hour == 12) {
            hour = 0;
          }
          selectedTime = TimeOfDay(hour: hour, minute: minute);
        } catch (e) {
          print("Error parsing time: ${widget.existingTodo!.time}");
        }
      }
    }

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    scrollController.dispose();
    titleController.dispose();
    descriptionController.dispose();
    titleFocusNode.dispose();
    descFocusNode.dispose();
    super.dispose();
  }

  void insertEmojiAtCursor(String emoji) {
    TextEditingController controller;
    if (titleFocusNode.hasFocus) {
      controller = titleController;
    } else if (descFocusNode.hasFocus) {
      controller = descriptionController;
    } else {
      // Default to title controller if no field is focused
      controller = titleController;
    }

    final text = controller.text;
    final selection = controller.selection;
    final newText = text.replaceRange(selection.start, selection.end, emoji);
    final newPosition = selection.start + emoji.length;

    controller.text = newText;
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: newPosition),
    );

    setState(() {
      selectedEmoji = emoji;
    });
  }

  void _pickDate() async {
    final pickedDate = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PickDateSheet(initialDate: selectedDate),
    );
    if (pickedDate != null) {
      setState(() => selectedDate = pickedDate);
      if (mounted) {
        _pickTime();
      }
    }
  }

  void _pickTime() async {
    final picked = await showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PickTimeSheet(initialTime: selectedTime),
    );
    if (picked != null) {
      setState(() => selectedTime = picked);
    }
  }

  void _pickPriority() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PickPrioritySheet(initialPriority: selectedPriority),
    );
    if (picked != null) {
      setState(() => selectedPriority = picked);
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'High':
        return 'High Priority';
      case 'Medium':
        return 'Medium Priority';
      case 'Low':
        return 'Low Priority';
      default:
        return priority;
    }
  }

  void _handleSubmit() {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    final todoToReturn = Todo(
      title: title,
      description: descriptionController.text.trim(),
      emoji: selectedEmoji,
      date: selectedDate != null ? DateFormat.yMMMd().format(selectedDate!) : '',
      time: selectedTime != null ? selectedTime!.format(context) : '',
      priority: selectedPriority,
      isCompleted: widget.existingTodo?.isCompleted ?? false,
      status: widget.existingTodo?.status ?? 'To-Do',
      firebaseId: widget.existingTodo?.firebaseId,
      isDeleted: widget.existingTodo?.isDeleted ?? false,
      needsUpdate: widget.existingTodo?.needsUpdate ?? false,
    );

    Navigator.pop(context, todoToReturn);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedPadding(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.only(bottom: bottomInset),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: SingleChildScrollView(
              controller: scrollController,
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
                        widget.existingTodo == null ? 'New Todo' : 'Edit Todo',
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
                      children: [
                        TextField(
                          controller: titleController,
                          focusNode: titleFocusNode,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Eg : Meeting with client',
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: descriptionController,
                          focusNode: descFocusNode,
                          maxLines: 3,
                          style: const TextStyle(fontSize: 16),
                          decoration: const InputDecoration(
                            hintText: 'Description',
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            enabledBorder: InputBorder.none,
                          ),
                          textCapitalization: TextCapitalization.sentences,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.calendar_today, color: Colors.grey),
                              onPressed: _pickDate,
                            ),
                            IconButton(
                              icon: const Icon(Icons.access_time, color: Colors.grey),
                              onPressed: _pickTime,
                            ),
                            IconButton(
                              icon: const Icon(Icons.flag, color: Colors.grey),
                              onPressed: _pickPriority,
                            ),
                            const Spacer(),
                            if (selectedDate != null)
                              Text(DateFormat.yMMMd().format(selectedDate!), style: const TextStyle(fontSize: 12)),
                            if (selectedTime != null)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(selectedTime!.format(context), style: const TextStyle(fontSize: 12)),
                              ),
                            if (selectedPriority.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(left: 8),
                                child: Text(_getPriorityLabel(selectedPriority), style: const TextStyle(fontSize: 12)),
                              ),
                          ],
                        ),
                        const Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: emojis.map((emoji) {
                            final isSelected = emoji == selectedEmoji;
                            return GestureDetector(
                              onTap: () => insertEmojiAtCursor(emoji),
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
        ),
      ),
    );
  }
}
