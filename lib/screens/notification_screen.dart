import 'dart:convert';
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
    List<Map<String, String>> result = [];
    result.addAll(_getPersistedChangeNotifications());

    for (final key in todoBox.keys) {
      final todo = todoBox.get(key);
      if (todo == null) continue;

      result.addAll(_generateNotificationsForTodo(todo, key));
      _updatePreviousData(todo, key);
    }

    _finalizeAndUpdateState(result);
  }

  List<Map<String, String>> _getPersistedChangeNotifications() {
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
    return result;
  }

  List<Map<String, String>> _generateNotificationsForTodo(Todo todo, dynamic key) {
    final List<Map<String, String>> generated = [];
    final now = DateTime.now();
    final timestamp = DateFormat('MMM d, h:mm a').format(now);

    final prevMap = previousDataBox.get(key);
    final prevPriority = prevMap?['priority'];
    final prevDate = prevMap?['date'];
    final prevTime = prevMap?['time'];

    void addNotif(String type, String msg, {bool isChangeNotif = false}) {
      String notifKey;
      if (type == '🗓️ Date Changed') {
        notifKey = '${key}_date_changed_${todo.date}';
      } else if (type == '🕐 Time Changed') {
        notifKey = '${key}_time_changed_${todo.time}';
      } else if (type == '⬆️ Priority Changed') {
        notifKey = '${key}_priority_changed_${todo.priority}';
      } else {
        notifKey = '${key}_${type.hashCode}';
      }

      if (!dismissedBox.containsKey(notifKey)) {
        final newNotif = {
          'type': type,
          'message': msg,
          'key': notifKey,
          'timestamp': timestamp,
        };
        generated.add(newNotif);
        if (isChangeNotif) {
          activeChangeNotifKeysBox.put(notifKey, newNotif);
        }
      }
    }

    if (todo.date.isNotEmpty && todo.time.isNotEmpty) {
      try {
        final dateTimeStr = '${todo.date} ${todo.time.toUpperCase()}';
        final fullDateTime = DateFormat('yMMMd h:mm a').parseStrict(dateTimeStr);
        final timeDiff = fullDateTime.difference(now);

        if (timeDiff.inDays < 0) {
          addNotif('🚨 Overdue Reminder', 'Task "${todo.title}" is overdue by ${timeDiff.inDays.abs()} day${timeDiff.inDays.abs() > 1 ? 's' : ''}!');
        } else if (fullDateTime.isAfter(now) && timeDiff.inMinutes <= 30 && timeDiff.inMinutes > 0) {
          addNotif('🔔 Reminder', 'Your task "${todo.title}" starts in ${timeDiff.inMinutes} minute${timeDiff.inMinutes > 1 ? 's' : ''}. Get ready!');
        } else if (fullDateTime.isBefore(now) && todo.isCompleted != true && todo.status != 'Completed') {
          addNotif('⏳ Task Due', 'Don\'t forget to complete "${todo.title}" before the deadline.');
        } else if (fullDateTime.isAfter(now)) {
          addNotif('⏳ Upcoming Task', 'Upcoming: "${todo.title}" is scheduled soon. Stay prepared!');
        }
      } catch (e) { }
    }

    switch (todo.type) {
      case 'List':
        final progress = _getListProgress(todo.content);
        if (progress > 0 && progress < 100) {
          addNotif('📊 List Progress', "$progress% of items completed in '${todo.title}'.");
        }
        break;
      case 'Journal':
        try {
          final entryDate = DateFormat.yMMMd().parseStrict(todo.date);
          if (entryDate.month == now.month && entryDate.day == now.day && entryDate.year < now.year) {
            final yearsAgo = now.year - entryDate.year;
            addNotif('🗓️ Journal Throwback', 'From ${yearsAgo} year${yearsAgo > 1 ? 's' : ''} ago: "${todo.title}"');
          }
        } catch(e) { }
        break;
      case 'Habit':
        addNotif('🎯 Habit Reminder', 'Don\'t forget to complete your habit: "${todo.title}".');
        if ((todo.streak ?? 0) > 1) {
          addNotif('🔥 Streak Alert', "You're on a ${todo.streak}-day streak for \"${todo.title}\". Keep it up!");
        }
        break;
      case 'Note':
        if (todo.date.isNotEmpty) {
          addNotif('📌 Note Reminder', 'Reminder for your note "${todo.title}" on ${todo.date}.');
        }
        break;
    }

    if (todo.isCompleted == true || todo.status == 'Completed') {
      addNotif('✅ Task Completed', 'Good job! You completed "${todo.title}".');
    } else if (todo.status == 'In Progress') {
      addNotif('🚧 Task In Progress', 'You started working on "${todo.title}". Keep it going!');
    } else if (todo.needsUpdate == true) {
      addNotif('✏️ Task Updated', 'You made changes to "${todo.title}".');
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

    return generated;
  }

  int _getListProgress(String? content) {
    if (content == null || content.isEmpty) return 0;
    try {
      final List<dynamic> items = jsonDecode(content);
      if (items.isEmpty) return 0;
      final int completedCount = items.where((item) => (item['checked'] as bool? ?? false)).length;
      return ((completedCount / items.length) * 100).round();
    } catch (e) {
      return 0;
    }
  }

  void _updatePreviousData(Todo todo, dynamic key) {
    previousDataBox.put(key, {
      'priority': todo.priority,
      'date': todo.date,
      'time': todo.time,
    });
  }

  void _finalizeAndUpdateState(List<Map<String, String>> allNotifications) {
    final uniqueResults = <String, Map<String, String>>{};
    for (var notif in allNotifications) {
      uniqueResults[notif['key']!] = notif;
    }

    List<Map<String, String>> finalNotifications = uniqueResults.values.toList();

    if (finalNotifications.isEmpty) {
      finalNotifications.add({
        'type': '',
        'message': 'No notifications for today.',
        'key': 'none',
        'timestamp': DateFormat('MMM d, h:mm a').format(DateTime.now()),
      });
    }

    if (!mounted) return;
    setState(() {
      notifications = finalNotifications;
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
      if (notifications.isEmpty) {
        _finalizeAndUpdateState([]);
      }
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
    _finalizeAndUpdateState([]);
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
              !(notifications.length == 1 && notifications[0]['key'] == 'none'))
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
