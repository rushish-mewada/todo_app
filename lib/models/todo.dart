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

  @HiveField(11)
  String type;

  @HiveField(12)
  String? content;

  @HiveField(13)
  List<String>? frequency;

  @HiveField(14)
  int? streak;

  @HiveField(15)
  String? lastCompletedDate;

  @HiveField(16)
  String? mood;


  Todo({
    required this.title,
    this.description = '',
    this.emoji = '',
    this.date = '',
    this.time = '',
    this.priority = 'Low',
    this.isCompleted = false,
    this.status = 'To-Do',
    this.firebaseId,
    this.isDeleted = false,
    this.needsUpdate = false,
    this.type = 'To-Do',
    this.content,
    this.frequency,
    this.streak,
    this.lastCompletedDate,
    this.mood,
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
      'type': type,
      'content': content,
      'frequency': frequency,
      'streak': streak,
      'lastCompletedDate': lastCompletedDate,
      'mood': mood,
    };
  }

  factory Todo.fromMap(Map<String, dynamic> map) {
    return Todo(
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      emoji: map['emoji'] ?? '',
      date: map['date'] ?? '',
      time: map['time'] ?? '',
      priority: map['priority'] ?? 'Low',
      isCompleted: map['isCompleted'] ?? false,
      status: map['status'] ?? 'To-Do',
      firebaseId: map['firebaseId'],
      isDeleted: map['isDeleted'] ?? false,
      needsUpdate: map['needsUpdate'] ?? false,
      type: map['type'] ?? 'To-Do',
      content: map['content'],
      frequency: map['frequency'] != null ? List<String>.from(map['frequency']) : null,
      streak: map['streak'],
      lastCompletedDate: map['lastCompletedDate'],
      mood: map['mood'],
    );
  }
}
