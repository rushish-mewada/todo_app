import 'package:flutter/material.dart';

class FilterSheet extends StatefulWidget {
  final String? initialPriority;
  final String? initialStatus;
  final String? initialSortOption;

  const FilterSheet({
    super.key,
    this.initialPriority,
    this.initialStatus,
    this.initialSortOption,
  });

  @override
  State<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<FilterSheet> {
  String? _selectedPriority;
  String? _selectedStatus;
  String? _selectedSortOption;

  @override
  void initState() {
    super.initState();
    _selectedPriority = widget.initialPriority;
    _selectedStatus = widget.initialStatus;
    _selectedSortOption = widget.initialSortOption;
  }

  Widget _buildFilterChip(
      String label, String? groupValue, Function(String?) onSelected) {
    final isSelected = label == groupValue;
    return GestureDetector(
      onTap: () {
        onSelected(isSelected ? null : label);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFEB5E00) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? Colors.transparent : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: const BoxDecoration(
              color: Color(0xFFEB5E00),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: const Center(
              child: Text(
                'Filter & Sort',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sort By',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  children: [
                    _buildFilterChip('Date', _selectedSortOption, (value) {
                      setState(() => _selectedSortOption = value);
                    }),
                    _buildFilterChip('Priority', _selectedSortOption, (value) {
                      setState(() => _selectedSortOption = value);
                    }),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Filter by Priority',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  children: [
                    _buildFilterChip('High', _selectedPriority, (value) {
                      setState(() => _selectedPriority = value);
                    }),
                    _buildFilterChip('Medium', _selectedPriority, (value) {
                      setState(() => _selectedPriority = value);
                    }),
                    _buildFilterChip('Low', _selectedPriority, (value) {
                      setState(() => _selectedPriority = value);
                    }),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Filter by Status',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 12.0,
                  runSpacing: 12.0,
                  children: [
                    _buildFilterChip('To-Do', _selectedStatus, (value) {
                      setState(() => _selectedStatus = value);
                    }),
                    _buildFilterChip('In Progress', _selectedStatus, (value) {
                      setState(() => _selectedStatus = value);
                    }),
                    _buildFilterChip('Completed', _selectedStatus, (value) {
                      setState(() => _selectedStatus = value);
                    }),
                  ],
                ),
                const SizedBox(height: 40),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context,
                            {'priority': null, 'status': null, 'sort': null});
                      },
                      child: const Text(
                        'Clear All',
                        style: TextStyle(color: Color(0xFFEB5E00)),
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEB5E00),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      onPressed: () {
                        final filterData = {
                          'priority': _selectedPriority,
                          'status': _selectedStatus,
                          'sort': _selectedSortOption,
                        };
                        Navigator.pop(context, filterData);
                      },
                      child: const Text('Apply'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
