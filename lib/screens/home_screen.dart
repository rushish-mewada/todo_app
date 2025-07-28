import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../services/firestore_service.dart';
import '../models/todo.dart';
import '../widgets/add_todo.dart';
import '../widgets/add_note.dart';
import '../widgets/add_habit.dart';
import '../widgets/add_journal.dart';
import '../widgets/add_list.dart';
import '../widgets/task_card.dart';
import '../widgets/habit_card.dart';
import '../widgets/journal_card.dart';
import '../widgets/note_card.dart';
import '../widgets/list_card.dart';
import '../widgets/list_modal.dart';

import '../widgets/bot_nav.dart';
import '../widgets/refresh.dart';
import '../widgets/preview_modal.dart';
import '../widgets/delete_confirmation_modal.dart';
import '../widgets/filter_sheet.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _opacityAnimation;
  bool showFloatingMenu = false;

  late Box<Todo> todoBox;
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";

  int _selectedTabIndex = 0;
  final List<String> _tabTypes = ['To-Do', 'List', 'Habit', 'Journal', 'Note'];
  String? _selectedPriorityFilter;
  String? _selectedStatusFilter;
  String? _selectedSortOption;

  @override
  void initState() {
    super.initState();
    todoBox = Hive.box<Todo>('todos');

    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    _scaleAnimation = CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animationController, curve: Curves.easeInOut));
    _opacityAnimation = Tween<double>(begin: 0, end: 1).animate(_animationController);

    FirestoreService.startConnectivityListener();
    FirestoreService.syncAll();

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
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void toggleMenu() {
    if (mounted) {
      setState(() {
        showFloatingMenu = !showFloatingMenu;
        showFloatingMenu ? _animationController.forward() : _animationController.reverse();
      });
    }
  }

  Future<void> _openAddItemSheet({String? type, Todo? existing, int? index}) async {
    if (showFloatingMenu) toggleMenu();

    final itemType = existing?.type ?? type ?? _tabTypes[_selectedTabIndex];

    Widget builder(BuildContext context) {
      switch (itemType) {
        case 'Note':
          return AddNote(existingNote: existing);
        case 'Habit':
          return AddHabit(existingHabit: existing);
        case 'Journal':
          return AddJournal(existingJournal: existing);
        case 'List':
          return AddList(existingList: existing);
        case 'To-Do':
        default:
          return AddTodo(existingTodo: existing);
      }
    }

    final newItem = await showModalBottomSheet<Todo>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: builder,
    );

    if (newItem != null) {
      if (existing != null && existing.key != null) {
        newItem.needsUpdate = true;
        await todoBox.put(existing.key, newItem);
      } else {
        await todoBox.add(newItem);
      }
      await FirestoreService.syncAll();
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
      todo.isDeleted = true;
      await todo.save();
      await FirestoreService.syncAll();
    }
  }

  void _changeStatus(int index, String newStatus) async {
    final updatedTodo = todoBox.getAt(index);
    if (updatedTodo != null) {
      updatedTodo.status = newStatus;
      updatedTodo.needsUpdate = true;
      await updatedTodo.save();
      await FirestoreService.syncAll();
    }
  }

  Future<void> _refreshHiveOnly() async {
    await FirestoreService.syncAll();
    if (mounted) {
      setState(() {});
    }
  }

  void _showFilterSheet() async {
    final filterData = await showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => FilterSheet(
        initialPriority: _selectedPriorityFilter,
        initialStatus: _selectedStatusFilter,
        initialSortOption: _selectedSortOption,
      ),
    );

    if (filterData != null) {
      setState(() {
        _selectedPriorityFilter = filterData['priority'];
        _selectedStatusFilter = filterData['status'];
        _selectedSortOption = filterData['sort'];
      });
    }
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
          onUpdateAndSave: (updatedTodo, todoKey) async {
            updatedTodo.needsUpdate = true;
            await todoBox.put(todoKey, updatedTodo);
            await FirestoreService.syncAll();
          },
          onDelete: () {
            final allTodos = todoBox.values.toList();
            final originalIndex = allTodos.indexWhere((t) => t.key == todo.key);
            if (originalIndex != -1) {
              _deleteTodo(originalIndex);
            }
          },
          getPriorityColor: _getPriorityColor,
          getPriorityLabel: _getPriorityLabel,
          getStatusColor: _getStatusColor,
        );
      },
    );
  }

  void _showListDetailModal(Todo todo) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ListModal(
          todo: todo,
          onUpdateAndSave: (updatedTodo, todoKey) async {
            updatedTodo.needsUpdate = true;
            await todoBox.put(todoKey, updatedTodo);
            await FirestoreService.syncAll();
          },
          onDelete: () {
            final allTodos = todoBox.values.toList();
            final originalIndex = allTodos.indexWhere((t) => t.key == todo.key);
            if (originalIndex != -1) {
              _deleteTodo(originalIndex);
            }
          },
        );
      },
    );
  }

  Widget _buildTaskList(List<Todo> allTodos) {
    List<Todo> typeSpecificTodos = allTodos.where((todo) {
      bool typeMatch = todo.type == _tabTypes[_selectedTabIndex];
      bool priorityMatch = _selectedPriorityFilter == null || todo.priority == _selectedPriorityFilter;
      bool statusMatch = _selectedStatusFilter == null || todo.status == _selectedStatusFilter;
      return typeMatch && priorityMatch && statusMatch;
    }).toList();

    if (_selectedSortOption == 'Date') {
      typeSpecificTodos.sort((a, b) {
        if (a.date.isEmpty && b.date.isEmpty) return 0;
        if (a.date.isEmpty) return 1;
        if (b.date.isEmpty) return -1;
        try {
          return DateFormat.yMMMd().parse(a.date).compareTo(DateFormat.yMMMd().parse(b.date));
        } catch (e) {
          return 0;
        }
      });
    } else if (_selectedSortOption == 'Priority') {
      final priorityMap = {'High': 3, 'Medium': 2, 'Low': 1};
      typeSpecificTodos.sort((a, b) {
        final priorityA = priorityMap[a.priority] ?? 0;
        final priorityB = priorityMap[b.priority] ?? 0;
        return priorityB.compareTo(priorityA);
      });
    }

    if (typeSpecificTodos.isEmpty) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (_searchText.isEmpty)
            Image.asset('assets/empty_state.png', height: 220),
          if (_searchText.isNotEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Text(
                'No matching tasks found.',
                style: TextStyle(fontSize: 16, color: Colors.black54),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 100, top: 10),
      itemCount: typeSpecificTodos.length,
      itemBuilder: (context, index) {
        final todo = typeSpecificTodos[index];
        final originalIndex = todoBox.values.toList().indexWhere((t) => t.key == todo.key);

        switch (todo.type) {
          case 'To-Do':
            return GestureDetector(
              onTap: () => _showTaskPreviewModal(todo),
              child: TaskCard(
                todo: todo,
                onEdit: () => _openAddItemSheet(existing: todo, index: originalIndex),
                onDelete: () => _deleteTodo(originalIndex),
                onStatusChange: (status) => _changeStatus(originalIndex, status),
              ),
            );
          case 'Habit':
            return HabitCard(
              todo: todo,
              onEdit: () => _openAddItemSheet(existing: todo, index: originalIndex),
              onDelete: () => _deleteTodo(originalIndex),
            );
          case 'Journal':
            return JournalCard(
              todo: todo,
              onEdit: () => _openAddItemSheet(existing: todo, index: originalIndex),
              onDelete: () => _deleteTodo(originalIndex),
            );
          case 'Note':
            return NoteCard(
              todo: todo,
              onEdit: () => _openAddItemSheet(existing: todo, index: originalIndex),
              onDelete: () => _deleteTodo(originalIndex),
            );
          case 'List':
            return ListCard(
              todo: todo,
              onEdit: () => _openAddItemSheet(existing: todo, index: originalIndex),
              onDelete: () => _deleteTodo(originalIndex),
              onTap: () => _showListDetailModal(todo),
            );
          default:
            return Container();
        }
      },
    );
  }

  Widget _buildTabChip(String label, int index) {
    final isSelected = _selectedTabIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedTabIndex = index;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEB5E00) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget menuButton(String text, {bool outlined = false, VoidCallback? onPressed}) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ButtonStyle(
        elevation: MaterialStateProperty.all(3),
        backgroundColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.pressed)) {
            return Colors.white;
          }
          return const Color(0xFFEB5E00);
        }),
        foregroundColor: MaterialStateProperty.resolveWith<Color>((states) {
          if (states.contains(MaterialState.pressed)) {
            return const Color(0xFFEB5E00);
          }
          return Colors.white;
        }),
        side: MaterialStateProperty.resolveWith<BorderSide>((states) {
          return const BorderSide(color: Color(0xFFEB5E00));
        }),
        shape: MaterialStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        padding: MaterialStateProperty.all(
          const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        ),
      ),
      child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                final visibleTodos = box.values.where((todo) => todo.isDeleted != true).toList();
                final filteredTodos = visibleTodos.where((todo) {
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
                        child: Row(
                          children: [
                            Expanded(
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
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20.0),
                        child: Row(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Wrap(
                                  spacing: 8.0,
                                  children: List.generate(_tabTypes.length, (index) {
                                    return _buildTabChip(_tabTypes[index], index);
                                  }),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.sort, color: Color(0xFFEB5E00)),
                              onPressed: _showFilterSheet,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: _buildTaskList(filteredTodos),
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
                child: Container(color: Colors.black.withOpacity(0.6)),
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
                      menuButton('Add Journal', onPressed: () => _openAddItemSheet(type: 'Journal')),
                      const SizedBox(height: 10),
                      menuButton('Add Habit', onPressed: () => _openAddItemSheet(type: 'Habit')),
                      const SizedBox(height: 10),
                      menuButton('Add Note', onPressed: () => _openAddItemSheet(type: 'Note')),
                      const SizedBox(height: 10),
                      menuButton('Add List', onPressed: () => _openAddItemSheet(type: 'List')),
                      const SizedBox(height: 10),
                      menuButton('Add To-Do', onPressed: () => _openAddItemSheet(type: 'To-Do')),
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
}
