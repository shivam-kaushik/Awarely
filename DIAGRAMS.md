# 📊 Awarely - Visual Architecture & Flow Diagrams

This document contains ASCII diagrams illustrating the system architecture, data flows, and user journeys.

---

## 1. System Architecture Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                         AWARELY APP                              │
│                                                                  │
│  ┌────────────────────────────────────────────────────────┐    │
│  │             PRESENTATION LAYER                          │    │
│  │  ┌──────────┐  ┌──────────┐  ┌──────────────────┐     │    │
│  │  │ Splash   │  │Onboarding│  │    Home Screen   │     │    │
│  │  │ Screen   │→ │ Screen   │→ │  (Reminder List) │     │    │
│  │  └──────────┘  └──────────┘  └──────────────────┘     │    │
│  │                                        │                │    │
│  │  ┌──────────────┐         ┌───────────▼──────────┐    │    │
│  │  │ Add Reminder │         │  Analytics Screen   │    │    │
│  │  │   Screen     │         │   (Statistics)      │    │    │
│  │  └──────┬───────┘         └─────────────────────┘    │    │
│  │         │                                              │    │
│  │         │  Provider (State Management)                │    │
│  │         ▼                                              │    │
│  │  ┌──────────────────────────────────────────┐        │    │
│  │  │      ReminderProvider                     │        │    │
│  │  │  - createReminder()                       │        │    │
│  │  │  - updateReminder()                       │        │    │
│  │  │  - deleteReminder()                       │        │    │
│  │  │  - loadStatistics()                       │        │    │
│  │  └──────────────┬───────────────────────────┘        │    │
│  └─────────────────┼────────────────────────────────────┘    │
│                    │                                           │
│  ┌─────────────────▼──────────────────────────────────────┐  │
│  │          BUSINESS LOGIC LAYER                           │  │
│  │  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐ │  │
│  │  │  NLU Parser  │  │   Trigger    │  │ Notification │ │  │
│  │  │              │  │   Engine     │  │   Service    │ │  │
│  │  │  Parse text  │  │              │  │              │ │  │
│  │  │  Extract:    │  │  Monitor:    │  │  Schedule &  │ │  │
│  │  │  - Task      │  │  - GPS       │  │  Show alerts │ │  │
│  │  │  - Time      │  │  - Wi-Fi     │  │              │ │  │
│  │  │  - Location  │  │  - Time      │  │              │ │  │
│  │  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘ │  │
│  └─────────┼─────────────────┼─────────────────┼─────────┘  │
│            │                 │                 │             │
│  ┌─────────▼─────────────────▼─────────────────▼─────────┐  │
│  │               DATA LAYER                                │  │
│  │  ┌────────────────────────────────────────────────┐    │  │
│  │  │       ReminderRepository                       │    │  │
│  │  │  - CRUD operations                             │    │  │
│  │  │  - Query reminders                             │    │  │
│  │  │  - Log events                                  │    │  │
│  │  └────────────────────┬───────────────────────────┘    │  │
│  │                       │                                 │  │
│  │  ┌────────────────────▼───────────────────────────┐    │  │
│  │  │         DatabaseHelper (Singleton)             │    │  │
│  │  │  - SQLite instance                             │    │  │
│  │  │  - Table creation                              │    │  │
│  │  │  - Migrations                                  │    │  │
│  │  └────────────────────┬───────────────────────────┘    │  │
│  └─────────────────────────┼──────────────────────────────┘  │
│                            │                                  │
│                      ┌─────▼─────┐                           │
│                      │  SQLite   │                           │
│                      │ Database  │                           │
│                      └───────────┘                           │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. User Flow - Creating a Reminder

