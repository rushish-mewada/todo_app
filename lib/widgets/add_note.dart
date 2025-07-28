import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/todo.dart';

class AddNote extends StatefulWidget {
  final Todo? existingNote;

  const AddNote({super.key, this.existingNote});

  @override
  State<AddNote> createState() => _AddNoteState();
}

class _AddNoteState extends State<AddNote> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  final FocusNode titleFocusNode = FocusNode();
  final FocusNode contentFocusNode = FocusNode();
  String selectedEmoji = '';

  final List<String> emojis = ['📝', '💡', '📌', '📎', '🔗', '🧠', '💭', '🤔'];

  @override
  void initState() {
    super.initState();
    if (widget.existingNote != null) {
      titleController.text = widget.existingNote!.title;
      contentController.text = widget.existingNote!.content ?? '';
      selectedEmoji = widget.existingNote!.emoji;
    }
  }

  void insertEmojiAtCursor(String emoji) {
    TextEditingController controller;
    if (titleFocusNode.hasFocus) {
      controller = titleController;
    } else if (contentFocusNode.hasFocus) {
      controller = contentController;
    } else {
      controller = contentController;
    }

    final text = controller.text;
    final selection = controller.selection;
    final newText = text.replaceRange(selection.start, selection.end, emoji);
    final newPosition = selection.start + emoji.length;

    controller.text = newText;
    controller.selection = TextSelection.fromPosition(
      TextPosition(offset: newPosition),
    );

    setState(() {
      selectedEmoji = emoji;
    });
  }

  void _handleSubmit() {
    final title = titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Title cannot be empty')),
      );
      return;
    }

    final noteToReturn = Todo(
      title: title,
      content: contentController.text.trim(),
      date: DateFormat.yMMMd().format(DateTime.now()),
      type: 'Note',
      description: '',
      emoji: selectedEmoji.isNotEmpty ? selectedEmoji : '📝',
      time: '',
      priority: '',
      status: '',
    );

    Navigator.pop(context, noteToReturn);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: const BoxDecoration(
                  color: Color(0xFFEB5E00),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Center(
                  child: Text(
                    widget.existingNote == null ? 'New Note' : 'Edit Note',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.notes_rounded, color: Colors.grey),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: titleController,
                            focusNode: titleFocusNode,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            decoration: const InputDecoration(
                              hintText: 'Note Title',
                              border: InputBorder.none,
                            ),
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                      ],
                    ),
                    const Divider(),
                    TextField(
                      controller: contentController,
                      focusNode: contentFocusNode,
                      minLines: 4,
                      maxLines: 10,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Start writing your note...',
                        border: InputBorder.none,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: emojis.map((emoji) {
                        final isSelected = emoji == selectedEmoji;
                        return GestureDetector(
                          onTap: () => insertEmojiAtCursor(emoji),
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFEB5E00).withOpacity(0.2) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: _handleSubmit,
                        child: Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: Color(0xFFEB5E00),
                          ),
                          padding: const EdgeInsets.all(10),
                          child: const Icon(Icons.send, color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
