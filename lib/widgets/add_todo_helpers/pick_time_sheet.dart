import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PickTimeSheet extends StatefulWidget {
  final TimeOfDay? initialTime;
  const PickTimeSheet({super.key, this.initialTime});

  @override
  State<PickTimeSheet> createState() => _PickTimeSheetState();
}

class _PickTimeSheetState extends State<PickTimeSheet> with TickerProviderStateMixin {
  late TimeOfDay? _selectedTime;
  bool is12HourFormat = true;
  String selectedTimezone = 'Indian Standard Time (UTC+05:30)';

  final List<String> timezones = [
    'Indian Standard Time (UTC+05:30)',
    'Eastern Time (UTC-05:00)',
    'Central European Time (UTC+01:00)',
    'Pacific Time (UTC-08:00)',
  ];

  final List<TimeOfDay> timeSlots = List.generate(
    20,
        (i) => TimeOfDay(hour: 9 + (i ~/ 2), minute: (i % 2) * 30),
  );

  String _formatTime(TimeOfDay time) {
    final now = DateTime.now();
    final dt = DateTime(now.year, now.month, now.day, time.hour, time.minute);
    return DateFormat(is12HourFormat ? 'hh:mm a' : 'HH:mm').format(dt);
  }

  @override
  void initState() {
    super.initState();
    _selectedTime = null; // Initially none selected
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final screenWidth = MediaQuery.of(context).size.width;
    final totalHorizontalPadding = 40.0;
    final gapBetween = 8.0;
    final availableWidth = screenWidth - totalHorizontalPadding - gapBetween;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
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
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('EEEE').format(now),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(DateFormat('MMM dd, yyyy').format(now),
                      style: const TextStyle(color: Colors.black54, fontSize: 14)),
                ],
              ),
              ToggleButtons(
                isSelected: [is12HourFormat, !is12HourFormat],
                onPressed: (index) => setState(() => is12HourFormat = index == 0),
                borderRadius: BorderRadius.circular(8),
                selectedColor: Colors.white,
                fillColor: const Color(0xFFEB5E00),
                color: Colors.black,
                textStyle: const TextStyle(fontSize: 14),
                constraints: const BoxConstraints(minHeight: 32, minWidth: 48),
                children: const [Text("12h"), Text("24h")],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: Colors.grey),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.language, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedTimezone,
                    isExpanded: true,
                    icon: const Icon(Icons.keyboard_arrow_down),
                    items: timezones.map((zone) {
                      return DropdownMenuItem(
                        value: zone,
                        child: Text(zone, style: const TextStyle(fontSize: 14)),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedTimezone = value);
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 320,
            child: ListView.builder(
              itemCount: timeSlots.length,
              itemBuilder: (context, index) {
                final time = timeSlots[index];
                final formatted = _formatTime(time);
                final isSelected = _selectedTime == time;

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: ClipRect(
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => setState(() => _selectedTime = time),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                              width: isSelected
                                  ? availableWidth * 0.5
                                  : availableWidth + gapBetween,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: isSelected ? Colors.black87 : const Color(0xFFF1F1F1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                formatted,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            transitionBuilder: (child, animation) => SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(1, 0),
                                end: Offset.zero,
                              ).animate(animation),
                              child: FadeTransition(opacity: animation, child: child),
                            ),
                            child: isSelected
                                ? Container(
                              key: ValueKey("confirm_$index"),
                              width: availableWidth * 0.5,
                              padding: const EdgeInsets.only(left: 8),
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context, time),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFEB5E00),
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                child: const Text('Confirm',
                                    style: TextStyle(color: Colors.white, fontSize: 14)),
                              ),
                            )
                                : const SizedBox(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