```
┌─────────────────────────────────────────────────────────────┐
│                    USER JOURNEY                              │
└─────────────────────────────────────────────────────────────┘

    USER
     │
     ▼
┌─────────────────┐
│  Open App       │
│  (Splash)       │
└────────┬────────┘
         │
         ▼
┌─────────────────┐       First Time?
│  Onboarding     │───────────── Yes ───┐
│  (3 pages)      │                     │
└────────┬────────┘                     │
         │                              │
         │ No                           │
         ▼                              │
┌─────────────────────────┐            │
│  Home Screen            │◄───────────┘
│  - Reminder List        │
│  - Analytics Button     │
│  - Settings             │
└────────┬────────────────┘
         │
         │ Tap "Add Reminder"
         ▼
┌─────────────────────────┐
│  Add Reminder Screen    │
│  - Text Input Field     │
│  - Voice Input Button   │
│  - Sample Phrases       │
└────────┬────────────────┘
         │
         │ User types: "Remind me to take medicine at 8 PM"
         ▼
┌────────────────────────────────┐
│  NLU Parser Processing         │
│  Input: "Remind me to take     │
│          medicine at 8 PM"     │
│                                │
│  Parse:                        │
│  ✓ Task: "Take medicine"       │
│  ✓ Time: 8:00 PM               │
│  ✓ Context: Time-based         │
└────────┬───────────────────────┘
         │
         ▼
┌────────────────────────────────┐
│  Create Reminder Object        │
│  {                             │
│    id: "uuid-1234",            │
│    text: "Take medicine",      │
│    timeAt: DateTime(20:00),    │
│    enabled: true               │
│  }                             │
└────────┬───────────────────────┘
         │
         ▼
┌────────────────────────────────┐
│  Save to Database              │
│  INSERT INTO reminders...      │
└────────┬───────────────────────┘
         │
         ▼
┌────────────────────────────────┐
│  Schedule Notification         │
│  scheduleNotification(         │
│    time: 8:00 PM,              │
│    title: "Reminder",          │
│    body: "Take medicine"       │
│  )                             │
└────────┬───────────────────────┘
         │
         ▼
┌────────────────────────────────┐
│  Return to Home Screen         │
│  ✓ Success message shown       │
│  ✓ Reminder appears in list    │
└────────────────────────────────┘
         │
         │ At 8:00 PM...
         ▼
┌────────────────────────────────┐
│  Notification Triggered        │
│  📱 "Reminder"                 │
│  💬 "Take medicine"            │
└────────────────────────────────┘
         │
         │ User taps notification
         ▼
┌────────────────────────────────┐
│  Log Context Event             │
│  outcome: "completed"          │
│  Update: triggerCount++        │
└────────────────────────────────┘
```

---

## 3. Context Monitoring Flow

```
┌──────────────────────────────────────────────────────────────┐
│              BACKGROUND CONTEXT MONITORING                    │
└──────────────────────────────────────────────────────────────┘

    APP START
       │
       ▼
┌────────────────────┐
│  Initialize        │
│  - NotificationService
│  - PermissionService
│  - TriggerEngine   │
└─────────┬──────────┘
          │
          ▼
┌────────────────────┐
│  WorkManager       │
│  Register Task:    │
│  - Every 15 min    │
│  - Battery-aware   │
└─────────┬──────────┘
          │
          │  ┌──────────────────┐
          │  │  User moves or   │
          └─▶│  time changes    │
             └────────┬─────────┘
                      │
        ┌─────────────┴──────────────┐
        │                            │
        ▼                            ▼
┌───────────────┐          ┌───────────────┐
│  GPS Stream   │          │  Wi-Fi Stream │
│  Update every │          │  Monitor SSID │
│  50 meters    │          │  connection   │
└───────┬───────┘          └───────┬───────┘
        │                          │
        └──────────┬───────────────┘
                   │
                   ▼
        ┌──────────────────────┐
        │  Query Active        │
        │  Reminders from DB   │
        └──────────┬───────────┘
                   │
                   ▼
        ┌──────────────────────┐
        │  For each reminder:  │
        │  Check if context    │
        │  matches current     │
        │  state               │
        └──────────┬───────────┘
                   │
        ┌──────────┴───────────┐
        │                      │
    ❌ NO                   ✅ YES
        │                      │
        ▼                      ▼
┌───────────────┐    ┌──────────────────┐
│  Continue     │    │  Trigger         │
│  Monitoring   │    │  Notification    │
└───────────────┘    └────────┬─────────┘
                              │
                              ▼
                    ┌──────────────────┐
                    │  Update Stats:   │
                    │  - lastTriggered │
                    │  - triggerCount++│
                    └────────┬─────────┘
                             │
                             ▼
                    ┌──────────────────┐
                    │  Log Event:      │
                    │  contextType,    │
                    │  triggerTime,    │
                    │  outcome         │
                    └──────────────────┘
```

---

## 4. Data Model Relationships

