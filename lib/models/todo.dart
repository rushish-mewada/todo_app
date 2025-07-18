import 'package:hive/hive.dart';
part 'todo.g.dart';

@HiveType(typeId: 0)
class Todo extends HiveObject {
  @HiveField(0)
  String title;

  @HiveField(1)
  String description;

  @HiveField(2)
  String emoji;

  @HiveField(3)
  String date;

  @HiveField(4)
  String time;

  @HiveField(5)
  String priority;

  @HiveField(6)
  bool? isCompleted;

  @HiveField(7)
  String? status;

  @HiveField(8)
  String? firebaseId;

  @HiveField(9)
  bool? isDeleted;

  @HiveField(10)
  bool? needsUpdate;

  Todo({
    required this.title,
    required this.description,
    required this.emoji,
    required this.date,
    required this.time,
    required this.priority,
    this.isCompleted = false,
    this.status = 'To-Do',
    this.firebaseId,
    this.isDeleted = false,
    this.needsUpdate = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'emoji': emoji,
      'date': date,
      'time': time,
      'priority': priority,
      'isCompleted': isCompleted,
      'status': status,
      'firebaseId': firebaseId,
      'isDeleted': isDeleted,
      'needsUpdate': needsUpdate,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      emoji: map['emoji'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      priority: map['priority'] ?? '',
      isCompleted: map['isCompleted'] ?? false,
      status: map['status'] ?? 'To-Do',
      firebaseId: map['firebaseId'],
      isDeleted: map['isDeleted'] ?? false,
      needsUpdate: map['needsUpdate'] ?? false,
    );
  }
}
