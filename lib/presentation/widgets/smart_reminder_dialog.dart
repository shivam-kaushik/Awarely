import 'package:flutter/material.dart';
import '../../data/models/reminder.dart' as model;
import 'priority_selector.dart';
import 'category_selector.dart';
import 'time_selectors.dart';
import '../screens/home_setup_screen.dart';
import '../../core/services/home_detection_service.dart';
import 'package:flutter/foundation.dart';
import '../../data/models/saved_location.dart';

/// Comprehensive reminder creation/edit dialog with all smart features
class SmartReminderDialog extends StatefulWidget {
  final model.Reminder? reminder; // Null for new, populated for edit
  // Optional suggestion for location-based reminders. Example:
  // { 'context': 'home', 'latitude': 12.34, 'longitude': 56.78, 'radius': 150.0 }
  final Map<String, dynamic>? locationSuggestion;

  const SmartReminderDialog({
    super.key,
    this.reminder,
    this.locationSuggestion,
  });

  @override
  State<SmartReminderDialog> createState() => _SmartReminderDialogState();
}

class _SmartReminderDialogState extends State<SmartReminderDialog> {
  late TextEditingController _textController;
  late model.ReminderPriority _priority;
  late model.ReminderCategory _category;

  // Location-related editor fields
  bool _enableLocation = false;
  bool _onLeaveContext = false;
  bool _onArriveContext = false;
  double? _geofenceLat;
  double? _geofenceLng;
  double? _geofenceRadius;
  String? _locationContext;

  DateTime? _timeAt;
  bool _isRecurring = false;
  int? _repeatInterval;
  String? _repeatUnit;
  DateTime? _repeatEndDate;
  List<int>? _repeatOnDays;
  DateTime? _timeRangeStart;
  DateTime? _timeRangeEnd;
  model.TimeOfDay? _preferredTimeOfDay;

  bool _showAdvanced = false;

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;

    _textController = TextEditingController(text: reminder?.text ?? '');
    _priority = reminder?.priority ?? model.ReminderPriority.medium;
    _category = reminder?.category ?? model.ReminderCategory.other;
    _timeAt = reminder?.timeAt;
    _isRecurring = reminder?.isRecurring ?? false;
    _repeatInterval = reminder?.repeatInterval;
    _repeatUnit = reminder?.repeatUnit;
    _repeatEndDate = reminder?.repeatEndDate;
    _repeatOnDays = reminder?.repeatOnDays;
    _timeRangeStart = reminder?.timeRangeStart;
    _timeRangeEnd = reminder?.timeRangeEnd;
    _preferredTimeOfDay = reminder?.preferredTimeOfDay;
    // Initialize location-related fields from reminder or suggestion
    _enableLocation = reminder?.geofenceId != null;
    _onLeaveContext = reminder?.onLeaveContext ?? false;
    _onArriveContext = reminder?.onArriveContext ?? false;
    _geofenceLat = reminder?.geofenceLat;
    _geofenceLng = reminder?.geofenceLng;
    _geofenceRadius = reminder?.geofenceRadius;
    _locationContext = reminder?.geofenceId; // may be 'home' or other id
    // If a suggestion is provided and no geofence is set, store suggestion but keep disabled
    if (!_enableLocation && widget.locationSuggestion != null) {
      _locationContext = widget.locationSuggestion!['context'] as String?;
      _geofenceLat = widget.locationSuggestion!['latitude'] as double?;
      _geofenceLng = widget.locationSuggestion!['longitude'] as double?;
      _geofenceRadius =
          widget.locationSuggestion!['radius'] as double? ?? 150.0;
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _timeAt ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date == null) return;

