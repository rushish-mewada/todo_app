import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';

class HabitCard extends StatelessWidget {
  final Todo todo;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const HabitCard({
    super.key,
    required this.todo,
    this.onEdit,
    this.onDelete,
  });

  Widget _getIconForType(String type) {
    return const Icon(Icons.repeat, color: Color(0xFFEB5E00));
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

  Widget _buildFrequencyDisplay(List<String> frequency) {
    final List<String> displayDays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final List<String> fullDayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

    final Set<String> activeFullDays = frequency.map((d) => d.trim()).toSet();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(7, (index) {
        final dayInitial = displayDays[index];
        final fullDayName = fullDayNames[index];
        final isActive = activeFullDays.contains(fullDayName);

        return Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFFEB5E00) : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              dayInitial,
              style: TextStyle(
                color: isActive ? Colors.white : Colors.black54,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        );
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
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
              color: const Color(0xFF3D74B6),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  todo.type,
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
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
                  ],
                ),
                if (todo.description.isNotEmpty == true)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      todo.description,
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                  ),
                if (todo.content?.isNotEmpty == true)
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
                if (todo.frequency?.isNotEmpty == true)
                  _buildFrequencyDisplay(todo.frequency!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
