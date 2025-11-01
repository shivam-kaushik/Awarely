# 🧪 Awarely - Complete Testing Guide for Emulator

## 📋 Prerequisites

1. **Android Emulator Setup**
   - Android Studio → AVD Manager
   - Create emulator with API 30+ (Android 11+)
   - Enable location services in emulator settings
   - Grant all permissions in emulator

2. **Emulator Configuration**
   - Enable mock location
   - Set up WiFi simulation (Settings → WiFi)
   - Enable GPS (Settings → Location)

---

## 🚀 Running Tests

### 1. Start the App
```bash
flutter run
```

### 2. Enable Debug Logging
All logs are prefixed with emojis for easy filtering:
- 🔔 = Notifications
- 📍 = Location/Geofence
- 📶 = WiFi
- 🏃 = Activity Recognition
- 🧠 = Learning/Smart Timing
- ⏰ = Time-based triggers
- ✅ = Success
- ❌ = Error
- ⚠️ = Warning

### 3. Filter Logs in Terminal
```powershell
# Filter for specific feature
adb logcat | Select-String "TriggerEngine"
adb logcat | Select-String "Activity"
adb logcat | Select-String "Learning"
adb logcat | Select-String "AlarmService"

# Filter for all Awarely logs
adb logcat | Select-String "awarely"
```

---

## ✅ Phase 1 Features Testing

### 1. Time-Based Reminder Triggering

#### Test: Basic Time Reminder
1. Open app → Tap "+" to add reminder
2. Enter: "Remind me to test notification in 1 minute"
3. Wait for notification at scheduled time
4. **Expected Logs**:
   ```
   📝 CREATING NEW REMINDER
   📅 TimeAt is set
   ✅ Alarm scheduled
   🔔 Notification shown
   ```

#### Test: Recurring Reminder
1. Enter: "Remind me to drink water every 2 mins starting now"
2. Watch logs for scheduling multiple occurrences
3. **Expected Logs**:
   ```
   🔁 Processing recurring reminder logic...
   📅 SCHEDULING OCCURRENCES:
   [Occurrence 1] Processing...
   ✅ Occurrence 1 scheduled successfully!
   [Occurrence 2] Processing...
   ✅ Occurrence 2 scheduled successfully!
   ...
   ```

#### Verify in Logs:
```powershell
adb logcat | Select-String "CREATING NEW REMINDER|Alarm scheduled|Occurrence"
```

---

### 2. Location-Based Triggering (Geofence)

#### Setup Mock Location:
1. In Android Studio → **More** (three dots) → **Location**
2. Or use ADB:
   ```bash
   adb emu geo fix <longitude> <latitude>
   ```

#### Test: Arrive at Location
1. **Set Home Location**:
   - Go to Settings → Home Setup
   - Save current location as "Home"
   - **Expected Log**: `✅ Home location saved`

2. **Create Arrival Reminder**:
   - Add: "Remind me to take keys when arriving home"
   - **Expected Log**: `📝 Home reminder: "take keys" (arrive=true)`

3. **Simulate Arrival**:
   - Use emulator location controls to move to home coordinates
   - **Expected Logs**:
     ```
     🏠 Home status check: now=true
     ✅ ARRIVING HOME detected
     🔔 TRIGGERING "arriving home" reminder
     ```

#### Test: Leave Location
1. Create: "Remind me to lock door when leaving home"
2. Move location away from home
3. **Expected Logs**:
   ```
   🚪 LEAVING HOME detected
   🔔 TRIGGERING "leaving home" reminder
   ```

#### Verify in Logs:
```powershell
adb logcat | Select-String "Home|ARRIVING|LEAVING|geofence"
```

---

### 3. WiFi SSID Detection

#### Test: WiFi Context
1. **Check Current WiFi**:
   - Add reminder: "Remind me when I connect to home WiFi"
   - **Expected Log**: `📶 Current WiFi SSID: <name>`

2. **Monitor WiFi Changes**:
   - Disconnect/reconnect WiFi in emulator
   - **Expected Logs**:
     ```
     📡 Connectivity changed: wifi
     📡 Home status check: now=true
     ```

#### Verify in Logs:
```powershell
adb logcat | Select-String "WiFi|SSID|Connectivity|Home status"
```

---

### 4. Natural Language Parsing

#### Test: Complex NLP Inputs
1. **Priority Detection**:
   - Input: "URGENT: Call doctor tomorrow at 3 PM"
   - **Expected Log**: `🔍 NLU PARSER: Parsing reminder text`
   - **Check**: Priority set to "Critical"

2. **Recurring with Starting Now**:
   - Input: "Remind me to exercise every 30 mins starting now"
   - **Expected Log**: `⚡ startImmediately: true`
   - **Check**: First occurrence scheduled 10 seconds from now

3. **Time Range**:
   - Input: "Remind me every hour between 9 AM and 6 PM"
   - **Expected Log**: `⏰ Time range extracted: 9:00 - 18:00`

