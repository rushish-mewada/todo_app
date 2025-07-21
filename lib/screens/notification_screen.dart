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
  late Box previousDataBox;
  late Box activeChangeNotifKeysBox;

  @override
  void initState() {
    super.initState();
    todoBox = Hive.box<Todo>('todos');
    dismissedBox = Hive.box('dismissed_notifications');
    previousDataBox = Hive.box('previous_todo_data');
    activeChangeNotifKeysBox = Hive.box('active_change_notification_keys');
    generateNotifications();
  }

  Future<void> generateNotifications() async {
    final todos = todoBox.values.toList();
    final now = DateTime.now();
    final timestamp = DateFormat('MMM d, h:mm a').format(now);

    List<Map<String, String>> result = [];

    for (var key in activeChangeNotifKeysBox.keys) {
      final storedNotif = activeChangeNotifKeysBox.get(key);
      if (storedNotif != null && storedNotif is Map<dynamic, dynamic>) {
        result.add({
          'type': storedNotif['type'] as String,
          'message': storedNotif['message'] as String,
          'key': storedNotif['key'] as String,
          'timestamp': storedNotif['timestamp'] as String,
        });
      }
    }

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
      final prevMap = previousDataBox.get(todo.key);
      final prevPriority = prevMap?['priority'];
      final prevDate = prevMap?['date'];
      final prevTime = prevMap?['time'];

      void addNotif(String type, String msg, {bool isChangeNotif = false}) {
        String key;
        if (type == '🗓️ Date Changed') {
          key = '${todo.key}_date_changed_${todo.date}';
        } else if (type == '🕐 Time Changed') {
          key = '${todo.key}_time_changed_${todo.time}';
        } else if (type == '⬆️ Priority Changed') {
          key = '${todo.key}_priority_changed_${todo.priority}';
        } else if (type == '✏️ Task Updated') {
          key = '${todo.key}_task_updated';
        } else {
          key = '${todo.key}_$type';
        }

        if (!dismissedBox.containsKey(key)) {
          final newNotif = {
            'type': type,
            'message': msg,
            'key': key,
            'timestamp': timestamp,
          };
          result.add(newNotif);
          if (isChangeNotif) {
            activeChangeNotifKeysBox.put(key, newNotif);
          }
        }
      }

      if (timeDiff.inDays < 0) {
        addNotif('🚨 Overdue Reminder', 'Task "${todo.title}" is overdue by ${timeDiff.inDays.abs()} day${timeDiff.inDays.abs() > 1 ? 's' : ''}!');
      }

      if (todo.isCompleted == true || todo.status == 'Completed') {
        addNotif('✅ Task Completed', 'Good job! You completed "${todo.title}".');
      } else if (todo.status == 'In Progress') {
        addNotif('🚧 Task In Progress', 'You started working on "${todo.title}". Keep it going!');
      } else if (todo.needsUpdate == true) {
        addNotif('✏️ Task Updated', 'You made changes to "${todo.title}".');
      } else {
        if (fullDateTime.isAfter(now) && timeDiff.inMinutes <= 30 && timeDiff.inMinutes > 0) {
          addNotif('🔔 Reminder', 'Your task "${todo.title}" starts in ${timeDiff.inMinutes} minute${timeDiff.inMinutes > 1 ? 's' : ''}. Get ready!');
        } else if (fullDateTime.isBefore(now) && (todo.isCompleted == false) && todo.status != 'Completed') {
          addNotif('⏳ Task Due', 'Don\'t forget to complete "${todo.title}" before the deadline.');
        } else if (fullDateTime.isAfter(now)) {
          addNotif('⏳ Upcoming Task', 'Upcoming: "${todo.title}" is scheduled soon. Stay prepared!');
        }
      }

      if (prevDate != null && prevDate != todo.date) {
        addNotif('🗓️ Date Changed', 'Task "${todo.title}" was rescheduled to ${todo.date}.', isChangeNotif: true);
      }

      if (prevTime != null && prevTime != todo.time) {
        addNotif('🕐 Time Changed', 'Task "${todo.title}" time updated to ${todo.time}.', isChangeNotif: true);
      }

      if (prevPriority != null && prevPriority != todo.priority) {
        addNotif('⬆️ Priority Changed', 'Task "${todo.title}" priority changed from $prevPriority to ${todo.priority}.', isChangeNotif: true);
      }

      previousDataBox.put(todo.key, {
        'priority': todo.priority,
        'date': todo.date,
        'time': todo.time,
      });
    }

    final uniqueResults = <String, Map<String, String>>{};
    for (var notif in result) {
      uniqueResults[notif['key']!] = notif;
    }
    result = uniqueResults.values.toList();

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
      activeChangeNotifKeysBox.delete(key);
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
        activeChangeNotifKeysBox.delete(key);
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
