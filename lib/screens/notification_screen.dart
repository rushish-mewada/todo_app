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
    final timestamp = DateFormat('MMM d, h:mm a').format(now);

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

      // 1. Completed Task
      if (todo.status == 'Completed' || todo.isCompleted == true) {
        type = '✅ Task Completed';
        message = 'Good job! You completed "${todo.title}".';
      }

      // 2. In Progress Tracking
      else if (todo.status == 'In Progress') {
        type = '🚧 Task In Progress';
        message = 'You started working on "${todo.title}". Keep it going!';
      }

      // 3. Task Updated
      else if (todo.needsUpdate == true) {
        type = '✏️ Task Updated';
        message = 'You made changes to "${todo.title}".';
      }

      // 4. Upcoming/Due/Reminder
      else {
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
      }

      final key = '${todo.title}_$type';
      if (type != null && message != null && !dismissedBox.containsKey(key)) {
        result.add({
          'type': type,
          'message': message,
          'key': key,
          'timestamp': timestamp,
        });
      }
    }

    if (result.isEmpty) {
      result.add({
        'type': '',
        'message': 'No notifications for today.',
        'key': 'none',
        'timestamp': timestamp,
      });
    }

    if (!mounted) return;
    setState(() {
      notifications = result;
    });
  }

  void removeNotification(int index) {
    final notif = notifications[index];
    final key = notif['key'];
    if (key != null && key != 'none') {
      dismissedBox.put(key, true);
    }
    setState(() {
      notifications.removeAt(index);
    });
  }

  void clearAllNotifications() {
    for (var notif in notifications) {
      final key = notif['key'];
      if (key != null && key != 'none') {
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
        child: notifications.length == 1 && notifications[0]['key'] == 'none'
            ? const Center(
          child: Text(
            'No notifications for today.',
            style: TextStyle(fontSize: 16, color: Colors.black54),
            textAlign: TextAlign.center,
          ),
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: notifications.length,
          itemBuilder: (context, index) {
            final type = notifications[index]['type']!;
            final message = notifications[index]['message']!;
            final timestamp = notifications[index]['timestamp'] ?? '';

            return Dismissible(
              key: Key('${notifications[index]['key']}'),
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
              child: SizedBox(
                width: double.infinity,
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
                      if (timestamp.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            timestamp,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                    ],
                  ),
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