    if (!mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_timeAt ?? DateTime.now()),
    );

    if (time != null) {
      setState(() {
        _timeAt = DateTime(
          date.year,
          date.month,
          date.day,
          time.hour,
          time.minute,
        );
      });
    }
  }

  Future<void> _pickEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _repeatEndDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _repeatEndDate = date);
    }
  }

  Future<void> _pickTimeRange() async {
    // Pick start time
    final startTime = await showTimePicker(
      context: context,
      initialTime: _timeRangeStart != null
          ? TimeOfDay.fromDateTime(_timeRangeStart!)
          : const TimeOfDay(hour: 9, minute: 0),
    );

    if (startTime == null) return;
    if (!mounted) return;

    // Pick end time
    final endTime = await showTimePicker(
      context: context,
      initialTime: _timeRangeEnd != null
          ? TimeOfDay.fromDateTime(_timeRangeEnd!)
          : const TimeOfDay(hour: 18, minute: 0),
    );

    if (endTime != null) {
      final now = DateTime.now();
      setState(() {
        _timeRangeStart = DateTime(
          now.year,
          now.month,
          now.day,
          startTime.hour,
          startTime.minute,
        );
        _timeRangeEnd = DateTime(
          now.year,
          now.month,
          now.day,
          endTime.hour,
          endTime.minute,
        );
      });
    }
  }

  void _save() {
    final text = _textController.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a reminder text')),
      );
      return;
    }

    if (_isRecurring && (_repeatInterval == null || _repeatUnit == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set repeat interval')),
      );
      return;
    }

    final reminder = model.Reminder(
      id: widget.reminder?.id,
      text: text,
      timeAt: _timeAt,
      priority: _priority,
      category: _category,
      repeatInterval: _isRecurring ? _repeatInterval : null,
      repeatUnit: _isRecurring ? _repeatUnit : null,
      repeatEndDate: _isRecurring ? _repeatEndDate : null,
      repeatOnDays: _repeatOnDays,
      timeRangeStart: _timeRangeStart,
      timeRangeEnd: _timeRangeEnd,
      preferredTimeOfDay: _preferredTimeOfDay,
      // Location fields
      geofenceId: _enableLocation ? (_locationContext ?? 'home') : null,
      geofenceLat: _enableLocation ? _geofenceLat : null,
      geofenceLng: _enableLocation ? _geofenceLng : null,
      geofenceRadius: _enableLocation ? _geofenceRadius : null,
      onLeaveContext: _onLeaveContext,
      onArriveContext: _onArriveContext,
    );

    Navigator.of(context).pop(reminder);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.add_alert, color: Theme.of(context).primaryColor),
                  const SizedBox(width: 12),
                  Text(
                    widget.reminder == null ? 'New Reminder' : 'Edit Reminder',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            // Scrollable content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Text input
                    TextField(
                      controller: _textController,
                      decoration: const InputDecoration(
                        labelText: 'What do you want to remember?',
                        hintText: 'e.g., Take medicine, Call doctor',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 2,
                      autofocus: true,
                    ),

                    const SizedBox(height: 24),
                    // Location suggestion / controls
                    if (_onLeaveContext ||
                        _onArriveContext ||
                        widget.locationSuggestion != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: _buildLocationSection(),
                      ),

                    // Priority
                    PrioritySelector(
                      selectedPriority: _priority,
                      onChanged: (p) => setState(() => _priority = p),
                    ),

                    const SizedBox(height: 24),

                    // Category
                    CategorySelector(
                      selectedCategory: _category,
                      onChanged: (c) => setState(() => _category = c),
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Time settings
                    _buildTimeSettings(),

                    const SizedBox(height: 24),

                    // Advanced options
                    _buildAdvancedOptions(),

                    const SizedBox(height: 24),

                    // Preview
                    if (_isRecurring || _timeAt != null) _buildPreview(),
                  ],
                ),
              ),
            ),

            // Footer buttons
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _save,
                    child: Text(widget.reminder == null ? 'Create' : 'Update'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeSettings() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Date/Time picker
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _pickDateTime,
                icon: const Icon(Icons.schedule),
                label: Text(
                  _timeAt == null
                      ? 'Set Date & Time'
                      : '${_formatDate(_timeAt!)} at ${_formatTime(_timeAt!)}',
                ),
              ),
            ),
            if (_timeAt != null)
              IconButton(
                onPressed: () => setState(() => _timeAt = null),
                icon: const Icon(Icons.clear),
              ),
          ],
        ),

        const SizedBox(height: 16),

        // Recurring toggle
        SwitchListTile(
          title: const Text('Repeat'),
          value: _isRecurring,
          onChanged: (val) => setState(() => _isRecurring = val),
          contentPadding: EdgeInsets.zero,
        ),

        if (_isRecurring) ...[
          const SizedBox(height: 16),

          // Repeat interval
          Row(
            children: [
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Every',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (val) => _repeatInterval = int.tryParse(val),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 3,
                child: DropdownButtonFormField<String>(
                  initialValue: _repeatUnit ?? 'hours',
                  decoration: const InputDecoration(
                    labelText: 'Unit',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'minutes', child: Text('Minutes')),
                    DropdownMenuItem(value: 'hours', child: Text('Hours')),
                    DropdownMenuItem(value: 'days', child: Text('Days')),
                    DropdownMenuItem(value: 'weeks', child: Text('Weeks')),
                  ],
                  onChanged: (val) => setState(() => _repeatUnit = val),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // End date
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickEndDate,
                  icon: const Icon(Icons.event),
                  label: Text(
                    _repeatEndDate == null
                        ? 'Set End Date'
                        : 'Until ${_formatDate(_repeatEndDate!)}',
                  ),
                ),
              ),
              if (_repeatEndDate != null)
                IconButton(
                  onPressed: () => setState(() => _repeatEndDate = null),
                  icon: const Icon(Icons.clear),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildAdvancedOptions() {
    return Column(
      children: [
        // Advanced toggle
        TextButton.icon(
          onPressed: () => setState(() => _showAdvanced = !_showAdvanced),
          icon: Icon(_showAdvanced ? Icons.expand_less : Icons.expand_more),
          label: Text(
            _showAdvanced ? 'Hide Advanced Options' : 'Show Advanced Options',
          ),
        ),

        if (_showAdvanced) ...[
          const SizedBox(height: 16),

          // Time of day preference
          TimeOfDaySelector(
            selectedTimeOfDay: _preferredTimeOfDay,
            onChanged: (val) => setState(() => _preferredTimeOfDay = val),
          ),

          const SizedBox(height: 16),

          // Custom time range
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _pickTimeRange,
                  icon: const Icon(Icons.access_time),
                  label: Text(
                    _timeRangeStart == null
                        ? 'Set Time Range'
                        : '${_formatTime(_timeRangeStart!)} - ${_formatTime(_timeRangeEnd!)}',
                  ),
                ),
              ),
              if (_timeRangeStart != null)
                IconButton(
                  onPressed: () => setState(() {
                    _timeRangeStart = null;
                    _timeRangeEnd = null;
                  }),
                  icon: const Icon(Icons.clear),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Days of week
          if (_isRecurring)
            DaysOfWeekSelector(
              selectedDays: _repeatOnDays,
              onChanged: (days) => setState(() => _repeatOnDays = days),
            ),
        ],
      ],
    );
  }

  Widget _buildPreview() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.info_outline, color: Colors.blue.shade700, size: 20),
              const SizedBox(width: 8),
              Text(
                'Preview',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.blue.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPreviewText(),
        ],
      ),
    );
  }

  Widget _buildPreviewText() {
    final parts = <String>[];

    if (_isRecurring && _repeatInterval != null && _repeatUnit != null) {
      parts.add('Repeats every $_repeatInterval $_repeatUnit');

      if (_timeRangeStart != null && _timeRangeEnd != null) {
        parts.add(
          'between ${_formatTime(_timeRangeStart!)} and ${_formatTime(_timeRangeEnd!)}',
        );
      } else if (_preferredTimeOfDay != null) {
        parts.add(
          'during ${_preferredTimeOfDay!.displayName.split(' ')[0].toLowerCase()}',
        );
      }

      if (_repeatOnDays != null && _repeatOnDays!.isNotEmpty) {
        const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final days = _repeatOnDays!.map((d) => dayNames[d - 1]).join(', ');
        parts.add('on $days');
      }

      if (_repeatEndDate != null) {
        parts.add('until ${_formatDate(_repeatEndDate!)}');
      }
    } else if (_timeAt != null) {
      parts.add('Once on ${_formatDate(_timeAt!)} at ${_formatTime(_timeAt!)}');
    }

    return Text(
      parts.isEmpty ? 'No schedule set' : parts.join(' '),
      style: const TextStyle(fontSize: 14),
    );
  }

  Widget _buildLocationSection() {
    final suggested = widget.locationSuggestion != null;
    final String locationLabel = _locationContext ??
        (suggested
            ? widget.locationSuggestion!['context'] as String
            : 'location');

    return Card(
      color: Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.place, color: Theme.of(context).primaryColor),
                const SizedBox(width: 8),
                Expanded(
                    child: Text('Location triggers',
                        style: Theme.of(context).textTheme.titleMedium)),
              ],
            ),
            const SizedBox(height: 8),

            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Enable location triggers for this reminder'),
              value: _enableLocation,
              onChanged: (val) async {
                if (val && (_geofenceLat == null || _geofenceLng == null)) {
                  // Try to use suggestion or ask user to setup home
                  if (suggested && widget.locationSuggestion != null) {
                    setState(() {
                      _geofenceLat =
                          widget.locationSuggestion!['latitude'] as double?;
                      _geofenceLng =
                          widget.locationSuggestion!['longitude'] as double?;
                      _geofenceRadius =
                          widget.locationSuggestion!['radius'] as double? ??
                              150.0;
                      _locationContext =
                          widget.locationSuggestion!['context'] as String? ??
                              _locationContext;
                      _enableLocation = true;
                    });
                    return;
                  }

                  // No suggestion available: navigate user to Home setup
                  final shouldSetup = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Location not configured'),
                      content: const Text(
                          'To enable location triggers you need to set your home location. Would you like to set it up now?'),
                      actions: [
                        TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel')),
                        ElevatedButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Setup')),
                      ],
                    ),
                  );

                  if (shouldSetup == true) {
                    // Open HomeSetupScreen and then attempt to fetch home
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const HomeSetupScreen(),
                      ),
                    );
                    await _applyHomeLocationFromService();
                    if (_geofenceLat != null) {
                      setState(() => _enableLocation = true);
                    }
                  }
                } else {
                  setState(() => _enableLocation = val);
                }
              },
            ),

            if (_enableLocation) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _geofenceLat != null && _geofenceLng != null
                          ? 'Using $locationLabel (${_geofenceLat!.toStringAsFixed(4)}, ${_geofenceLng!.toStringAsFixed(4)})'
                          : 'No location chosen',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: () async {
                      // Allow user to (re)open home setup and fetch location
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const HomeSetupScreen(),
                        ),
                      );
                      await _applyHomeLocationFromService();
                      if (mounted) setState(() {});
                    },
                    child: const Text('Set / Update'),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 8),
            // Leave/Arrive toggles
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('When I leave $locationLabel'),
              value: _onLeaveContext,
              onChanged: (v) => setState(() => _onLeaveContext = v ?? false),
            ),
            CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('When I arrive $locationLabel'),
              value: _onArriveContext,
              onChanged: (v) => setState(() => _onArriveContext = v ?? false),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applyHomeLocationFromService() async {
    final SavedLocation? home = await HomeDetectionService().getHomeLocation();
    if (home != null) {
      _geofenceLat = home.latitude;
      _geofenceLng = home.longitude;
      _geofenceRadius = home.radius;
      _locationContext = home.name;
      if (kDebugMode) {
        debugPrint(
            'SmartDialog: applied home location $_geofenceLat,$_geofenceLng');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Home location not configured')),
        );
      }
    }
  }

  String _formatTime(DateTime time) {
    final hour =
        time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}
