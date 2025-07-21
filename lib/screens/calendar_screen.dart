import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/todo.dart';
import '../widgets/add_todo.dart';
import '../widgets/task_card.dart';
import '../widgets/bot_nav.dart';
import '../widgets/refresh.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;
  bool showFloatingMenu = false;

  late Box<Todo> todoBox;
  DateTime selectedDate = DateTime.now();

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    todoBox = Hive.box<Todo>('todos');
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);
    _syncFirestoreToHive();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  void _scrollToSelectedDate() {
    final double itemWidth = 60 + 12;
    final double offset = (selectedDate.day - 1) * itemWidth -
        MediaQuery.of(context).size.width / 2 +
        itemWidth / 2;

    _scrollController.animateTo(
      offset.clamp(0, _scrollController.position.maxScrollExtent),
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOut,
    );
  }

  Future<void> _syncFirestoreToHive() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final firestoreTasks = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .get();

    final existingIds = todoBox.values.map((t) => t.firebaseId).toSet();

    for (var doc in firestoreTasks.docs) {
      final data = doc.data();
      if (!existingIds.contains(doc.id)) {
        final todo = Todo(
          title: data['title'] ?? '',
          description: data['description'] ?? '',
          emoji: data['emoji'] ?? '',
          date: data['date'] ?? '',
          time: data['time'] ?? '',
          priority: data['priority'] ?? '',
          isCompleted: data['isCompleted'] ?? false,
          status: data['status'] ?? 'To-Do',
          firebaseId: doc.id,
        );
        await todoBox.add(todo);
      }
    }
  }

  Future<void> _syncHiveTodoToFirestore(Todo todo) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('tasks')
        .doc(todo.firebaseId);

    final data = {
      'title': todo.title,
      'description': todo.description,
      'emoji': todo.emoji,
      'date': todo.date,
      'time': todo.time,
      'priority': todo.priority,
      'isCompleted': todo.isCompleted,
      'status': todo.status,
    };

    try {
      await docRef.set(data);
    } catch (_) {}
  }

  Future<void> _deleteFromFirestore(String? firebaseId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || firebaseId == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('tasks')
          .doc(firebaseId)
          .delete();
    } catch (_) {}
  }

  void toggleMenu() {
    setState(() {
      showFloatingMenu = !showFloatingMenu;
      showFloatingMenu ? _controller.forward() : _controller.reverse();
    });
  }

  Future<void> _openAddTodo({Todo? existing, int? index}) async {
    if (showFloatingMenu) toggleMenu();

    final newTodo = await showModalBottomSheet<Todo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AddTodo(existingTodo: existing),
    );

    if (newTodo != null) {
      if (index != null) {
        todoBox.putAt(index, newTodo);
      } else {
        todoBox.add(newTodo);
      }
      _syncHiveTodoToFirestore(newTodo);
    }
  }

  void _deleteTodo(int index) {
    final todo = todoBox.getAt(index);
    if (todo != null) {
      _deleteFromFirestore(todo.firebaseId);
      todoBox.deleteAt(index);
    }
  }

  void _changeStatus(int index, String newStatus) {
    final updatedTodo = todoBox.getAt(index);
    if (updatedTodo != null) {
      updatedTodo.status = newStatus;
      updatedTodo.save();
      _syncHiveTodoToFirestore(updatedTodo);
      setState(() {});
    }
  }

  Future<void> _refreshHiveOnly() async {
    setState(() {});
    await Future.delayed(const Duration(milliseconds: 500));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: ValueListenableBuilder(
              valueListenable: todoBox.listenable(),
              builder: (context, Box<Todo> box, _) {
                final todos = box.values
                    .where((t) => t.date == DateFormat.yMMMd().format(selectedDate))
                    .toList();

                final firstDay = DateTime(selectedDate.year, selectedDate.month, 1);
                final lastDay = DateTime(selectedDate.year, selectedDate.month + 1, 0);
                final totalDays = lastDay.day;

                return RefreshWrapper(
                  onRefresh: _refreshHiveOnly,
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left),
                            onPressed: () {
                              setState(() {
                                final now = DateTime.now();
                                final prevMonth = DateTime(selectedDate.year, selectedDate.month - 1);
                                if (prevMonth.year == now.year && prevMonth.month == now.month) {
                                  selectedDate = now;
                                } else {
                                  selectedDate = DateTime(prevMonth.year, prevMonth.month, 1);
                                }
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _scrollToSelectedDate();
                                });
                              });
                            },
                          ),
                          Text(
                            DateFormat.yMMMM().format(selectedDate),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right),
                            onPressed: () {
                              setState(() {
                                final now = DateTime.now();
                                final nextMonth = DateTime(selectedDate.year, selectedDate.month + 1);
                                if (nextMonth.year == now.year && nextMonth.month == now.month) {
                                  selectedDate = now;
                                } else {
                                  selectedDate = DateTime(nextMonth.year, nextMonth.month, 1);
                                }
                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                  _scrollToSelectedDate();
                                });
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 110,
                        child: ListView.builder(
                          controller: _scrollController,
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: totalDays,
                          itemBuilder: (context, index) {
                            final date = DateTime(
                                selectedDate.year, selectedDate.month, index + 1);
                            final dateKey = DateFormat.yMMMd().format(date);
                            final isSelected = DateFormat('yyyy-MM-dd').format(date) ==
                                DateFormat('yyyy-MM-dd').format(selectedDate);

                            final dailyTodos = box.values
                                .where((t) => t.date == dateKey)
                                .toList();
                            final statuses = dailyTodos.map((t) => t.status).toSet();

                            return GestureDetector(
                              onTap: () => setState(() => selectedDate = date),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 6),
                                    child: Container(
                                      width: 60,
                                      padding: const EdgeInsets.symmetric(vertical: 18),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? const Color(0xFFEB5E00)
                                            : const Color(0xFFF7F8F8),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            DateFormat('E').format(date),
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isSelected
                                                  ? Colors.white
                                                  : const Color(0xFF7B6F72),
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            '${date.day}',
                                            style: TextStyle(
                                              color: isSelected
                                                  ? Colors.white
                                                  : Colors.black,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      if (statuses.contains('To-Do'))
                                        dot(Colors.red),
                                      if (statuses.contains('In Progress'))
                                        dot(Colors.amber),
                                      if (statuses.contains('Done'))
                                        dot(Colors.green),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: todos.isEmpty
                            ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/empty_state.png', height: 220),
                            const SizedBox(height: 16),
                          ],
                        )
                            : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: todos.length,
                          itemBuilder: (context, index) {
                            return TaskCard(
                              todo: todos[index],
                              onEdit: () => _openAddTodo(
                                  existing: todos[index], index: index),
                              onDelete: () => _deleteTodo(index),
                              onStatusChange: (status) =>
                                  _changeStatus(index, status),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (showFloatingMenu)
            Positioned.fill(
              child: GestureDetector(
                onTap: toggleMenu,
                child: Container(color: Colors.black.withOpacity(0.3)),
              ),
            ),
          if (showFloatingMenu)
            Positioned(
              bottom: 90,
              right: 20,
              child: FadeTransition(
                opacity: _opacityAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      menuButton('Setup Journal', outlined: true),
                      const SizedBox(height: 10),
                      menuButton('Setup Habit', outlined: true),
                      const SizedBox(height: 10),
                      menuButton('Add List'),
                      const SizedBox(height: 10),
                      menuButton('Add Note'),
                      const SizedBox(height: 10),
                      menuButton('Add Todo', onPressed: _openAddTodo),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFEB5E00),
        onPressed: toggleMenu,
        child: Icon(showFloatingMenu ? Icons.close : Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: BotNav(currentIndex: 2, onTap: (index) {}),
    );
  }

  Widget dot(Color color) => Container(
    width: 6,
    height: 6,
    margin: const EdgeInsets.symmetric(horizontal: 1),
    decoration: BoxDecoration(color: color, shape: BoxShape.circle),
  );

  Widget menuButton(String text,
      {bool outlined = false, VoidCallback? onPressed}) {
    return ElevatedButton(
      onPressed: onPressed ?? () {},
      style: ElevatedButton.styleFrom(
        elevation: 3,
        backgroundColor: outlined ? Colors.white : const Color(0xFFEB5E00),
        foregroundColor: outlined ? const Color(0xFFEB5E00) : Colors.white,
        side: outlined ? const BorderSide(color: Color(0xFFEB5E00)) : null,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
    );
  }
}