```
┌─────────────────────────────────────────────────────────┐
│                    DATABASE SCHEMA                       │
└─────────────────────────────────────────────────────────┘

┌───────────────────────────┐
│      REMINDERS            │
├───────────────────────────┤
│ id (PK)          TEXT     │
│ text             TEXT     │
│ timeAt           TEXT     │─────┐
│ geofenceId       TEXT     │     │
│ geofenceLat      REAL     │     │
│ geofenceLng      REAL     │     │
│ geofenceRadius   REAL     │     │  One reminder can have
│ wifiSsid         TEXT     │     │  many context events
│ onLeaveContext   INTEGER  │     │
│ onArriveContext  INTEGER  │     │
│ enabled          INTEGER  │     │
│ createdAt        TEXT     │     │
│ lastTriggeredAt  TEXT     │     │
│ triggerCount     INTEGER  │     │
└───────────────────────────┘     │
                                  │
                                  │
                                  ▼
                        ┌───────────────────────────┐
                        │   CONTEXT_EVENTS          │
                        ├───────────────────────────┤
                        │ id (PK)          TEXT     │
                        │ reminderId (FK)  TEXT     │──┐
                        │ contextType      TEXT     │  │ Foreign Key
                        │ triggerTime      TEXT     │  │ to Reminders
                        │ outcome          TEXT     │  │
                        │ metadata         TEXT     │  │
                        └───────────────────────────┘  │
                                                       │
┌───────────────────────────┐                         │
│      LOCATIONS            │                         │
├───────────────────────────┤                         │
│ id (PK)          TEXT     │                         │
│ name             TEXT     │─────────────────────────┘
│ latitude         REAL     │  Referenced by
│ longitude        REAL     │  geofenceId
│ radius           REAL     │
│ wifiSsid         TEXT     │
│ createdAt        TEXT     │
└───────────────────────────┘

INDEXES:
- idx_reminders_enabled ON reminders(enabled)
- idx_context_events_reminder ON context_events(reminderId)
- idx_context_events_time ON context_events(triggerTime)
```

---

## 5. State Management Flow (Provider Pattern)

```
┌──────────────────────────────────────────────────────────┐
│                PROVIDER PATTERN FLOW                      │
└──────────────────────────────────────────────────────────┘

       UI LAYER
          │
          │ Consumer<ReminderProvider>
          ▼
┌────────────────────────┐
│   ReminderProvider     │◄──── ChangeNotifier
│                        │
│  State:                │
│  - List<Reminder>      │
│  - isLoading           │
│  - error               │
│  - statistics          │
│                        │
│  Methods:              │
│  - loadReminders()     │
│  - createReminder()    │
│  - updateReminder()    │
│  - deleteReminder()    │
│  - toggleReminder()    │
└────────┬───────────────┘
         │
         │ notifyListeners()
         ▼
    ┌─────────┐
    │   UI    │  Rebuilds automatically
    │ Widgets │  when state changes
    └─────────┘

EXAMPLE FLOW:

1. User taps "Toggle Reminder"
   │
   ▼
2. HomeScreen calls:
   reminderProvider.toggleReminder(id, enabled)
   │
   ▼
3. ReminderProvider:
   - Updates database
   - Reschedules/cancels notification
   - Calls notifyListeners()
   │
   ▼
4. Consumer<ReminderProvider> rebuilds
   │
   ▼
5. UI shows updated state
```

---

## 6. NLU Parsing Flow

```
┌──────────────────────────────────────────────────────────┐
│           NATURAL LANGUAGE UNDERSTANDING                  │
└──────────────────────────────────────────────────────────┘

INPUT: "Remind me to take medicine when leaving home at 8 AM"
  │
  ▼
┌────────────────────────────────────┐
│  1. Lowercase & Normalize          │
│  "remind me to take medicine when  │
│   leaving home at 8 am"            │
└────────┬───────────────────────────┘
         │
         ▼
┌────────────────────────────────────┐
│  2. Extract Time                   │
│  Pattern: "at \d{1,2} (am|pm)"     │
│  Result: timeAt = 8:00 AM          │
└────────┬───────────────────────────┘
         │
         ▼
┌────────────────────────────────────┐
│  3. Extract Location               │
│  Keywords: ["home", "work", ...]   │
│  Result: geofenceId = "home"       │
└────────┬───────────────────────────┘
         │
         ▼
┌────────────────────────────────────┐
│  4. Extract Movement Context       │
│  Keywords: ["leaving", "arriving"] │
│  Result: onLeaveContext = true     │
└────────┬───────────────────────────┘
         │
         ▼
┌────────────────────────────────────┐
│  5. Clean Reminder Text            │
│  Remove: "remind me to", "when",   │
│          "at 8 AM", "leaving home" │
│  Result: "Take medicine"           │
└────────┬───────────────────────────┘
         │
         ▼
OUTPUT: Reminder {
  text: "Take medicine",
  timeAt: DateTime(8:00),
  geofenceId: "home",
  onLeaveContext: true
}
```

---

## 7. Notification Triggering Timeline

