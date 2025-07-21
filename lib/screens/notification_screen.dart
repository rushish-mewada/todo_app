import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../models/todo.dart';
import '../widgets/bot_nav.dart';
import '../widgets/refresh.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<Map<String, String>> notifications = [];
  late Box<Todo> todoBox;
  late Box dismissedBox;

  @override
  void initState() {
    super.initState();
    todoBox = Hive.box<Todo>('todos');
    dismissedBox = Hive.box('dismissed_notifications');
    generateNotifications();
  }

  Future<void> generateNotifications() async {
    final todos = todoBox.values.toList();
    final now = DateTime.now();
    List<Map<String, String>> result = [];

    for (var todo in todos) {
      if (todo.date.isEmpty || todo.time.isEmpty) continue;

      DateTime? fullDateTime;
      try {
        final dateTimeStr = '${todo.date} ${todo.time.toUpperCase()}';
        fullDateTime = DateFormat('yMMMd h:mm a').parseStrict(dateTimeStr);
      } catch (e) {
        try {
          fullDateTime = DateFormat('yMMMd').parseStrict(todo.date);
        } catch (_) {
          continue;
        }
      }

      final timeDiff = fullDateTime.difference(now);

      String? type;
      String? message;

      if (!["Done", "Completed"].contains(todo.priority)) {
        if (timeDiff.inMinutes <= 30 && timeDiff.inMinutes > 0) {
          type = '🔔 Reminder';
          message = 'Your task "${todo.title}" starts in ${timeDiff.inMinutes} minutes. Get ready!';
        } else if (timeDiff.isNegative) {
          type = '⏳ Task Due';
          message = 'Don\'t forget to complete "${todo.title}" before the deadline.';
        } else {
          type = '⏳ Upcoming Task';
          message = 'Upcoming: "${todo.title}" is scheduled soon. Stay prepared!';
        }
      } else {
        type = '✅ Task Completed';
        message = 'Good job! You completed "${todo.title}".';
      }

      final key = '${todo.title}_$type';
      if (type != null && message != null && !dismissedBox.containsKey(key)) {
        result.add({'type': type, 'message': message, 'key': key});
      }
    }

    if (result.isEmpty) {
      result.add({'type': '', 'message': 'No notifications for today.', 'key': ''});
    }

    setState(() {
      notifications = result;
    });
  }

  void removeNotification(int index) {
    final notif = notifications[index];
    final key = notif['key'];
    if (key != null && key.isNotEmpty) {
      dismissedBox.put(key, true);
    }

    setState(() {
      notifications.removeAt(index);
    });
  }

  void clearAllNotifications() {
    for (var notif in notifications) {
      final key = notif['key'];
      if (key != null && key.isNotEmpty) {
        dismissedBox.put(key, true);
      }
    }
    setState(() {
      notifications.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const BackButton(color: Colors.black),
        title: const Text(
          "Notifications",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        actions: [
          if (notifications.isNotEmpty &&
              !(notifications.length == 1 && notifications[0]['type'] == ''))
            TextButton(
              onPressed: clearAllNotifications,
              child: const Text(
                "Clear All",
                style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: RefreshWrapper(
        onRefresh: generateNotifications,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final type = notifications[index]['type']!;
            final message = notifications[index]['message']!;

            return Dismissible(
              key: Key('$type-$message'),
              direction: DismissDirection.endToStart,
              onDismissed: (_) => removeNotification(index),
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.redAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete, color: Colors.white),
              ),
              child: Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 6,
                      offset: Offset(0, 2),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (type.isNotEmpty)
                      Text(
                        type,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BotNav(currentIndex: 1, onTap: (index) {}),
    );
  }
}
