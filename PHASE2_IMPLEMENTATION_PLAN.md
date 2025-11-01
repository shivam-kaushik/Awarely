# Phase 2: Beta - Enhanced Context Implementation Plan

## Overview
Phase 2 focuses on enhancing context awareness, user experience, and adding intelligent features that make the app more valuable and personalized.

**Timeline**: 8 weeks (2 months)  
**Status**: 🚀 Starting Implementation

---

## Feature Breakdown & Implementation Order

### Week 1-2: Foundation & Quick Wins

#### 1. Dark Mode Polish ✅ (Priority: High)
- **Duration**: 2-3 days
- **Tasks**:
  - Review current theme implementation
  - Ensure all screens respect dark mode
  - Add theme toggle in settings
  - Test contrast and readability
- **Dependencies**: Material 3 theming (already in place)
- **Impact**: Better UX, follows system preferences

#### 2. Voice Input for Reminder Creation ✅ (Priority: High)
- **Duration**: 3-4 days
- **Tasks**:
  - Integrate `speech_to_text` package
  - Add microphone button to Add Reminder screen
  - Handle permissions (microphone access)
  - Show real-time transcription
  - Fallback to text input if speech fails
- **Dependencies**: `speech_to_text: ^6.0.0`
- **Impact**: Faster reminder creation, accessibility improvement

#### 3. Enhanced Analytics - Weekly Insights ✅ (Priority: Medium)
- **Duration**: 4-5 days
- **Tasks**:
  - Create WeeklyInsightsService
  - Track completion rates by day/time
  - Show completion trends
  - Identify peak reminder times
  - Add insights card to home screen
- **Dependencies**: Existing analytics infrastructure
- **Impact**: User self-awareness, motivation

---

### Week 3-4: Context & Intelligence

#### 4. Activity Recognition ✅ (Priority: High)
- **Duration**: 5-7 days
- **Tasks**:
  - Integrate `activity_recognition` or use `geolocator` activity stream
  - Detect: walking, running, driving, stationary, cycling
  - Store activity context in ContextEvent
  - Add activity-based trigger conditions
  - Update TriggerEngine to handle activity triggers
  - Add UI to set reminders based on activity
- **Dependencies**: `activity_recognition: ^2.0.0` or Android/iOS native APIs
- **Impact**: More contextual reminders (e.g., "When I start driving")

#### 5. Adaptive Timing - Learned Patterns ✅ (Priority: High)
- **Duration**: 7-10 days
- **Tasks**:
  - Create LearningService to analyze completion patterns
  - Track: user's typical response times, completion rates by time of day
  - Learn optimal reminder timing
  - Adjust future reminders based on patterns
  - Add "Smart Timing" toggle in reminder settings
- **Dependencies**: Analytics data, SQLite for pattern storage
- **Impact**: Higher completion rates, less reminder fatigue

---

### Week 5-6: Social & Multi-Device

#### 6. Shared Reminders (Family/Caregiver Mode) ✅ (Priority: Medium)
- **Duration**: 10-12 days
- **Tasks**:
  - Set up Firebase Authentication
  - Create Firestore collections: shared_reminders, user_groups
  - Build UI for sharing reminders
  - Implement permission levels (view-only, edit, full access)
  - Sync reminder completions across devices
  - Add "Shared with me" section in home screen
- **Dependencies**: Firebase Auth, Firestore
- **Impact**: Caregiver support, family coordination

#### 7. Widget Support ✅ (Priority: Medium)
- **Duration**: 4-5 days
- **Tasks**:
  - Create home screen widget using `home_widget` package
  - Show upcoming reminders (next 3-5)
  - Quick action: Mark complete from widget
  - Refresh widget when reminders update
  - Support Android and iOS widgets
- **Dependencies**: `home_widget: ^0.5.0`
- **Impact**: Quick access without opening app

---

### Week 7-8: Advanced Features & Polish

