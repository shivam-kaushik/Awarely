import 'package:flutter/material.dart';

import '../../data/models/reminder.dart';
import '../../core/services/smart_bundling_service.dart';
import 'reminder_card.dart';

/// Widget for displaying a group of reminders with context header
class ContextGroupCard extends StatelessWidget {
  final String contextTitle;
  final List<Reminder> reminders;
  final String? contextIcon;
  final Function(Reminder)? onReminderTap;
  final Function(String, bool)? onToggle;
  final Function(String)? onDelete;

  const ContextGroupCard({
    super.key,
    required this.contextTitle,
    required this.reminders,
    this.contextIcon,
    this.onReminderTap,
    this.onToggle,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (reminders.isEmpty) {
      return const SizedBox.shrink();
    }

    final icon = contextIcon != null ? contextIcon! : SmartBundlingService.getContextIcon(contextTitle);
    final description = SmartBundlingService.getContextDescription(
      contextTitle,
      reminders,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Context header
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Text(
                icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contextTitle,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    if (description.isNotEmpty)
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey[600],
                            ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Reminders in this group
        ...reminders.map((reminder) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ReminderCard(
              reminder: reminder,
              onTap: onReminderTap != null
                  ? () => onReminderTap!(reminder)
                  : null,
              onToggle: onToggle != null
                  ? (enabled) => onToggle!(reminder.id, enabled)
                  : null,
              onDelete: onDelete != null ? () => onDelete!(reminder.id) : null,
            ),
          );
        }),

        const SizedBox(height: 16),
      ],
    );
  }
}

