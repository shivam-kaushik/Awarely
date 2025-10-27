# 🏗️ Awarely Architecture Documentation

## Overview

Awarely follows **Clean Architecture** principles with clear separation between presentation, business logic, and data layers. This ensures testability, maintainability, and scalability.

---

## Architecture Layers

### 1. Presentation Layer (`lib/presentation/`)

**Responsibility**: UI rendering, user interaction, state management

**Components**:
- **Screens**: Full-page views (Home, Add Reminder, Analytics)
- **Widgets**: Reusable UI components (ReminderCard)
- **Providers**: State management using Provider pattern
- **Theme**: Material 3 design system configuration

**Key Principles**:
- No direct database access
- No business logic
- Observes state from Providers
- Reactive UI updates

**Example Flow**:
```
User taps "Add Reminder" 
  → AddReminderScreen
  → Calls ReminderProvider.createReminderFromText()
  → UI updates automatically via notifyListeners()
```

---

### 2. Business Logic Layer (`lib/core/services/`)

**Responsibility**: Application logic, context monitoring, NLU processing

**Components**:

#### NLU Parser (`nlu_parser.dart`)
- Parses natural language input
- Extracts task, time, location, and trigger type
- Uses regex patterns and keyword matching
- Future: Integration with OpenAI GPT-4 for advanced parsing

**Input**: "Remind me to take medicine at 8 PM"
**Output**: Reminder(text: "Take medicine", timeAt: DateTime(20:00))

#### Trigger Engine (`trigger_engine.dart`)
- Monitors sensor streams (GPS, Wi-Fi, connectivity)
- Matches current context against reminder triggers
- Fires notifications when context matches
- Handles location updates efficiently (50m distance filter)

**Context Types**:
- Time: Scheduled at specific DateTime
- Geofence: Within radius of saved location
- Wi-Fi: Connected to specific SSID
- Leaving: Exiting geofence boundary
- Arriving: Entering geofence boundary

#### Notification Service (`notification_service.dart`)
- Manages local notifications (flutter_local_notifications)
- Schedules time-based notifications
- Shows immediate context-triggered alerts
- Handles notification channels (Android) and authorization (iOS)

#### Permission Service (`permission_service.dart`)
- Requests runtime permissions (location, notification)
- Checks permission status
- Opens app settings for manual permission grant

---

### 3. Data Layer (`lib/data/`)

**Responsibility**: Data persistence, models, repository pattern

**Components**:

#### Models (`models/`)
- **Reminder**: Core reminder entity with context fields
- **ContextEvent**: Logs each trigger event with outcome
- **SavedLocation**: Stores frequently used places

**Model Properties**:
```dart
Reminder:
  - id, text, timeAt
  - geofenceId, geofenceLat, geofenceLng, geofenceRadius
  - wifiSsid
  - onLeaveContext, onArriveContext
  - enabled, createdAt, lastTriggeredAt, triggerCount
```

#### Database Helper (`database_helper.dart`)
- SQLite database singleton
- Creates tables on first run
- Handles schema migrations
- Provides database instance to repositories

**Tables**:
- `reminders`: Stores all reminder data
- `context_events`: Logs trigger history
- `locations`: Saved places (home, work, etc.)

#### Repository (`repositories/reminder_repository.dart`)
- Abstraction layer for data access
- CRUD operations for reminders
- Query methods (getActiveReminders, getAllReminders)
- Statistics aggregation (completion rate, counts)

---

## Data Flow Diagram

```
┌────────────────────────────────────────────────────────────┐
│                      USER INTERACTION                       │
└──────────────┬─────────────────────────────────────────────┘
               │
               ▼
┌──────────────────────────────────────────────────────────┐
│               PRESENTATION LAYER                          │
│  ┌────────────┐  ┌────────────┐  ┌──────────────┐       │
│  │  Screens   │  │  Widgets   │  │  Providers   │       │
│  └────────────┘  └────────────┘  └──────────────┘       │
└──────────────┬───────────────────────────────────────────┘
               │ (State Management)
               ▼
┌──────────────────────────────────────────────────────────┐
│              BUSINESS LOGIC LAYER                         │
│  ┌────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ NLU Parser │  │Trigger Engine│  │ Notification │     │
│  └────────────┘  └──────────────┘  └──────────────┘     │
└──────────────┬───────────────────────────────────────────┘
               │ (Data Operations)
               ▼
┌──────────────────────────────────────────────────────────┐
│                    DATA LAYER                             │
│  ┌────────────┐  ┌─────────────┐  ┌──────────────┐      │
│  │   Models   │  │  Repository │  │   Database   │      │
│  └────────────┘  └─────────────┘  └──────────────┘      │
└──────────────┬───────────────────────────────────────────┘
               │
               ▼
         [SQLite Database]
```

