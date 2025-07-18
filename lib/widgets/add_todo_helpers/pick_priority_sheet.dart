import 'package:flutter/material.dart';

class PickPrioritySheet extends StatelessWidget {
  final String initialPriority;

  const PickPrioritySheet({super.key, required this.initialPriority});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              blurRadius: 12,
              color: Colors.black.withOpacity(0.2),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildOption(
              context,
              emoji: '⚠️',
              label: 'High Priority',
              color: Colors.pink,
            ),
            const Divider(height: 1),
            _buildOption(
              context,
              emoji: '⏳',
              label: 'Medium Priority',
              color: Colors.orange,
            ),
            const Divider(height: 1),
            _buildOption(
              context,
              emoji: '✅',
              label: 'Low Priority',
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(BuildContext context,
      {required String emoji,
        required String label,
        required Color color}) {
    return InkWell(
      onTap: () => Navigator.pop(context, label.split(' ')[0]), // returns "High", "Medium", or "Low"
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Text(emoji, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 16,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
