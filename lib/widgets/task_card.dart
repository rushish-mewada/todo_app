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

  Widget _getIconForType(String type) {
    switch (type) {
      case 'Note':
        return const Icon(Icons.notes_rounded, color: Color(0xFFEB5E00));
      case 'Habit':
        return const Icon(Icons.repeat, color: Color(0xFFEB5E00));
      case 'Journal':
        return const Icon(Icons.book, color: Color(0xFFEB5E00));
      case 'To-Do':
      default:
        return const Icon(Icons.check_circle_outline, color: Color(0xFFEB5E00));
    }
  }

  PopupMenuEntry<String> _buildPopupMenuItem(
      IconData icon, String text, String value, Color textColor,
      {Color? iconColor}) {
    return PopupMenuItem<String>(
      value: value,
      padding: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? textColor, size: 20),
            const SizedBox(width: 12),
            Text(
              text,
              style: TextStyle(fontSize: 16, color: textColor),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuEntry<String> _buildPopupDivider() {
    return const PopupMenuDivider(height: 1);
  }

  @override
  Widget build(BuildContext context) {
    final color = getPriorityColor(todo.priority);
    final label = getPriorityLabel(todo.priority);
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.flag_outlined, color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ],
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
                  color: Colors.white,
                  elevation: 8,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.grey.shade300, width: 1),
                  ),
                  itemBuilder: (context) => [
                    _buildPopupMenuItem(Icons.edit, 'Edit', 'edit', Colors.black87, iconColor: const Color(0xFFEB5E00)),
                    _buildPopupMenuItem(Icons.delete, 'Delete', 'delete', Colors.redAccent),
                    if (todo.type == 'To-Do') _buildPopupDivider(),
                    if (todo.type == 'To-Do')
                      _buildPopupMenuItem(Icons.pending_actions, 'Mark as To-Do', 'To-Do', Colors.black87),
                    if (todo.type == 'To-Do')
                      _buildPopupMenuItem(Icons.run_circle_outlined, 'Mark as In Progress', 'In Progress', Colors.black87),
                    if (todo.type == 'To-Do')
                      _buildPopupMenuItem(Icons.check_circle_outline, 'Mark as Completed', 'Completed', Colors.black87),
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _getIconForType(todo.type),
                    const SizedBox(width: 12),
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
                    if (todo.type == 'To-Do')
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
                if (todo.content != null && todo.content!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      todo.content!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                const SizedBox(height: 12),
                if (todo.date.isNotEmpty)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (todo.time.isNotEmpty)
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
        return Colors.grey.shade400;
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
        return todo.type;
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
