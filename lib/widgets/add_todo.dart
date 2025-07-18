import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
  String selectedPriority = 'Medium';
  DateTime? selectedDate;
  TimeOfDay? selectedTime;

  final List<String> emojis = ['😀', '🤑', '😇', '🥰', '🙌', '👋', '😓', '✌️'];

  bool _titleEdited = false;
  bool _descEdited = false;

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
        selectedDate = DateFormat.yMMMd().parse(widget.existingTodo!.date);
      }
      if (widget.existingTodo!.time.isNotEmpty) {
        final timeParts = widget.existingTodo!.time.split(' ');
        final hm = timeParts[0].split(':');
        int hour = int.parse(hm[0]);
        int minute = int.parse(hm[1]);
        if (timeParts.length > 1 && timeParts[1].toLowerCase() == 'pm' && hour < 12) {
          hour += 12;
        }
        selectedTime = TimeOfDay(hour: hour, minute: minute);
      }
    }

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _fadeAnimation = Tween<double>(begin: 0, end: 1)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));
    _controller.forward();

    titleFocusNode.addListener(() => _scrollToField(titleFocusNode));
    descFocusNode.addListener(() => _scrollToField(descFocusNode));
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

  void _scrollToField(FocusNode focusNode) {
    if (focusNode.hasFocus) {
      Future.delayed(const Duration(milliseconds: 300), () {
        scrollController.animateTo(
          scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  void insertEmojiAtCursor(String emoji) {
    TextEditingController controller;
    if (titleFocusNode.hasFocus) {
      controller = titleController;
    } else if (descFocusNode.hasFocus) {
      controller = descriptionController;
    } else {
      return;
    }

    final text = controller.text;
    final selection = controller.selection;
    final newText = text.replaceRange(selection.start, selection.end, emoji);
    final newPosition = selection.start + emoji.length;

    setState(() {
      selectedEmoji = emoji;
      controller.text = newText;
      controller.selection = TextSelection.fromPosition(
        TextPosition(offset: newPosition),
      );
    });
  }

  void _handleTitleChange(String value) {
    if (!_titleEdited && value.isNotEmpty) {
      _titleEdited = true;
      final updated = value[0].toUpperCase() + value.substring(1);
      titleController.value = TextEditingValue(
        text: updated,
        selection: TextSelection.collapsed(offset: updated.length),
      );
    }
  }

  void _handleDescChange(String value) {
    if (!_descEdited && value.isNotEmpty) {
      _descEdited = true;
      final updated = value[0].toUpperCase() + value.substring(1);
      descriptionController.value = TextEditingValue(
        text: updated,
        selection: TextSelection.collapsed(offset: updated.length),
      );
    }
  }

  void _pickDate() async {
    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PickDateSheet(initialDate: selectedDate),
    );
    if (picked != null) {
      setState(() => selectedDate = picked);
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

  void _handleSubmit() async {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    final newTodo = Todo(
      title: title,
      description: descriptionController.text.trim(),
      emoji: selectedEmoji,
      date: selectedDate != null ? DateFormat.yMMMd().format(selectedDate!) : '',
      time: selectedTime != null ? selectedTime!.format(context) : '',
      priority: selectedPriority,
    );

    final box = Hive.box<Todo>('todos');

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        final tasksCollection = FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .collection('tasks');

        final docRef = widget.existingTodo?.firebaseId != null
            ? tasksCollection.doc(widget.existingTodo!.firebaseId)
            : tasksCollection.doc();

        final firebaseId = docRef.id;

        final todoToSave = Todo(
          title: newTodo.title,
          description: newTodo.description,
          emoji: newTodo.emoji,
          date: newTodo.date,
          time: newTodo.time,
          priority: newTodo.priority,
          isCompleted: newTodo.isCompleted,
          status: newTodo.status,
          firebaseId: firebaseId,
        );

        await docRef.set({
          'title': todoToSave.title,
          'description': todoToSave.description,
          'emoji': todoToSave.emoji,
          'date': todoToSave.date,
          'time': todoToSave.time,
          'priority': todoToSave.priority,
          'isCompleted': todoToSave.isCompleted,
          'status': todoToSave.status,
          'firebaseId': todoToSave.firebaseId,
          'createdAt': FieldValue.serverTimestamp(),
        });

        if (widget.existingTodo != null && widget.existingTodo!.key != null) {
          await box.put(widget.existingTodo!.key, todoToSave);
        } else {
          await box.add(todoToSave);
        }
      } else {
        throw Exception('User not signed in');
      }
    } catch (e) {
      debugPrint('Firestore unavailable: saving to Hive only. Error: $e');
      if (widget.existingTodo != null && widget.existingTodo!.key != null) {
        await box.put(widget.existingTodo!.key, newTodo);
      } else {
        await box.add(newTodo);
      }
    }

    if (mounted) Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Todo saved')),
    );
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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: const BoxDecoration(
                    color: Color(0xFFEB5E00),
                    borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: const Center(
                    child: Text(
                      'New Todo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: titleController,
                          focusNode: titleFocusNode,
                          onChanged: _handleTitleChange,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Eg : Meeting with client',
                            border: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: descriptionController,
                          focusNode: descFocusNode,
                          onChanged: _handleDescChange,
                          maxLines: 2,
                          style: const TextStyle(fontSize: 16),
                          decoration: const InputDecoration(
                            hintText: 'Description',
                            border: InputBorder.none,
                          ),
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
                                child: Text(selectedPriority, style: const TextStyle(fontSize: 12)),
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
                              child: Text(
                                emoji,
                                style: TextStyle(
                                  fontSize: 24,
                                  backgroundColor: isSelected
                                      ? const Color(0xFFEB5E00).withOpacity(0.2)
                                      : Colors.transparent,
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
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}