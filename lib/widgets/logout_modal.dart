import 'package:flutter/material.dart';

class LogoutModal extends StatelessWidget {
  const LogoutModal({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.white,
      titlePadding: EdgeInsets.zero,
      contentPadding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 0.0),
      actionsPadding: const EdgeInsets.all(20.0),

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
            "Confirm Logout",
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 20,
              color: Colors.white,
            ),
          ),
        ),
      ),
      content: const Text(
        "Are you sure you want to log out?",
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 16, color: Colors.black87),
      ),
      actions: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // User cancels
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: Color(0xFFEB5E00)),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop(true); // User confirms
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEB5E00),
                foregroundColor: Colors.white,
              ),
              child: const Text("Log out"),
            ),
          ],
        ),
      ],
    );
  }
}
