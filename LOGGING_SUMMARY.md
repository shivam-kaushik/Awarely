# 📊 Awarely - Logging Summary

## 🔍 All Features Are Now Fully Logged

All Phase 1 and Phase 2 features now have comprehensive logging to help you track and debug functionality.

---

## 📋 Log Categories & Emojis

### 🔔 Notifications & Alarms
- Reminder creation
- Alarm scheduling
- Notification display
- Recurring occurrences

### 📍 Location & Geofence
- Location updates
- Geofence checks
- Distance calculations
- Arrival/departure detection

### 📶 WiFi & Connectivity
- WiFi SSID detection
- Connectivity changes
- Home status checks

### 🏃 Activity Recognition
- Activity changes
- Speed calculations
- Activity transitions
- Activity-based triggers

### 🧠 Learning & Smart Timing
- Pattern learning
- Optimal time calculation
- Smart timing adjustments
- Completion rate analysis

### 🎤 Voice Input
- Speech recognition status
- Transcription results
- Permission checks

### ⏰ Time-Based
- Time parsing
- Scheduling logic
- Recurring calculations

---

## 🔍 Log Filtering Commands

### View All Awarely Logs:
```powershell
adb logcat | Select-String "awarely|Awarely|FLUTTER"
```

### Feature-Specific Filters:

**Notifications**:
```powershell
adb logcat | Select-String "🔔|Notification|Alarm|CREATING NEW REMINDER"
```

**Location**:
```powershell
adb logcat | Select-String "📍|Location|geofence|Home|Position update"
```

**Activity**:
```powershell
adb logcat | Select-String "🏃|Activity|activity changed|ACTIVITY CHANGED"
```

**Learning**:
```powershell
adb logcat | Select-String "🧠|Learning|optimal|Smart Timing"
```

**Voice**:
```powershell
adb logcat | Select-String "🎤|Voice|Speech|recognition"
```

**Trigger Engine**:
```powershell
adb logcat | Select-String "TriggerEngine|TRIGGER ENGINE"
```

**All Errors**:
```powershell
adb logcat | Select-String "❌|ERROR|Error|Exception"
```

---

## 📊 Log Output Examples

### Creating a Reminder:
```
📝 CREATING NEW REMINDER
═══════════════════════════════════════════════════
📋 Reminder Details:
   Text: "drink water"
   TimeAt: 2025-10-31 19:14:23.000
   IsRecurring: true
   RepeatInterval: 2
   RepeatUnit: minutes
═══════════════════════════════════════════════════
✅ Reminder saved with ID: abc123
📅 SCHEDULING OCCURRENCES:
   [Occurrence 1] Processing...
      ✅ Occurrence 1 scheduled successfully!
   [Occurrence 2] Processing...
      ✅ Occurrence 2 scheduled successfully!
```

### Activity Recognition:
```
🔄═══════════════════════════════════════════════════
🔄 ActivityRecognition: ACTIVITY CHANGED
🔄═══════════════════════════════════════════════════
   Previous: Unknown
   New: Walking
   Speed: 3.2 km/h
   Threshold: 1-5 km/h
🔄═══════════════════════════════════════════════════

🏃 TriggerEngine: Activity changed callback received
🔄 TriggerEngine: Activity changed: Unknown -> Walking
✅ TriggerEngine: Activity match found!
   Reminder: "Exercise when walking"
   Reminder activity: walking
   Current activity: Walking
```

### Learning Service:
```
🧠═══════════════════════════════════════════════════
🧠 LEARNING SERVICE: Learning Optimal Timing
🧠═══════════════════════════════════════════════════
   Reminder ID: abc123
   Total events: 8
   ✅ Completed event at 10:00
   ✅ Completed event at 10:00
   ✅ Completed event at 14:00
   
   Analyzing completion rates by hour:
     10:00 - 5/5 = 100.0%
     14:00 - 1/3 = 33.3%
   
   🎯 Optimal hour identified: 10:00
   📊 Completion rate: 100.0%
   💾 Saving learning pattern to database...
✅ Learning pattern saved
🧠═══════════════════════════════════════════════════
```

### Triggering a Reminder:
```
🔔═══════════════════════════════════════════════════
🔔 TRIGGER ENGINE: Triggering Reminder
🔔═══════════════════════════════════════════════════
   Reminder ID: abc123
   Text: "drink water"
   Context Type: time
   Time: 2025-10-31 19:14:23.000
✅ Trigger stats updated
✅ Context event created
📱 Showing notification...
✅ Notification shown
🔔═══════════════════════════════════════════════════
```

---

## 🎯 Testing with Logs

1. **Start the app** and watch logs for initialization
2. **Create a reminder** - watch for scheduling logs
3. **Wait for trigger** - watch for notification logs
4. **Move location** - watch for geofence logs
5. **Change activity** - watch for activity logs
6. **Complete reminders** - watch for learning logs

---

## 📝 Log Levels

- **Info** (default): Normal operation
- **Debug**: Detailed flow tracking
- **Warning** (⚠️): Non-critical issues
- **Error** (❌): Failures that need attention

All logs use emoji prefixes for easy visual scanning!

---

## 🚀 Quick Start Testing

1. Run app: `flutter run`
2. Open separate terminal for logs:
   ```powershell
   adb logcat | Select-String "🔔|📍|🏃|🧠|🎤"
   ```
3. Interact with app and watch logs in real-time!

---

**Happy Debugging! 🔍**

