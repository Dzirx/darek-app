import 'package:flutter/material.dart';

class CalendarFilters extends StatelessWidget {
  final String? selectedFilter;
  final Function(String?) onFilterChanged;

  const CalendarFilters({
    Key? key,
    required this.selectedFilter,
    required this.onFilterChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Wrap(
        spacing: 8,
        children: [
          FilterChip(
            label: const Text('Dziś'),
            selected: selectedFilter == 'today',
            onSelected: (selected) => onFilterChanged(selected ? 'today' : null),
          ),
          FilterChip(
            label: const Text('Ten tydzień'),
            selected: selectedFilter == 'week',
            onSelected: (selected) => onFilterChanged(selected ? 'week' : null),
          ),
          FilterChip(
            label: const Text('Przyszłe'),
            selected: selectedFilter == 'upcoming',
            onSelected: (selected) => onFilterChanged(selected ? 'upcoming' : null),
          ),
        ],
      ),
    );
  }
}