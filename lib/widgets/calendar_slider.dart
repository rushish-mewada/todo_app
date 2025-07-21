import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import '../models/todo.dart';
import 'package:google_fonts/google_fonts.dart';

class CalendarSlider extends StatefulWidget {
  final Function(DateTime) onDateSelected;
  final DateTime selectedDate;

  const CalendarSlider({
    Key? key,
    required this.onDateSelected,
    required this.selectedDate,
  }) : super(key: key);

  @override
  State<CalendarSlider> createState() => _CalendarSliderState();
}

class _CalendarSliderState extends State<CalendarSlider> {
  final ScrollController _scrollController = ScrollController();
  late Box<Todo> todoBox;

  @override
  void initState() {
    super.initState();
    todoBox = Hive.box<Todo>('todos');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate();
    });
  }

  void _scrollToSelectedDate() {
    final index = widget.selectedDate.difference(DateTime.now()).inDays;
    _scrollController.animateTo(
      (index.clamp(0, 29)) * 70.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    final daysToShow = List.generate(30, (i) => today.add(Duration(days: i)));

    return Container(
      color: const Color(0xFFF7F8F8),
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: SizedBox(
        height: 100,
        child: ListView.builder(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          itemCount: daysToShow.length,
          itemBuilder: (context, index) {
            final date = daysToShow[index];

            final isSelected = DateTime(date.year, date.month, date.day)
                .isAtSameMomentAs(DateTime(widget.selectedDate.year,
                widget.selectedDate.month, widget.selectedDate.day));

            final bgColor = isSelected
                ? const Color(0xFFFFA726)
                : Colors.white;

            final textColor = isSelected
                ? Colors.white
                : const Color(0xFF7B6F72);

            return GestureDetector(
              onTap: () => widget.onDateSelected(date),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 6),
                width: 60,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                    BoxShadow(
                      color: Colors.orange.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    )
                  ]
                      : [],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      DateFormat('EEE').format(date),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('d').format(date),
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
