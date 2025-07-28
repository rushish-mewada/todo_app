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
      isChecked: json['checked'] as bool? ?? false,
    );
  }
}

class AddList extends StatefulWidget {
  final Todo? existingList;

  const AddList({super.key, this.existingList});

  @override
  State<AddList> createState() => _AddListState();
}

class _AddListState extends State<AddList> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final List<TextEditingController> _listItemControllers = [];
  final List<bool> _listItemCheckedStates = [];

  final FocusNode _titleFocusNode = FocusNode();
  final FocusNode _descriptionFocusNode = FocusNode();
  final List<FocusNode> _listItemFocusNodes = [];
  TextEditingController? _currentFocusedController;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.existingList?.title ?? '';
    _descriptionController.text = widget.existingList?.description ?? '';

    _titleFocusNode.addListener(_onFocusChange);
    _descriptionFocusNode.addListener(_onFocusChange);

    if (widget.existingList != null &&
        (widget.existingList!.content?.isNotEmpty == true)) {
      try {
        final List<dynamic> items = jsonDecode(widget.existingList!.content!);
        for (var itemMap in items) {
          final listItem = ListItem.fromJson(itemMap as Map<String, dynamic>);
          _addListItemField(text: listItem.text, isChecked: listItem.isChecked);
        }
      } catch (e) {
        _addListItemField(text: widget.existingList!.content!);
      }
    }

    if (_listItemControllers.isEmpty) {
      _addListItemField();
    }
  }

  void _onFocusChange() {
    if (_titleFocusNode.hasFocus) {
      _currentFocusedController = _titleController;
    } else if (_descriptionFocusNode.hasFocus) {
      _currentFocusedController = _descriptionController;
    } else {
      for (int i = 0; i < _listItemFocusNodes.length; i++) {
        if (_listItemFocusNodes[i].hasFocus) {
          _currentFocusedController = _listItemControllers[i];
          return;
        }
      }
      _currentFocusedController = null;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _titleFocusNode.removeListener(_onFocusChange);
    _descriptionFocusNode.removeListener(_onFocusChange);
    _titleFocusNode.dispose();
    _descriptionFocusNode.dispose();
    _scrollController.dispose();
    for (var controller in _listItemControllers) {
      controller.dispose();
    }
    for (var focusNode in _listItemFocusNodes) {
      focusNode.removeListener(_onFocusChange);
      focusNode.dispose();
    }
    super.dispose();
  }

  void _addListItemField({String text = '', bool isChecked = false}) {
    setState(() {
      _listItemControllers.add(TextEditingController(text: text));
      final focusNode = FocusNode();
      focusNode.addListener(_onFocusChange);
      _listItemFocusNodes.add(focusNode);
      _listItemCheckedStates.add(isChecked);
    });
  }

  void _removeListItemField(int index) {
    if (_listItemControllers.length <= 1) return;

    setState(() {
      _listItemControllers[index].dispose();
      _listItemControllers.removeAt(index);
      _listItemFocusNodes[index].removeListener(_onFocusChange);
      _listItemFocusNodes[index].dispose();
      _listItemFocusNodes.removeAt(index);
      _listItemCheckedStates.removeAt(index);
    });
  }

  void _insertEmoji(String emoji) {
    if (_currentFocusedController == null) return;

    final controller = _currentFocusedController!;
    final text = controller.text;
    final selection = controller.selection;
    final newText = text.replaceRange(selection.start, selection.end, emoji);
    controller.text = newText;
    controller.selection = selection.copyWith(
      baseOffset: selection.start + emoji.length,
      extentOffset: selection.start + emoji.length,
    );
  }

  void _saveList() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final List<Map<String, dynamic>> listItemsToSave = [];
    for (int i = 0; i < _listItemControllers.length; i++) {
      final text = _listItemControllers[i].text.trim();
      if (text.isNotEmpty) {
        listItemsToSave.add(ListItem(
          text: text,
          isChecked: _listItemCheckedStates[i],
        ).toJson());
      }
    }

    final newTodo = Todo(
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      type: 'List',
      content: jsonEncode(listItemsToSave),
      date: widget.existingList?.date ?? '',
      time: widget.existingList?.time ?? '',
      priority: widget.existingList?.priority ?? '',
      isCompleted: widget.existingList?.isCompleted ?? false,
      status: widget.existingList?.status ?? 'To-Do',
      firebaseId: widget.existingList?.firebaseId,
      isDeleted: widget.existingList?.isDeleted ?? false,
      needsUpdate: widget.existingList?.needsUpdate ?? false,
      emoji: widget.existingList?.emoji ?? '',
      frequency: widget.existingList?.frequency,
      streak: widget.existingList?.streak ?? 0,
      lastCompletedDate: widget.existingList?.lastCompletedDate ?? '',
      mood: widget.existingList?.mood ?? '',
    );

    Navigator.of(context).pop(newTodo);
  }

  @override
  Widget build(BuildContext context) {
    const double listItemHeight = 70.0;
    const int maxVisibleItems = 3;
    final double maxListHeight = listItemHeight * maxVisibleItems;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(25.0)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                decoration: const BoxDecoration(
                  color: Color(0xFFEB5E00),
                  borderRadius:
                  BorderRadius.vertical(top: Radius.circular(25.0)),
                ),
                child: Text(
                  widget.existingList == null ? 'New List' : 'Edit List',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextFormField(
                        controller: _titleController,
                        focusNode: _titleFocusNode,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                        decoration: const InputDecoration(
                          hintText: 'Eg : Tasks for Today',
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter a title';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: _descriptionController,
                        focusNode: _descriptionFocusNode,
                        maxLines: 3,
                        style: const TextStyle(fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: 'Description',
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                        ),
                        textCapitalization: TextCapitalization.sentences,
                      ),
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxHeight: _listItemControllers.length > maxVisibleItems
                              ? maxListHeight
                              : double.infinity,
                        ),
                        child: Scrollbar(
                          thumbVisibility: true,
                          controller: _scrollController,
                          child: ListView.builder(
                            controller: _scrollController,
                            shrinkWrap: true,
                            physics: _listItemControllers.length > maxVisibleItems
                                ? const AlwaysScrollableScrollPhysics()
                                : const NeverScrollableScrollPhysics(),
                            itemCount: _listItemControllers.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 16.0),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextFormField(
                                        controller: _listItemControllers[index],
                                        focusNode: _listItemFocusNodes[index],
                                        decoration: InputDecoration(
                                          hintText: 'List Item ${index + 1}',
                                          border: const OutlineInputBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(10.0)),
                                            borderSide: BorderSide.none,
                                          ),
                                          filled: true,
                                          fillColor: const Color(0xFFF0F0F0),
                                          contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 15),
                                        ),
                                      ),
                                    ),
                                    if (_listItemControllers.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                                        onPressed: () => _removeListItemField(index),
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _addListItemField,
                        icon: const Icon(Icons.add_circle_outline,
                            color: Color(0xFFEB5E00)),
                        label: const Text(
                          'Add Item',
                          style: TextStyle(
                              color: Color(0xFFEB5E00),
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _saveList,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFFEB5E00),
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: const Icon(Icons.send,
                                color: Colors.white, size: 24),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Divider(
                          height: 1, thickness: 1, color: Color(0xFFE0E0E0)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          GestureDetector(onTap: () => _insertEmoji('😀'), child: const Text('😀', style: TextStyle(fontSize: 28))),
                          GestureDetector(onTap: () => _insertEmoji('😂'), child: const Text('😂', style: TextStyle(fontSize: 28))),
                          GestureDetector(onTap: () => _insertEmoji('😇'), child: const Text('😇', style: TextStyle(fontSize: 28))),
                          GestureDetector(onTap: () => _insertEmoji('😍'), child: const Text('😍', style: TextStyle(fontSize: 28))),
                          GestureDetector(onTap: () => _insertEmoji('🙌'), child: const Text('🙌', style: TextStyle(fontSize: 28))),
                          GestureDetector(onTap: () => _insertEmoji('👏'), child: const Text('👏', style: TextStyle(fontSize: 28))),
                          GestureDetector(onTap: () => _insertEmoji('🥶'), child: const Text('🥶', style: TextStyle(fontSize: 28))),
                          GestureDetector(onTap: () => _insertEmoji('✌️'), child: const Text('✌️', style: TextStyle(fontSize: 28))),
                        ],
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
