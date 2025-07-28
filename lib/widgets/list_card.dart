import 'package:flutter/material.dart';
import '../models/todo.dart';

class ListCard extends StatelessWidget {
  final Todo todo;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  const ListCard({
    super.key,
    required this.todo,
    this.onEdit,
    this.onDelete,
    this.onTap,
  });

  Widget _getIconForType(String type) {
    return const Icon(Icons.list_alt, color: Color(0xFFEB5E00));
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

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
              decoration: const BoxDecoration(
                color: Color(0xFF4CAF50), // Updated static color for List header
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    todo.type,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600), // Text color white
                  ),
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_horiz, color: Colors.white), // Icon color white
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
                  if (todo.description?.isNotEmpty == true)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        todo.description!,
                        style: const TextStyle(fontSize: 14, color: Colors.black87),
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
