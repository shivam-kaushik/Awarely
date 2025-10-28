import 'package:flutter/material.dart';
import '../../data/models/reminder.dart' as model;

/// Widget for selecting specific days of the week
class DaysOfWeekSelector extends StatelessWidget {
  final List<int>? selectedDays; // 1=Monday, 7=Sunday
  final ValueChanged<List<int>> onChanged;

  const DaysOfWeekSelector({
    super.key,
    required this.selectedDays,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedDays ?? [];
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Repeat On',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
        ),
        const SizedBox(height: 12),
        // Day chips - use Wrap to prevent overflow
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: List.generate(7, (index) {
            final dayNum = index + 1;
            final isSelected = selected.contains(dayNum);

            return _DayChip(
              day: dayNames[index],
              isSelected: isSelected,
              onTap: () {
                final newSelected = List<int>.from(selected);
                if (isSelected) {
                  newSelected.remove(dayNum);
                } else {
                  newSelected.add(dayNum);
                }
                newSelected.sort();
                onChanged(newSelected);
              },
            );
          }),
        ),
        const SizedBox(height: 8),
        // Quick select buttons - use Wrap to prevent overflow
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            TextButton.icon(
              onPressed: () => onChanged([1, 2, 3, 4, 5]),
              icon: const Icon(Icons.work_outline, size: 16),
              label: const Text('Weekdays', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            TextButton.icon(
              onPressed: () => onChanged([6, 7]),
              icon: const Icon(Icons.weekend_outlined, size: 16),
              label: const Text('Weekends', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
            TextButton.icon(
              onPressed: () => onChanged([1, 2, 3, 4, 5, 6, 7]),
              icon: const Icon(Icons.calendar_month, size: 16),
              label: const Text('Every day', style: TextStyle(fontSize: 12)),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DayChip extends StatelessWidget {
  final String day;
  final bool isSelected;
  final VoidCallback onTap;

  const _DayChip({
    required this.day,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).primaryColor
              : Colors.grey.shade100,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).primaryColor
                : Colors.grey.shade300,
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            day,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget for selecting time of day preference
class TimeOfDaySelector extends StatelessWidget {
  final model.TimeOfDay? selectedTimeOfDay;
  final ValueChanged<model.TimeOfDay?> onChanged;

  const TimeOfDaySelector({
    super.key,
    required this.selectedTimeOfDay,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Time of Day',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            if (selectedTimeOfDay != null)
              TextButton(
                onPressed: () => onChanged(null),
                child: const Text('Clear'),
              ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: model.TimeOfDay.values.map((timeOfDay) {
            final isSelected = timeOfDay == selectedTimeOfDay;
            return _TimeOfDayChip(
              timeOfDay: timeOfDay,
              isSelected: isSelected,
              onTap: () => onChanged(timeOfDay),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _TimeOfDayChip extends StatelessWidget {
  final model.TimeOfDay timeOfDay;
  final bool isSelected;
  final VoidCallback onTap;

  const _TimeOfDayChip({
    required this.timeOfDay,
    required this.isSelected,
    required this.onTap,
  });

  String _getIcon() {
    switch (timeOfDay) {
      case model.TimeOfDay.morning:
        return '🌅';
      case model.TimeOfDay.afternoon:
        return '☀️';
      case model.TimeOfDay.evening:
        return '🌆';
      case model.TimeOfDay.night:
        return '🌙';
      case model.TimeOfDay.lateNight:
        return '🌃';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? Theme.of(context).primaryColor.withOpacity(0.1)
          : Colors.grey.shade100,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            border: Border.all(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade300,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _getIcon(),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Text(
                timeOfDay.displayName.split(' ')[0], // Just "Morning" etc.
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? Theme.of(context).primaryColor
                      : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
