import 'package:flutter/material.dart';

import '../../data/models/reminder.dart';

/// Reminder card widget for displaying in list
class ReminderCard extends StatelessWidget {
  final Reminder reminder;
  final VoidCallback? onTap;
  final Function(bool)? onToggle;
  final VoidCallback? onDelete;

  const ReminderCard({
    super.key,
    required this.reminder,
    this.onTap,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header row
              Row(
                children: [
                  // Status icon
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: reminder.enabled ? Colors.green : Colors.grey,
                      shape: BoxShape.circle,
                    ),
                  ),

                  const SizedBox(width: 12),

                  // Context icons
                  ...reminder.getContextIcons().map((icon) {
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(icon, style: const TextStyle(fontSize: 16)),
                    );
                  }),

                  const Spacer(),

                  // Actions
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit_outlined),
                        onPressed: onTap,
                        tooltip: 'Edit reminder',
                        iconSize: 20,
                      ),
                      Switch(
                        value: reminder.enabled,
                        onChanged: onToggle,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline),
                        onPressed: onDelete,
                        color: Colors.red,
                        iconSize: 20,
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Reminder text
              Text(
                reminder.text,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      decoration: reminder.enabled
                          ? TextDecoration.none
                          : TextDecoration.lineThrough,
                    ),
              ),

              const SizedBox(height: 8),

              // Context description
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reminder.getContextDescription(),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                  ),
                  // Show next occurrence for recurring reminders
                  if (reminder.isRecurring && reminder.timeAt != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.next_plan,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Next: ${_formatNextOccurrence(reminder)}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                  // Show constant reminder indicator
                  if (reminder.keepRemindingUntilCompleted) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.repeat,
                          size: 14,
                          color: Colors.orange[700],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Will keep reminding until completed',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(
                                color: Colors.orange[700],
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),

              // Trigger count
              if (reminder.triggerCount > 0) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 14,
                      color: Colors.grey[600],
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Triggered ${reminder.triggerCount} time${reminder.triggerCount > 1 ? 's' : ''}',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatNextOccurrence(Reminder reminder) {
    if (reminder.timeAt == null) return 'Unknown';
    
    final now = DateTime.now();
    final next = reminder.timeAt!;
    
    // If next occurrence is today
    if (next.year == now.year && next.month == now.month && next.day == now.day) {
      final hour = next.hour > 12 ? next.hour - 12 : (next.hour == 0 ? 12 : next.hour);
      final minute = next.minute.toString().padLeft(2, '0');
      final period = next.hour >= 12 ? 'PM' : 'AM';
      return 'Today at $hour:$minute $period';
    }
    
    // If next occurrence is tomorrow
    final tomorrow = now.add(const Duration(days: 1));
    if (next.year == tomorrow.year && next.month == tomorrow.month && next.day == tomorrow.day) {
      final hour = next.hour > 12 ? next.hour - 12 : (next.hour == 0 ? 12 : next.hour);
      final minute = next.minute.toString().padLeft(2, '0');
      final period = next.hour >= 12 ? 'PM' : 'AM';
      return 'Tomorrow at $hour:$minute $period';
    }
    
    // Otherwise show date
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final hour = next.hour > 12 ? next.hour - 12 : (next.hour == 0 ? 12 : next.hour);
    final minute = next.minute.toString().padLeft(2, '0');
    final period = next.hour >= 12 ? 'PM' : 'AM';
    return '${dayNames[next.weekday - 1]}, ${months[next.month - 1]} ${next.day} at $hour:$minute $period';
  }
}
