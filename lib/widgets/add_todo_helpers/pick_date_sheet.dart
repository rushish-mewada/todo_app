import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PickDateSheet extends StatefulWidget {
  final DateTime? initialDate;
  const PickDateSheet({super.key, this.initialDate});

  @override
  State<PickDateSheet> createState() => _PickDateSheetState();
}

class _PickDateSheetState extends State<PickDateSheet> {
  late DateTime _focusedDay;
  late DateTime _selectedDay;

  @override
  void initState() {
    super.initState();
    _focusedDay = widget.initialDate ?? DateTime.now();
    _selectedDay = widget.initialDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final currentMonth = DateFormat.MMMM().format(_focusedDay);
    final currentYear = _focusedDay.year;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Icon(Icons.access_time, size: 20, color: Color(0xFFEB5E00)),
              SizedBox(width: 8),
              Text(
                "Select Due Date",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: () => setState(() {
                  _focusedDay = DateTime(_focusedDay.year, _focusedDay.month - 1, 1);
                }),
              ),
              Text(
                "$currentMonth $currentYear",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: () => setState(() {
                  _focusedDay = DateTime(_focusedDay.year, _focusedDay.month + 1, 1);
                }),
              ),
            ],
          ),
          _buildCalendar(),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, null),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEB5E00),
                    side: const BorderSide(color: Color(0xFFEB5E00)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Back"),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, _selectedDay),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFEB5E00),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Next"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCalendar() {
    final firstDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month, 1);
    final lastDayOfMonth = DateTime(_focusedDay.year, _focusedDay.month + 1, 0);
    final startWeekday = firstDayOfMonth.weekday % 7;
    final daysInMonth = lastDayOfMonth.day;

    final totalCells = startWeekday + daysInMonth;
    final rowCount = (totalCells / 7).ceil();

    List<Widget> rows = [];

    rows.add(Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: const ['M', 'T', 'W', 'T', 'F', 'S', 'S']
          .map((e) => Expanded(
        child: Center(child: Text(e, style: TextStyle(fontWeight: FontWeight.bold))),
      ))
          .toList(),
    ));

    for (int row = 0; row < rowCount; row++) {
      List<Widget> days = [];

      for (int col = 0; col < 7; col++) {
        int dayNum = row * 7 + col - startWeekday + 1;
        DateTime? day;
        if (dayNum > 0 && dayNum <= daysInMonth) {
          day = DateTime(_focusedDay.year, _focusedDay.month, dayNum);
        }

        days.add(Expanded(
          child: GestureDetector(
            onTap: day != null ? () => setState(() => _selectedDay = day!) : null,
            child: Container(
              margin: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: day != null && _isSameDay(day, _selectedDay) ? const Color(0xFFEB5E00) : null,
                borderRadius: BorderRadius.circular(8),
              ),
              height: 40,
              alignment: Alignment.center,
              child: Text(
                day != null ? '${day.day}' : '',
                style: TextStyle(
                  color: day != null && _isSameDay(day, _selectedDay)
                      ? Colors.white
                      : (day != null ? Colors.black : Colors.transparent),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ));
      }

      rows.add(Row(children: days));
    }

    return Column(children: rows);
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
