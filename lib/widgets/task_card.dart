import 'package:flutter/material.dart';
import '../models/todo.dart';

class TaskCard extends StatelessWidget {
  final Todo todo;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Function(String)? onStatusChange;

  const TaskCard({
    super.key,
    required this.todo,
    this.onEdit,
    this.onDelete,
    this.onStatusChange,
  });

  @override
  Widget build(BuildContext context) {
    final color = getPriorityColor(todo.priority);
    final label = getPriorityLabel(todo.priority);
    final icon = getPriorityIcon(todo.priority);
    final statusColor = getStatusColor(todo.status ?? 'To-Do');
    final statusText = todo.status ?? 'To-Do';

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Priority label bar (top colored strip)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$label $icon',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, color: Colors.white),
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        if (onEdit != null) onEdit!();
                        break;
                      case 'delete':
                        if (onDelete != null) onDelete!();
                        break;
                      case 'To-Do':
                      case 'In Progress':
                      case 'Completed':
                        if (onStatusChange != null) onStatusChange!(value);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'delete', child: Text('Delete')),
                    const PopupMenuDivider(),
                    const PopupMenuItem(value: 'To-Do', child: Text('Mark as To-Do')),
                    const PopupMenuItem(value: 'In Progress', child: Text('Mark as In Progress')),
                    const PopupMenuItem(value: 'Completed', child: Text('Mark as Completed')),
                  ],
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Emoji, Title, Status Tag
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(todo.emoji, style: const TextStyle(fontSize: 24)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        todo.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        statusText,
                        style: const TextStyle(fontSize: 12, color: Colors.white),
                      ),
                    ),
                  ],
                ),

                if (todo.description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      todo.description,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),

                const SizedBox(height: 12),

                // Time (left) and Date (right)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.access_time, size: 14, color: Colors.black),
                        const SizedBox(width: 4),
                        Text(todo.time, style: const TextStyle(fontSize: 12)),
                      ],
                    ),
                    Text(todo.date, style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return const Color(0xFFEA4335);
      case 'Medium':
        return const Color(0xFFED9611);
      case 'Low':
        return const Color(0xFF24A19C);
      default:
        return Colors.grey;
    }
  }

  String getPriorityLabel(String priority) {
    switch (priority) {
      case 'High':
        return 'High Priority';
      case 'Medium':
        return 'Medium Priority';
      case 'Low':
        return 'Low Priority';
      default:
        return 'Priority';
    }
  }

  String getPriorityIcon(String priority) {
    switch (priority) {
      case 'High':
        return '⚠️';
      case 'Medium':
        return '⏳';
      case 'Low':
        return '✅';
      default:
        return '';
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'To-Do':
        return const Color(0xFF218EFD);
      case 'Completed':
        return const Color(0xFF23A26D);
      case 'In Progress':
        return const Color(0xFFF6A221);
      default:
        return Colors.grey;
    }
  }
}
