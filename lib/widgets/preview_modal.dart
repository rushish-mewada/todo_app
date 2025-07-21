import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';

import '../widgets/add_todo_helpers/pick_date_sheet.dart';
import '../widgets/add_todo_helpers/pick_priority_sheet.dart';
import '../widgets/add_todo_helpers/pick_time_sheet.dart';

typedef GetPriorityColor = Color Function(String priority);
typedef GetPriorityLabel = String Function(String priority);
typedef GetStatusColor = Color Function(String status);

typedef OnUpdateAndSave = Future<void> Function(Todo updatedTodo);

class PreviewModal extends StatefulWidget {
  final Todo todo;
  final OnUpdateAndSave onUpdateAndSave;
  final VoidCallback onDelete;
  final GetPriorityColor getPriorityColor;
  final GetPriorityLabel getPriorityLabel;
  final GetStatusColor getStatusColor;

  const PreviewModal({
    super.key,
    required this.todo,
    required this.onUpdateAndSave,
    required this.onDelete,
    required this.getPriorityColor,
    required this.getPriorityLabel,
    required this.getStatusColor,
  });

  @override
  State<PreviewModal> createState() => _PreviewModalState();
}

class _PreviewModalState extends State<PreviewModal> {
  late String _currentDate;
  late String _currentTime;
  late String _currentPriority;

  @override
  void initState() {
    super.initState();
    _currentDate = widget.todo.date;
    _currentTime = widget.todo.time;
    _currentPriority = widget.todo.priority;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime? initialDate;
    try {
      if (_currentDate.isNotEmpty) {
        initialDate = DateFormat('yMMMd').parse(_currentDate);
      }
    } catch (_) {
      initialDate = DateTime.now();
    }

    final picked = await showModalBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PickDateSheet(initialDate: initialDate),
    );
    if (picked != null) {
      if (mounted) {
        setState(() {
          _currentDate = DateFormat('yMMMd').format(picked);
        });
      }
    }
  }

  Future<void> _pickTime() async {
    TimeOfDay? initialTime;
    try {
      if (_currentTime.isNotEmpty) {
        final format = DateFormat.jm();
        final dt = format.parse(_currentTime);
        initialTime = TimeOfDay.fromDateTime(dt);
      }
    } catch (_) {
      initialTime = TimeOfDay.now();
    }

    final picked = await showModalBottomSheet<TimeOfDay>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PickTimeSheet(initialTime: initialTime),
    );
    if (picked != null) {
      if (mounted) {
        setState(() {
          _currentTime = picked.format(context);
        });
      }
    }
  }

  Future<void> _pickPriority() async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PickPrioritySheet(initialPriority: _currentPriority),
    );
    if (picked != null && picked != _currentPriority) {
      if (mounted) {
        setState(() {
          _currentPriority = picked;
        });
      }
    }
  }

  IconData _getPriorityIconData(String priority) {
    switch (priority) {
      case 'High':
        return Icons.warning_amber_rounded;
      case 'Medium':
        return Icons.hourglass_empty_rounded;
      case 'Low':
        return Icons.check_circle_outline_rounded;
      default:
        return Icons.info_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 0,
              blurRadius: 17,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 24.0, bottom: 20.0),
              child: Center(
                child: Text(
                  "Preview",
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontFamily: 'SFProDisplay',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: const Color(0xFF333333),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.info_outline, size: 28, color: Color(0xFF505050)),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            widget.todo.title,
                            style: const TextStyle(
                              fontFamily: 'SFProDisplay',
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (widget.todo.description.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Center(
                  child: Text(
                    widget.todo.description,
                    style: const TextStyle(
                      fontFamily: 'SFProDisplay',
                      fontSize: 15,
                      color: Color(0xFF767E8C),
                      fontWeight: FontWeight.normal,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Divider(
                height: 0,
                thickness: 0.5,
                color: Color(0xFFE0E0E0),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: _pickPriority,
                    child: Row(
                      children: [
                        const Icon(Icons.flag, size: 18, color: Color(0xFF505050)),
                        const SizedBox(width: 12),
                        const Text(
                          'Priority',
                          style: TextStyle(
                            fontFamily: 'SFProDisplay',
                            fontSize: 16,
                            color: Color(0xFF505050),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          _getPriorityIconData(_currentPriority),
                          size: 18,
                          color: widget.getPriorityColor(_currentPriority),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.getPriorityLabel(_currentPriority),
                          style: TextStyle(
                            fontFamily: 'SFProDisplay',
                            fontSize: 16,
                            color: widget.getPriorityColor(_currentPriority),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickDate,
                    child: Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: Color(0xFF505050)),
                        const SizedBox(width: 12),
                        const Text(
                          'Due Date',
                          style: TextStyle(
                            fontFamily: 'SFProDisplay',
                            fontSize: 16,
                            color: Color(0xFF505050),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _currentDate,
                          style: const TextStyle(
                            fontFamily: 'SFProDisplay',
                            fontSize: 16,
                            color: Color(0xFF767E8C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickTime,
                    child: Row(
                      children: [
                        const Icon(Icons.access_time, size: 18, color: Color(0xFF505050)),
                        const SizedBox(width: 12),
                        const Text(
                          'Time',
                          style: TextStyle(
                            fontFamily: 'SFProDisplay',
                            fontSize: 16,
                            color: Color(0xFF505050),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _currentTime,
                          style: const TextStyle(
                            fontFamily: 'SFProDisplay',
                            fontSize: 16,
                            color: Color(0xFF767E8C),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.0),
              child: Divider(
                height: 0,
                thickness: 0.5,
                color: Color(0xFFE0E0E0),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFF0F0F0),
                        foregroundColor: const Color(0xFFEB5E00),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Back",
                        style: TextStyle(
                          fontFamily: 'SFProDisplay',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        final updatedTodo = Todo(
                          title: widget.todo.title,
                          description: widget.todo.description,
                          emoji: widget.todo.emoji,
                          date: _currentDate,
                          time: _currentTime,
                          priority: _currentPriority,
                          isCompleted: widget.todo.isCompleted,
                          status: widget.todo.status,
                          firebaseId: widget.todo.firebaseId,
                        );
                        Navigator.pop(context);
                        widget.onUpdateAndSave(updatedTodo);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEB5E00),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        elevation: 0,
                      ),
                      child: const Text(
                        "Save",
                        style: TextStyle(
                          fontFamily: 'SFProDisplay',
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
