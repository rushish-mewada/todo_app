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
import '../widgets/preview_modal.dart';
import '../widgets/delete_confirmation_modal.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;
  bool showFloatingMenu = false;

  late Box<Todo> todoBox;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  @override
  void initState() {
    super.initState();
    todoBox = Hive.box<Todo>('todos');
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(_controller);

    _syncFirestoreToHive();

    _searchController.addListener(() {
      if (mounted) {
        setState(() {
          _searchText = _searchController.text.trim();
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
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
    if (mounted) {
      setState(() {
        showFloatingMenu = !showFloatingMenu;
        showFloatingMenu ? _controller.forward() : _controller.reverse();
      });
    }
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

  void _deleteTodo(int index) async {
    final todo = todoBox.getAt(index);
    if (todo == null) return;

    final bool? confirmDelete = await showDialog<bool>(
      context: context,
      builder: (context) => DeleteConfirmationModal(taskTitle: todo.title),
    );

    if (confirmDelete == true) {
      _deleteFromFirestore(todo.firebaseId);
      todoBox.deleteAt(index);
      if (mounted) {
        setState(() {});
      }
    }
  }

  void _changeStatus(int index, String newStatus) {
    final updatedTodo = todoBox.getAt(index);
    if (updatedTodo != null) {
      updatedTodo.status = newStatus;
      updatedTodo.save();
      _syncHiveTodoToFirestore(updatedTodo);
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _refreshHiveOnly() async {
    if (mounted) {
      setState(() {});
    }
    await Future.delayed(const Duration(milliseconds: 500));
  }

  Color _getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return const Color(0xFFEA4335);
      case 'Medium':
        return const Color(0xFFED9611);
      case 'Low':
        return const Color(0xFF24A19C);
      default:
        return Colors.grey;
    }
  }

  String _getPriorityLabel(String priority) {
    switch (priority) {
      case 'High':
        return 'High Priority';
      case 'Medium':
        return 'Medium Priority';
      case 'Low':
        return 'Low Priority';
      default:
        return 'Priority';
    }
  }

  String _getPriorityIcon(String priority) {
    switch (priority) {
      case 'High':
        return '⚠️';
      case 'Medium':
        return '⏳';
      case 'Low':
        return '✅';
      default:
        return '';
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'To-Do':
        return const Color(0xFF218EFD);
      case 'Completed':
        return const Color(0xFF23A26D);
      case 'In Progress':
        return const Color(0xFFF6A221);
      default:
        return Colors.grey;
    }
  }

  void _showTaskPreviewModal(Todo todo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return PreviewModal(
          todo: todo,
          onUpdateAndSave: (updatedTodo) async {
            final allTodos = todoBox.values.toList();
            final originalIndex = allTodos.indexWhere((t) => t.firebaseId == updatedTodo.firebaseId);

            if (originalIndex != -1) {
              await todoBox.putAt(originalIndex, updatedTodo);
              await _syncHiveTodoToFirestore(updatedTodo);
              if (mounted) {
                setState(() {});
              }
            }
          },
          onDelete: () {
            final allTodos = todoBox.values.toList();
            _deleteTodo(allTodos.indexOf(todo));
          },
          getPriorityColor: _getPriorityColor,
          getPriorityLabel: _getPriorityLabel,
          getStatusColor: _getStatusColor,
        );
      },
    );
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
                final allTodos = box.values.toList();
                final filteredTodos = allTodos.where((todo) {
                  return todo.title.toLowerCase().contains(_searchText.toLowerCase()) ||
                      todo.description.toLowerCase().contains(_searchText.toLowerCase());
                }).toList();

                return RefreshWrapper(
                  onRefresh: _refreshHiveOnly,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        child: Row(
                          children: [
                            const Text('Today', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
                            const Spacer(),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            DateFormat('EEE dd MMMM yyyy').format(DateTime.now()),
                            style: const TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(32),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                spreadRadius: 0,
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: 'Search Task',
                              hintStyle: TextStyle(color: Colors.grey[400]),
                              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                              suffixIcon: _searchText.isNotEmpty
                                  ? IconButton(
                                icon: const Icon(Icons.close, color: Colors.grey),
                                onPressed: () {
                                  _searchController.clear();
                                },
                              )
                                  : null,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(32),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(32),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(32),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            filterButton('To-Do', selected: true),
                            const SizedBox(width: 8),
                            filterButton('Habit'),
                            const SizedBox(width: 8),
                            filterButton('Journal'),
                            const SizedBox(width: 8),
                            filterButton('Note'),
                            const Spacer(),
                            const Icon(Icons.filter_alt_outlined, color: Color(0xFFEB5E00)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: filteredTodos.isEmpty
                            ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (_searchText.isEmpty)
                              Image.asset('assets/empty_state.png', height: 220),
                            const SizedBox(height: 16),
                            Text(
                              _searchText.isEmpty ? 'No tasks for today.' : 'No matching tasks found.',
                              style: const TextStyle(fontSize: 16, color: Colors.black54),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                            : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 100),
                          itemCount: filteredTodos.length,
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () => _showTaskPreviewModal(filteredTodos[index]),
                              child: TaskCard(
                                todo: filteredTodos[index],
                                onEdit: () => _openAddTodo(existing: filteredTodos[index], index: allTodos.indexOf(filteredTodos[index])),
                                onDelete: () => _deleteTodo(allTodos.indexOf(filteredTodos[index])),
                                onStatusChange: (status) => _changeStatus(allTodos.indexOf(filteredTodos[index]), status),
                              ),
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
        child: Icon(showFloatingMenu ? Icons.close : Icons.add, color: Colors.white),
        onPressed: toggleMenu,
      ),
      bottomNavigationBar: BotNav(currentIndex: 0, onTap: (index) {}),
    );
  }

  Color getPriorityColor(String priority) {
    switch (priority) {
      case 'High':
        return const Color(0xFFEA4335);
      case 'Medium':
        return const Color(0xFFED9611);
      case 'Low':
        return const Color(0xFF24A19C);
      default:
        return Colors.grey;
    }
  }

  String getPriorityLabel(String priority) {
    switch (priority) {
      case 'High':
        return 'High Priority';
      case 'Medium':
        return 'Medium Priority';
      case 'Low':
        return 'Low Priority';
      default:
        return 'Priority';
    }
  }

  String getPriorityIcon(String priority) {
    switch (priority) {
      case 'High':
        return '⚠️';
      case 'Medium':
        return '⏳';
      case 'Low':
        return '✅';
      default:
        return '';
    }
  }

  Color getStatusColor(String status) {
    switch (status) {
      case 'To-Do':
        return const Color(0xFF218EFD);
      case 'Completed':
        return const Color(0xFF23A26D);
      case 'In Progress':
        return const Color(0xFFF6A221);
      default:
        return Colors.grey;
    }
  }

  Widget filterButton(String label, {bool selected = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFEB5E00) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(
        label,
        style: TextStyle(color: selected ? Colors.white : Colors.black87),
      ),
    );
  }

  Widget menuButton(String text, {bool outlined = false, VoidCallback? onPressed}) {
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
