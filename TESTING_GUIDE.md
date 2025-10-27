# 🧪 Quick Testing Guide - Awarely MVP

## Prerequisites
1. Run `flutter clean`
2. Run `flutter pub get`
3. Connect Android device or start emulator
4. Run `flutter run`

---

## ✅ Test 1: Immediate Notification (30 seconds)

### Steps:
1. Open app → Navigate to **Settings** (gear icon in top right)
2. Scroll down to "Notifications diagnostics"
3. Tap **"Test Notifications"** > **"Send Test"** button
4. **Expected Result:** Immediate notification "✅ Test Notification"
5. Wait 30 seconds
6. **Expected Result:** Second notification "⏰ Test Scheduled"

### Verify:
- [ ] Both notifications appear
- [ ] Notifications are visible even when screen is off
- [ ] Tap notification opens app
- [ ] Go to Settings > Recent Notifications
- [ ] Should see 2 events with "pending" status (blue)
- [ ] Tap an event > "Mark seen" > Status changes to "seen" (green)

**If notifications don't appear:** Check Settings > Permissions and grant all requested permissions.

---

## ✅ Test 2: Scheduled Reminder (5 minutes)

### Steps:
1. Open app → Tap **"+ Add Reminder"** button
2. Type: `Take medicine at [CURRENT_TIME + 5 minutes]`
   - Example: If it's 2:30 PM, type "Take medicine at 2:35 PM"
3. Tap **"Create Reminder"**
4. Time picker appears → Adjust to 5 minutes from now → **Confirm**
5. Check console/logcat for scheduling logs:
   ```
   📅 Scheduling notification id=... title="Reminder" at ...
   ✅ Notification scheduled successfully: true
   ```
6. Go to **Settings > Recent Notifications**
7. **Expected Result:** New event shows "pending" (blue badge)
8. **Wait 5 minutes**
9. **Expected Result:** Notification fires
10. **Tap notification**
11. Go back to Recent Notifications
12. **Expected Result:** Status changed to "seen" (green badge)

### Verify:
- [ ] Reminder created successfully
- [ ] Shows as "pending" in Recent Notifications
- [ ] Notification fires at scheduled time
- [ ] Tapping notification marks it "seen"
- [ ] Reminder shows correct text (not just ID)

---

## ✅ Test 3: Mic Functionality (2 minutes)

### Steps:
1. Open app → **"+ Add Reminder"**
2. Tap **microphone icon** (bottom right of text input)
3. **Expected:** Permission dialog appears (first time only)
4. Grant permission
5. **Expected:** Mic icon changes appearance (listening state)
6. **Speak:** "Remind me to call mom at 7 PM"
7. **Expected:** Text appears in input field
8. **Create reminder** using spoken text

### Verify:
- [ ] Permission requested properly
- [ ] Visual feedback when listening
- [ ] Speech recognized correctly
- [ ] Can create reminder from voice input

**If mic doesn't work:** Go to Settings > Manage Microphone permission.

---

## ✅ Test 4: All Permissions (3 minutes)

### Steps:
1. Go to **Settings** screen
2. Check **Permissions** section
3. **Verify statuses:**
   - Notifications: Should be **Enabled**
   - Exact Alarms: Should be **Enabled**
   - Microphone: May be **Disabled** (enable if testing mic)
   - Location: May be **Disabled** (enable for geofence features)

4. For any disabled permission:
   - Tap **"Manage"** button
   - System settings open
   - Grant permission
   - Return to app
   - **Expected:** Status refreshes automatically

### Verify:
- [ ] All permission statuses display correctly
- [ ] "Manage" buttons open system settings
- [ ] Statuses refresh when returning from settings
- [ ] Exact alarms permission enabled (critical for notifications)

---

## ✅ Test 5: Battery Optimization (2 minutes)

### Steps:
1. Go to **Settings** screen
2. Scroll down to **"Disable Battery Optimization"** button
3. Tap button
4. **Expected:** System dialog appears
5. Grant permission
6. **Why this matters:** Ensures notifications aren't killed by Android

### Verify:
- [ ] Button opens system battery settings
- [ ] Can disable optimization for Awarely

**Note:** This is **critical** for reliable notification delivery, especially on Xiaomi, Huawei, and Samsung devices.

---

## ✅ Test 6: Recent Notifications UI (2 minutes)

### Steps:
1. Create 3 reminders with different times
2. Go to **Settings > Recent Notifications**
3. **Verify:**
   - Shows reminder text (not just ID)
   - Color-coded cards:
     - 🔵 Blue = Pending (scheduled but not fired)
     - 🟢 Green = Seen (user tapped notification)
     - 🟠 Orange = Missed (fired but not tapped)
   - Icons display correctly
   - Tap card shows details dialog
   - "Mark seen" button works