---

## Context Monitoring Workflow

```
App Start
   │
   ▼
Initialize Services
   ├─> NotificationService.initialize()
   ├─> PermissionService.requestPermissions()
   └─> TriggerEngine.startMonitoring()
         │
         ▼
   Monitor Sensors (Background)
         ├─> GPS Stream (every 50m)
         ├─> Wi-Fi Connectivity
         └─> Time Checks (every 1 min)
               │
               ▼
   Compare Context with Active Reminders
         │
         ▼
   Match Found?
      ├─ Yes → Trigger Notification
      │         ├─> Update lastTriggeredAt
      │         ├─> Increment triggerCount
      │         └─> Log ContextEvent
      └─ No  → Continue Monitoring
```

---

## State Management (Provider Pattern)

**Why Provider?**
- Simple and performant
- Built-in with Flutter SDK
- Easy to test
- Minimal boilerplate

**ReminderProvider Flow**:
```
UI (Home Screen)
   │
   ├─> Consumer<ReminderProvider>
   │      └─> reminderProvider.reminders (Observable)
   │
   └─> Button Tap: Add Reminder
          │
          ▼
   reminderProvider.createReminderFromText(text)
          ├─> NLU Parser (extract context)
          ├─> Repository.createReminder()
          ├─> NotificationService.schedule()
          └─> notifyListeners() → UI Rebuilds
```

---

## Background Processing

**WorkManager** is used for periodic context checks:

```dart
Workmanager.registerPeriodicTask(
  'context_monitor',
  'contextMonitorTask',
  frequency: Duration(minutes: 15),
  constraints: Constraints(
    networkType: NetworkType.not_required,
    requiresBatteryNotLow: true,
  ),
);
```

**Task Execution**:
1. Wake up every 15 minutes (OS permitting)
2. Check current context (location, Wi-Fi, time)
3. Query active reminders from database
4. Trigger notifications if context matches
5. Go back to sleep

**Battery Optimization**:
- Distance filter on GPS (50m)
- Infrequent updates (15 min intervals)
- No continuous polling
- OS-managed task scheduling

---

## Security & Privacy

### Data Storage
- All data stored **locally** in SQLite
- No cloud upload in MVP
- Database encrypted with SQLCipher (future enhancement)

### Sensor Access
- Location processed on-device only
- No GPS logging to external servers
- Wi-Fi SSID stored locally for triggers

### User Control
- Permission requests with clear explanations
- Easy disable of reminders
- Data export/delete functionality (future)

---

## Testing Strategy

### Unit Tests (`test/`)
- NLU Parser logic
- Data model serialization
- Repository CRUD operations
- Utility functions

### Widget Tests
- Screen rendering
- User interactions
- State updates

### Integration Tests
- End-to-end reminder creation
- Notification triggering
- Background task execution

---

## Performance Considerations

1. **Database Indexing**: Indexes on `enabled` field and `triggerTime`
2. **Lazy Loading**: Reminders loaded only when needed
3. **Efficient Queries**: Use `WHERE` clauses to filter active reminders
4. **UI Debouncing**: Prevent excessive rebuilds
5. **Asset Optimization**: Compress images and use vector icons

---

## Scalability Plan

### Phase 1 (MVP): Local-First
- SQLite database
- On-device processing
- No backend required

### Phase 2 (Beta): Hybrid
- Firebase Auth for user accounts
- Firestore for cloud sync (optional)
- Local-first with background sync

### Phase 3 (Scale): Cloud-Enhanced
- Cloud Functions for ML model updates
- BigQuery for aggregate analytics
- CDN for asset delivery
- Multi-region deployment

---

## Technology Decisions

### Why Flutter?
- Single codebase for iOS + Android
- Native performance with Dart
- Rich widget ecosystem
- Strong community support

### Why SQLite?
- Zero-config local database
- ACID compliant
- Fast read/write
- Perfect for offline-first apps

### Why Provider (not BLoC/Riverpod)?
- Simpler for MVP scope
- Less boilerplate
- Easier onboarding for contributors
- Can migrate to BLoC later if needed

---

## Future Enhancements

1. **Machine Learning**: TensorFlow Lite for pattern recognition
2. **Voice Input**: speech_to_text integration
3. **Wearables**: Flutter + watchOS/Wear OS
4. **IoT**: MQTT for smart home triggers
5. **Collaboration**: Multi-user shared reminders
6. **API**: RESTful API for third-party integrations

---

**Last Updated**: December 2024
**Version**: 1.0.0 (MVP)
