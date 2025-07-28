import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/todo.dart';

class AddJournal extends StatefulWidget {
  final Todo? existingJournal;

  const AddJournal({super.key, this.existingJournal});

  @override
  State<AddJournal> createState() => _AddJournalState();
}

class _AddJournalState extends State<AddJournal> {
  final TextEditingController titleController = TextEditingController();
  final TextEditingController contentController = TextEditingController();
  String selectedMood = '';

  final List<String> moods = ['😊', '😄', '😐', '😢', '😠'];

  @override
  void initState() {
    super.initState();
    if (widget.existingJournal != null) {
      titleController.text = widget.existingJournal!.title;
      contentController.text = widget.existingJournal!.content ?? '';
      selectedMood = widget.existingJournal!.mood ?? '';
    } else {
      // Pre-fill title with today's date for new entries
      titleController.text = DateFormat('MMMM dd, yyyy').format(DateTime.now());
    }
  }

  void _handleSubmit() {
    final title = titleController.text.trim();
    final content = contentController.text.trim();

    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Journal content cannot be empty')),
      );
      return;
    }

    final journalToReturn = Todo(
      title: title.isEmpty ? DateFormat('MMMM dd, yyyy').format(DateTime.now()) : title,
      content: content,
      mood: selectedMood,
      type: 'Journal',
      date: DateFormat.yMMMd().format(DateTime.now()),
      // --- Default values for unused fields ---
      description: '',
      emoji: '',
      time: '',
      priority: '',
      status: '',
    );

    Navigator.pop(context, journalToReturn);
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
                    widget.existingJournal == null ? 'New Journal Entry' : 'Edit Journal Entry',
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: titleController,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      decoration: const InputDecoration(
                        hintText: 'Entry Title',
                        border: InputBorder.none,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text('How are you feeling today?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: moods.map((mood) {
                        final isSelected = mood == selectedMood;
                        return GestureDetector(
                          onTap: () => setState(() => selectedMood = mood),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFFEB5E00).withOpacity(0.2) : Colors.transparent,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              mood,
                              style: const TextStyle(fontSize: 32),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: contentController,
                      maxLines: 10,
                      style: const TextStyle(fontSize: 16),
                      decoration: const InputDecoration(
                        hintText: 'Write about your day...',
                        border: InputBorder.none,
                      ),
                      textCapitalization: TextCapitalization.sentences,
                    ),
                    const SizedBox(height: 20),
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