#### 8. Smartwatch Integration ✅ (Priority: Medium)
- **Duration**: 8-10 days
- **Tasks**:
  - Set up Wear OS plugin
  - Create watch companion app (minimal UI)
  - Show active reminders on watch
  - Allow marking complete from watch
  - Vibration patterns for different priorities
  - Handle watch-only notifications
- **Dependencies**: Wear OS development environment, `wear` package
- **Impact**: Convenience, especially for health reminders

---

## Technical Implementation Details

### Database Schema Updates

```sql
-- Activity Recognition
ALTER TABLE context_events ADD COLUMN activity_type TEXT;

-- Learning/Adaptive
CREATE TABLE learning_patterns (
  id TEXT PRIMARY KEY,
  user_id TEXT,
  reminder_text_pattern TEXT,
  optimal_time_hour INTEGER,
  optimal_time_minute INTEGER,
  completion_rate REAL,
  avg_response_time_seconds INTEGER,
  sample_count INTEGER,
  last_updated INTEGER
);

-- Shared Reminders
ALTER TABLE reminders ADD COLUMN shared_with_users TEXT; -- JSON array
ALTER TABLE reminders ADD COLUMN owner_id TEXT;
ALTER TABLE reminders ADD COLUMN sharing_enabled INTEGER DEFAULT 0;
```

### New Services to Create

1. **ActivityRecognitionService**
   - Monitor device activity
   - Provide activity stream
   - Battery-efficient implementation

2. **LearningService**
   - Analyze completion patterns
   - Calculate optimal timing
   - Suggest improvements

3. **SharedRemindersService**
   - Handle Firebase sync
   - Manage permissions
   - Conflict resolution

4. **WidgetService**
   - Update widget data
   - Handle widget interactions

### UI Components

1. **VoiceInputButton** - Microphone button with waveform animation
2. **WeeklyInsightsCard** - Visual charts for completion trends
3. **ActivityTriggerDialog** - Select activity type for triggers
4. **ShareReminderDialog** - Share reminder with contacts
5. **WidgetPreviewScreen** - Preview widget appearance

---

## Dependencies to Add

```yaml
# pubspec.yaml additions
dependencies:
  # Voice Input
  speech_to_text: ^6.0.0
  
  # Activity Recognition
  activity_recognition: ^2.0.0  # Or use geolocator's activity stream
  
  # Firebase (for shared reminders)
  firebase_core: ^2.24.0
  firebase_auth: ^4.15.0
  cloud_firestore: ^4.13.0
  
  # Widgets
  home_widget: ^0.5.0
  
  # Charts (for analytics)
  fl_chart: ^0.65.0
  
  # Wear OS
  wear: ^1.2.0  # If available, or use platform channels
```

---

## Success Criteria

- [ ] Dark mode works seamlessly across all screens
- [ ] Voice input accuracy > 85% for common phrases
- [ ] Weekly insights show meaningful patterns
- [ ] Activity recognition detects 4+ activity types reliably
- [ ] Adaptive timing improves completion rates by 15%+
- [ ] Shared reminders sync in < 2 seconds
- [ ] Widget updates within 30 seconds of reminder change
- [ ] Smartwatch shows notifications and allows interactions

---

## Risk Mitigation

1. **Battery Drain (Activity Recognition)**
   - Use low-power APIs
   - Sample at reasonable intervals (every 30-60 seconds)
   - Allow users to disable

2. **Privacy (Shared Reminders)**
   - End-to-end encryption
   - Clear privacy controls
   - Opt-in sharing only

3. **Complexity (Adaptive Learning)**
   - Start with simple patterns
   - Show explanations to users
   - Allow manual override

---

## Next Steps

1. ✅ Review and approve plan
2. ⏳ Start with Week 1 features (Dark Mode, Voice Input)
3. ⏳ Set up Firebase project (for shared reminders)
4. ⏳ Test activity recognition APIs
5. ⏳ Create database migrations

---

## Notes

- Prioritize features that provide immediate user value
- Maintain backward compatibility
- Add comprehensive logging for debugging
- Test battery impact of new features
- Ensure accessibility for all features

