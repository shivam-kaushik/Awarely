import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/reminder_provider.dart';
import '../../core/services/weekly_insights_service.dart';
import '../../data/repositories/reminder_repository.dart';

/// Analytics screen showing completion statistics and weekly insights
class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  WeeklyInsightsService? _insightsService;
  Map<String, dynamic>? _weeklyTrends;
  List<Map<String, dynamic>>? _insights;
  bool _loadingInsights = true;

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() => _loadingInsights = true);
    try {
      final repository = ReminderRepository();
      _insightsService = WeeklyInsightsService(repository);
      
      final trends = await _insightsService!.getWeeklyCompletionTrends();
      final generatedInsights = await _insightsService!.generateInsights();
      
      if (mounted) {
        setState(() {
          _weeklyTrends = trends;
          _insights = generatedInsights;
          _loadingInsights = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading insights: $e');
      if (mounted) {
        setState(() => _loadingInsights = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInsights,
            tooltip: 'Refresh insights',
          ),
        ],
      ),
      body: Consumer<ReminderProvider>(
        builder: (context, reminderProvider, child) {
          final stats = reminderProvider.statistics;

          if (stats == null) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Completion rate card
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Text(
                          '${stats['completionRate'] ?? 0}%',
                          style: Theme.of(context).textTheme.displayLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Completion Rate',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Stats grid
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    _buildStatCard(
                      context,
                      'Total Reminders',
                      '${stats['totalReminders'] ?? 0}',
                      Icons.notifications_rounded,
                      Colors.blue,
                    ),
                    _buildStatCard(
                      context,
                      'Active',
                      '${stats['activeReminders'] ?? 0}',
                      Icons.check_circle_rounded,
                      Colors.green,
                    ),
                    _buildStatCard(
                      context,
                      'Completed',
                      '${stats['completedEvents'] ?? 0}',
                      Icons.done_all_rounded,
                      Colors.purple,
                    ),
                    _buildStatCard(
                      context,
                      'Total Events',
                      '${stats['totalEvents'] ?? 0}',
                      Icons.timeline_rounded,
                      Colors.orange,
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Insights
                Text(
                  'Insights',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                // Weekly Trends Section
                if (_loadingInsights)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else ...[
                  if (_weeklyTrends != null) ...[
                    _buildWeeklyTrendsCard(context, _weeklyTrends!),
                    const SizedBox(height: 16),
                  ],
                  
                  if (_insights != null && _insights!.isNotEmpty) ...[
                    Text(
                      'Insights',
                      style: Theme.of(
                        context,
                      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    ..._insights!.map((insight) => _buildInsightCard(
                      context,
                      insight['title'] as String,
                      insight['description'] as String,
                      _getInsightIcon(insight['icon'] as String),
                      insight['type'] as String,
                    )),
                  ],
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildWeeklyTrendsCard(BuildContext context, Map<String, dynamic> trends) {
    final trendsList = trends['trends'] as List;
    final averageRate = trends['averageCompletionRate'] as int;
    final trendValue = trends['trend'] as int;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Weekly Trends',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                if (trendValue != 0)
                  Chip(
                    avatar: Icon(
                      trendValue > 0 ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                    ),
                    label: Text(
                      '${trendValue > 0 ? "+" : ""}$trendValue%',
                      style: TextStyle(
                        color: trendValue > 0 ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            if (trendsList.isEmpty)
              const Text('Not enough data yet. Keep using reminders to see trends!')
            else ...[
              Text(
                'Average: $averageRate%',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              // Simple bar chart
              ...trendsList.take(4).map((week) {
                final rate = week['completionRate'] as int;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            week['week'] as String,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                          Text(
                            '$rate%',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: rate / 100,
                          minHeight: 8,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            rate >= 70 ? Colors.green : rate >= 50 ? Colors.orange : Colors.red,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ],
          ],
        ),
      ),
    );
  }

  IconData _getInsightIcon(String iconString) {
    switch (iconString) {
      case '📈':
        return Icons.trending_up;
      case '📉':
        return Icons.trending_down;
      case '⏰':
        return Icons.access_time;
      case '⭐':
        return Icons.star;
      case '💪':
        return Icons.fitness_center;
      default:
        return Icons.lightbulb;
    }
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightCard(
    BuildContext context,
    String title,
    String description,
    IconData icon,
    String type,
  ) {
    Color backgroundColor;
    Color iconColor;
    
    switch (type) {
      case 'positive':
        backgroundColor = Colors.green.withOpacity(0.1);
        iconColor = Colors.green;
        break;
      case 'warning':
        backgroundColor = Colors.orange.withOpacity(0.1);
        iconColor = Colors.orange;
        break;
      default:
        backgroundColor = Theme.of(context).colorScheme.primary.withOpacity(0.1);
        iconColor = Theme.of(context).colorScheme.primary;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: backgroundColor,
          child: Icon(icon, color: iconColor),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
      ),
    );
  }
}