```
TIME: 7:50 AM                      8:00 AM                      8:10 AM
  │                                  │                             │
  │                                  │                             │
  ▼                                  ▼                             ▼
┌─────────────────┐      ┌──────────────────────┐      ┌─────────────────┐
│ Background      │      │ Time matches!        │      │ Notification    │
│ service checks  │      │ Trigger notification │      │ dismissed or    │
│ every 15 min    │──────▶ scheduled for 8 AM  │──────▶ acknowledged     │
└─────────────────┘      └──────────────────────┘      └─────────────────┘
                                   │
                                   ▼
                         ┌──────────────────────┐
                         │ System Notification  │
                         │ 📱 "Reminder"        │
                         │ 💬 "Take medicine"   │
                         └──────────────────────┘
                                   │
                         ┌─────────┴──────────┐
                         │                    │
                  User Taps            User Dismisses
                         │                    │
                         ▼                    ▼
               ┌──────────────┐     ┌──────────────┐
               │ outcome:     │     │ outcome:     │
               │ "completed"  │     │ "dismissed"  │
               └──────────────┘     └──────────────┘
```

---

## 8. Permission Request Flow

```
┌──────────────────────────────────────────────────────────┐
│                 PERMISSION FLOW                           │
└──────────────────────────────────────────────────────────┘

      APP LAUNCH
          │
          ▼
    ┌────────────┐
    │ Onboarding │
    │  Screen    │
    └──────┬─────┘
           │
           │ User taps "Get Started"
           ▼
    ┌────────────────────────┐
    │ Request Permissions:   │
    │ 1. Location            │
    │ 2. Notifications       │
    └──────┬─────────────────┘
           │
    ┌──────┴──────────────────────────┐
    │                                 │
    ▼                                 ▼
┌───────────────┐            ┌────────────────┐
│  Location     │            │ Notification   │
│  Permission   │            │ Permission     │
└───────┬───────┘            └────────┬───────┘
        │                             │
    ┌───┴──────┐                 ┌────┴─────┐
    │          │                 │          │
 GRANTED    DENIED            GRANTED    DENIED
    │          │                 │          │
    ▼          ▼                 ▼          ▼
┌────────┐ ┌────────┐      ┌────────┐ ┌────────┐
│ Enable │ │ Show   │      │ Enable │ │ Show   │
│ GPS    │ │ Retry  │      │ Alerts │ │ Retry  │
│ Monitor│ │ Dialog │      │        │ │ Dialog │
└────────┘ └────────┘      └────────┘ └────────┘
```

---

## 9. Analytics Calculation

```
┌──────────────────────────────────────────────────────────┐
│              ANALYTICS METRICS                            │
└──────────────────────────────────────────────────────────┘

DATABASE QUERIES:

1. Total Reminders
   └─ SELECT COUNT(*) FROM reminders

2. Active Reminders
   └─ SELECT COUNT(*) FROM reminders WHERE enabled = 1

3. Total Events
   └─ SELECT COUNT(*) FROM context_events

4. Completed Events
   └─ SELECT COUNT(*) FROM context_events 
      WHERE outcome = 'completed'

5. Completion Rate
   └─ (completedEvents / totalEvents) * 100

DISPLAY:

┌──────────────────────┐
│   Analytics Screen   │
│                      │
│   ╔═══════════╗      │
│   ║    87%    ║      │  Completion Rate
│   ╚═══════════╝      │
│                      │
│  ┌────────┬────────┐ │
│  │  Total │ Active │ │
│  │   24   │   18   │ │
│  ├────────┼────────┤ │
│  │  Done  │ Events │ │
│  │   156  │  179   │ │
│  └────────┴────────┘ │
└──────────────────────┘
```

---

## 10. Deployment Flow

```
┌──────────────────────────────────────────────────────────┐
│                  DEPLOYMENT PIPELINE                      │
└──────────────────────────────────────────────────────────┘

  LOCAL DEVELOPMENT
         │
         │ git commit & push
         ▼
  ┌──────────────┐
  │  GitHub      │
  │  Repository  │
  └──────┬───────┘
         │
         │ GitHub Actions trigger
         ▼
  ┌──────────────────────┐
  │  CI/CD Pipeline      │
  │  - flutter test      │
  │  - flutter analyze   │
  │  - flutter build     │
  └──────┬───────────────┘
         │
    ┌────┴────┐
    │         │
    ▼         ▼
┌─────────┐ ┌─────────┐
│ Android │ │   iOS   │
│  Build  │ │  Build  │
└────┬────┘ └────┬────┘
     │           │
     ▼           ▼
┌──────────┐ ┌──────────┐
│ Play     │ │ App      │
│ Console  │ │ Store    │
│ Beta     │ │ TestFligh│
└──────────┘ └──────────┘
     │           │
     │           │
     └─────┬─────┘
           │
           ▼
    ┌──────────────┐
    │  PRODUCTION  │
    │   RELEASE    │
    └──────────────┘
```

---

**End of Visual Diagrams**

These ASCII diagrams provide a comprehensive visual overview of Awarely's architecture, flows, and interactions. Use them for understanding system design, onboarding new developers, and technical presentations.