4. **Specific Days**:
   - Input: "Remind me every Monday and Friday at 8 PM"
   - **Expected Log**: `📅 DaysOfWeek: [1, 5]`

#### Verify in Logs:
```powershell
adb logcat | Select-String "NLU PARSER|Parsing reminder|startImmediately"
```

---

### 5. Background Service

#### Test: Background Monitoring
1. **Create time-based reminder** (2 minutes in future)
2. **Kill app**: Swipe away from recent apps
3. **Wait for notification**
4. **Expected Logs** (via logcat, app killed):
   ```
   Background task executed: contextMonitorTask
   ⏰ Running background checks...
   📅 Time-based reminder triggered
   ```

#### Verify Background Tasks:
```powershell
adb logcat | Select-String "Background task|contextMonitorTask|WorkManager"
```

---

### 6. Permission Handling

#### Test: Permission Flow
1. **Fresh Install**:
   - Install app
   - Should see permission requests
   - **Expected Log**: `🔐 Checking exact alarm permission...`

2. **Grant/Deny Permissions**:
   - Check logs for permission status
   - **Expected Log**: `✅ Exact alarm permission granted` or `⚠️ Permission denied`

#### Verify in Logs:
```powershell
adb logcat | Select-String "Permission|exact alarm|granted|denied"
```

---

### 7. Analytics Dashboard

#### Test: View Analytics
1. Create several reminders
2. Complete some, skip others
3. Open Analytics screen
4. **Expected Logs**:
   ```
   📊 Loading analytics...
   ✅ Statistics loaded
   📈 Weekly trends: <data>
   ```

#### Verify in Logs:
```powershell
adb logcat | Select-String "analytics|Statistics|trends|insights"
```

---

## 🚀 Phase 2 Features Testing

### 1. Activity Recognition

#### Test: Activity Detection
1. **Start Activity Monitoring**:
   - App automatically starts on launch
   - **Expected Log**: `🏃 Activity monitoring started`

2. **Simulate Walking**:
   - Use emulator location controls
   - Send GPS updates with low speed (1-5 km/h)
   - **Expected Logs**:
     ```
     🏃 Activity changed: Unknown -> Walking
     🔄 Activity changed: Unknown -> Walking (speed: 3.2 km/h)
     ```

3. **Create Activity-Based Reminder**:
   - Note: Activity reminders need `activityType` set (currently via code/database)
   - When activity matches, should trigger
   - **Expected Log**: `🔔 Triggering activity reminder: "<text>" (activity: walking)`

#### Test: Activity Transitions
1. **Walk → Drive**:
   - Change speed from 5 km/h to 60 km/h
   - **Expected Logs**:
     ```
     🔄 Activity changed: Walking -> Driving
     🏃 Activity changed: Walking -> Driving (speed: 60.0 km/h)
     ```

#### Verify in Logs:
```powershell
adb logcat | Select-String "Activity|activity changed|Walking|Driving"
```

---

### 2. Adaptive Timing (Learning Service)

#### Test: Smart Timing Learning
1. **Enable Smart Timing**:
   - Create reminder with `useSmartTiming: true` (currently via database/code)
   - Complete reminder at different times

2. **Learn Patterns**:
   - Complete same reminder 5+ times at 10 AM
   - **Expected Logs**:
     ```
     🧠 Learning optimal timing for reminder: "<id>"
     ✅ Saved learning pattern: optimal hour = 10
     ```

3. **Apply Smart Timing**:
   - Create new reminder with smart timing enabled
   - **Expected Logs**:
     ```
     🧠 Applying Smart Timing...
     ✅ Adjusted time: 10:00 (original: 14:00)
     ```

#### Verify in Logs:
```powershell
adb logcat | Select-String "Learning|Smart Timing|optimal hour|completion rate"
```

---

### 3. Voice Input

#### Test: Voice Recognition
1. **Tap Microphone Button**:
   - On Add Reminder screen
   - **Expected Log**: `🎤 Starting speech recognition...`

2. **Speak Reminder**:
   - Say: "Remind me to call Mom tomorrow at 3 PM"
   - **Expected Logs**:
     ```
     🎤 Speech recognition result: "Remind me to call Mom tomorrow at 3 PM"
     ✅ Speech transcribed successfully
     ```

3. **Check Transcription**:
   - Text should appear in input field
   - Preview should update automatically

#### Verify in Logs:
```powershell
adb logcat | Select-String "Speech|microphone|recognition|transcribed"
```

---

### 4. Enhanced Analytics

#### Test: Weekly Insights
1. **Generate Data**:
   - Create reminders and complete them over time
   - Mix completion times (morning, afternoon, evening)

