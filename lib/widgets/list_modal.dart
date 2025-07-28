import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/todo.dart';

class ListItem {
  String text;
  bool isChecked;

  ListItem({required this.text, this.isChecked = false});

  Map<String, dynamic> toJson() => {
    'text': text,
    'checked': isChecked,
  };

  factory ListItem.fromJson(Map<String, dynamic> json) {
    return ListItem(
      text: json['text'] as String,
      isChecked: json['checked'] as bool,
    );
  }
}

class ListModal extends StatefulWidget {
  final Todo todo;
  final Future<void> Function(Todo updatedTodo, dynamic todoKey) onUpdateAndSave;
  final VoidCallback onDelete;

  const ListModal({
    super.key,
    required this.todo,
    required this.onUpdateAndSave,
    required this.onDelete,
  });

  @override
  State<ListModal> createState() => _ListModalState();
}

class _ListModalState extends State<ListModal> {
  late String _listTitle;
  late String _listDescription;
  late List<ListItem> _listItems;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _listTitle = widget.todo.title;
    _listDescription = widget.todo.description;
    _listItems = _parseListContent(widget.todo.content ?? '');
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<ListItem> _parseListContent(String content) {
    if (content.isEmpty) {
      return [];
    }
    try {
      final List<dynamic> decoded = jsonDecode(content);
      return decoded.map((item) => ListItem.fromJson(item as Map<String, dynamic>)).toList();
    } catch (e) {
      return [ListItem(text: content, isChecked: false)];
    }
  }

  void _toggleItemChecked(int index) async {
    setState(() {
      _listItems[index].isChecked = !_listItems[index].isChecked;
    });
    await _saveChanges();
  }

  Future<void> _saveChanges() async {
    final updatedContent = jsonEncode(_listItems.map((item) => item.toJson()).toList());
    final updatedTodo = Todo(
      title: _listTitle,
      description: _listDescription,
      type: widget.todo.type,
      content: updatedContent,
      date: widget.todo.date,
      time: widget.todo.time,
      priority: widget.todo.priority,
      isCompleted: widget.todo.isCompleted,
      status: widget.todo.status,
      firebaseId: widget.todo.firebaseId,
      isDeleted: widget.todo.isDeleted,
      needsUpdate: true,
      emoji: widget.todo.emoji,
      frequency: widget.todo.frequency,
      streak: widget.todo.streak,
      lastCompletedDate: widget.todo.lastCompletedDate,
      mood: widget.todo.mood,
    );
    await widget.onUpdateAndSave(updatedTodo, widget.todo.firebaseId);
  }

  @override
  Widget build(BuildContext context) {
    const double itemHeight = 56.0;
    const int maxItemsBeforeScroll = 5;
    final double maxListHeight = itemHeight * maxItemsBeforeScroll;

    final double listHeight = (_listItems.length <= maxItemsBeforeScroll)
        ? (_listItems.length * itemHeight)
        : maxListHeight;

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      backgroundColor: Colors.white,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              spreadRadius: 0,
              blurRadius: 17,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _listTitle,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontFamily: 'SFProDisplay',
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                      color: const Color(0xFF333333),
                    ),
                  ),
                  if (_listDescription.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _listDescription,
                        style: const TextStyle(
                          fontFamily: 'SFProDisplay',
                          fontSize: 15,
                          color: Color(0xFF767E8C),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const Divider(height: 0, thickness: 0.5, color: Color(0xFFE0E0E0)),
            SizedBox(
              height: listHeight,
              child: Scrollbar(
                thumbVisibility: true,
                controller: _scrollController,
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                  itemCount: _listItems.length,
                  itemBuilder: (context, index) {
                    final item = _listItems[index];
                    return CheckboxListTile(
                      title: Text(
                        item.text,
                        style: TextStyle(
                          decoration: item.isChecked ? TextDecoration.lineThrough : TextDecoration.none,
                          color: item.isChecked ? Colors.grey : Colors.black,
                        ),
                      ),
                      value: item.isChecked,
                      onChanged: (bool? newValue) {
                        _toggleItemChecked(index);
                      },
                      controlAffinity: ListTileControlAffinity.leading,
                      activeColor: const Color(0xFFEB5E00),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEB5E00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