### Verify:
- [ ] All notifications listed with correct text
- [ ] Color coding works
- [ ] Can mark notifications as seen
- [ ] Details dialog shows full info
- [ ] Refresh button works (swipe down or tap icon)

---

## ✅ Test 7: Pending Notifications Count (1 minute)

### Steps:
1. Create 2-3 reminders with future times
2. Go to **Settings** screen
3. Find **"Pending scheduled notifications"** section
4. **Expected:** Shows count (e.g., "3 pending")
5. Tap **refresh icon** to reload
6. **Expected:** List expands showing all pending notifications with IDs and titles

### Verify:
- [ ] Count matches number of created reminders
- [ ] List shows notification details
- [ ] Refresh updates the list

---

## ✅ Test 8: App Closed / Background (10 minutes)

### Steps:
1. Create reminder scheduled for 5 minutes from now
2. Verify it appears in Recent Notifications as "pending"
3. **Close the app completely** (swipe away from recents)
4. **Wait 5 minutes**
5. **Expected:** Notification appears even though app is closed
6. **Tap notification**
7. **Expected:** App opens
8. Check Recent Notifications
9. **Expected:** Status is "seen"

### Verify:
- [ ] Notification fires when app is closed
- [ ] Notification is visible even with screen off
- [ ] Tapping opens app
- [ ] Status tracked correctly

**If notification doesn't fire when app is closed:**
- Check Exact Alarms permission is granted
- Disable battery optimization
- Check manufacturer-specific settings (some phones require additional whitelisting)

---

## 📊 Expected Console Output

When creating a reminder, you should see logs like:

```
📅 Creating reminder: Take medicine
🕐 Scheduled for: 2025-10-27 14:30:00.000
⏰ Time from now: 0:05:00.000000
📅 Scheduling notification id=123456 title="Reminder" at 2025-10-27 14:30:00.000
🔔 TZ Scheduled time: 2025-10-27 14:30:00.000-0700
🕐 Current time: 2025-10-27 14:25:00.000-0700
⏰ Time until notification: 0:05:00.000000
✅ Notification scheduled successfully: true
✅ Recorded scheduled notification for reminder abc-123-def at 2025-10-27 14:30:00.000
```

At startup, you should see:
```
📱 Exact alarm permission: true
```

If false, you'll see:
```
📱 Exact alarm permission: false
⚠️ Exact alarm permission not granted. Notifications may not be reliable.
```

---

## 🐛 Troubleshooting

### Notifications Not Appearing

**Check:**
1. ✅ Notification permission granted (Settings > Permissions)
2. ✅ Exact Alarm permission granted (Settings > Exact Alarms)
3. ✅ Battery optimization disabled (Settings > Battery)
4. ✅ Test notification works (Settings > Test Notifications)
5. ✅ Console shows "✅ Notification scheduled successfully: true"

**Common Issues:**
- **Xiaomi/Huawei/Samsung:** Enable "Autostart" permission in system settings
- **Android 12+:** Must grant "Alarms & reminders" permission
- **Battery Saver Mode:** May prevent notifications; disable or whitelist app

### Recent Notifications Empty

**Check:**
1. Create a new reminder → Should appear immediately as "pending"
2. Check console for "✅ Recorded scheduled notification" log
3. Tap test notification button → Should create events

**If still empty:** Database may not be initialized. Try:
```bash
flutter clean
flutter run
```

### Mic Not Working

**Check:**
1. Settings > Microphone shows "Enabled"
2. Console shows no errors when tapping mic button
3. Try granting permission via system settings if denied

---

## 🎯 Success Criteria

**MVP is working if:**
- ✅ Notifications fire at scheduled time (app open or closed)
- ✅ Recent Notifications shows all scheduled and delivered notifications
- ✅ Tapping notifications marks them as "seen"
- ✅ Test button works
- ✅ Mic input works
- ✅ All permissions can be granted
- ✅ Color coding and UI polish visible

---

## 📱 Testing on Device

**Recommended:**
- Test on real device (not just emulator)
- Test with screen off
- Test with app closed for extended period (30+ minutes)
- Test after device reboot

**Device Requirements:**
- Android 8.0+ (API 26+)
- Notifications enabled in system settings
- Sufficient storage for database

---

## 🔄 After Testing

**Report results:**
1. Which tests passed ✅
2. Which tests failed ❌
3. Console logs for failed tests
4. Device model and Android version
5. Any error messages

**If all tests pass:** MVP is ready for production testing! 🎉
