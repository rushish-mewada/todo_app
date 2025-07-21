import 'package:flutter/material.dart';

class DeleteConfirmationModal extends StatelessWidget {
  final String taskTitle;

  const DeleteConfirmationModal({super.key, required this.taskTitle});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.white,
      titlePadding: EdgeInsets.zero,

      title: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: const BoxDecoration(
          color: Color(0xFFEB5E00),
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Center(
          child: Text(
            "Delete Task",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ),
      content: Padding(
        padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_forever, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text(
              "Are you sure you want to delete \"$taskTitle\"?",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 10),
            const Text(
              "This action cannot be undone.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
          ],
        ),
      ),
      actions: <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 0.0), // Reduced vertical padding
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center, // Centered the buttons
            children: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(false);
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: Color(0xFFEB5E00)),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop(true);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text("Delete"),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