2. **View Insights**:
   - Open Analytics screen
   - **Expected Logs**:
     ```
     📊 Loading weekly insights...
     📈 Weekly trends loaded: 4 weeks
     ⏰ Best hour: 10:00 (80% completion)
     ⭐ Best day: Monday (75% completion)
     ```

3. **Check Insights Cards**:
   - Should see actionable recommendations
   - **Expected Log**: `💡 Generated 3 insights`

#### Verify in Logs:
```powershell
adb logcat | Select-String "insights|trends|Best hour|Best day|completion rate"
```

---

### 5. Dark Mode

#### Test: Theme Switching
1. **Open Settings**:
   - Go to Settings → Appearance
   - **Expected Log**: `🎨 Theme mode changed: dark`

2. **Toggle Theme**:
   - Switch between Light/Dark/System
   - **Expected Log**: `✅ Theme preference saved`

3. **Verify UI**:
   - All screens should update immediately
   - Colors should match theme

#### Verify in Logs:
```powershell
adb logcat | Select-String "Theme|theme mode|dark mode|light mode"
```

---

## 🔍 Comprehensive Log Filtering

### View All Awarely Logs:
```powershell
adb logcat | Select-String "awarely|Awarely|FLUTTER"
```

### Feature-Specific Filters:
```powershell
# All reminder operations
adb logcat | Select-String "Reminder|reminder"

# All notifications
adb logcat | Select-String "Notification|notification|Alarm"

# All location/context
adb logcat | Select-String "Location|location|geofence|Home|WiFi"

# All learning/smart features
adb logcat | Select-String "Learning|Smart|optimal|pattern"

# All errors
adb logcat | Select-String "ERROR|Error|❌|Exception"
```

### Save Logs to File:
```powershell
adb logcat > awarely_logs.txt
# Then filter:
Select-String -Path awarely_logs.txt -Pattern "TriggerEngine|Activity|Learning"
```

---

## 📊 Testing Checklist

### Phase 1 Checklist:
- [ ] Time-based reminder fires at correct time
- [ ] Recurring reminder fires multiple times
- [ ] Geofence arrival triggers reminder
- [ ] Geofence departure triggers reminder
- [ ] WiFi detection works
- [ ] NLP parses complex inputs correctly
- [ ] Background service runs after app kill
- [ ] Permissions are requested properly
- [ ] Analytics shows correct stats

### Phase 2 Checklist:
- [ ] Activity recognition detects changes
- [ ] Activity-based reminders trigger
- [ ] Smart timing learns from patterns
- [ ] Smart timing adjusts reminder times
- [ ] Voice input transcribes correctly
- [ ] Weekly insights display correctly
- [ ] Dark mode toggles properly
- [ ] Theme persists after restart

---

## 🐛 Debugging Tips

### If Notifications Don't Fire:
1. Check exact alarm permission:
   ```powershell
   adb logcat | Select-String "exact alarm|permission"
   ```
2. Verify alarm was scheduled:
   ```powershell
   adb logcat | Select-String "Alarm scheduled|Occurrence.*scheduled"
   ```
3. Check time validation:
   ```powershell
   adb logcat | Select-String "Time too close|in past|VALIDATION"
   ```

### If Location Reminders Don't Work:
1. Check location permission:
   ```powershell
   adb logcat | Select-String "Location permission|GPS"
   ```
2. Verify location updates:
   ```powershell
   adb logcat | Select-String "Position update|Location changed"
   ```
3. Check home detection:
   ```powershell
   adb logcat | Select-String "Home status|isAtHome"
   ```

### If Activity Recognition Fails:
1. Check location permission (required for activity):
   ```powershell
   adb logcat | Select-String "Activity.*permission|Location.*Activity"
   ```
2. Verify position stream:
   ```powershell
   adb logcat | Select-String "Position stream|speed"
   ```

---

## 📱 Emulator Location Simulation

### Method 1: Android Studio
1. **Extended Controls** (three dots)
2. **Location** tab
3. Enter coordinates or use presets
4. Click "Send"

### Method 2: ADB Commands
```bash
# Set specific location
adb emu geo fix -122.4194 37.7749  # San Francisco

# Simulate movement (walking speed ~5 km/h)
# Send multiple coordinates in sequence
adb emu geo fix -122.4194 37.7749
adb emu geo fix -122.4195 37.7750
adb emu geo fix -122.4196 37.7751

# Simulate driving (high speed, multiple coordinates quickly)
```

---

## ✅ Success Criteria

### Each Feature Should:
1. **Log clearly** what it's doing
2. **Show success/error** with emoji prefixes
3. **Provide context** (IDs, times, values)
4. **Work in background** (test after killing app)

### Expected Behavior:
- ✅ No crashes
- ✅ All features log their activity
- ✅ Notifications fire reliably
- ✅ Background tasks continue working
- ✅ Permissions handled gracefully

---

**Happy Testing! 🚀**

For issues, check logs first using the filters above, then check `PHASE1_PHASE2_VERIFICATION.md` for feature details.
