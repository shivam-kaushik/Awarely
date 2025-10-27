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
              Text(
                reminder.getContextDescription(),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
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
}
