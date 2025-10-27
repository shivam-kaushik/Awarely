# 🔔 Awarely - The Context-Aware Reminder Assistant

**Never forget what matters — Awarely thinks in context, not in clocks.**

![Version](https://img.shields.io/badge/version-1.0.0-blue)
![Flutter](https://img.shields.io/badge/Flutter-3.24-02569B?logo=flutter)
![License](https://img.shields.io/badge/license-MIT-green)

---

## 📖 Table of Contents

1. [Vision & Problem](#vision--problem)
2. [Key Features](#key-features)
3. [Technology Stack](#technology-stack)
4. [Project Structure](#project-structure)
5. [Installation & Setup](#installation--setup)
6. [Permissions Required](#permissions-required)
7. [Usage Guide](#usage-guide)
8. [Architecture Overview](#architecture-overview)
9. [Roadmap](#roadmap)
10. [Testing](#testing)
11. [Contributing](#contributing)
12. [Business Model](#business-model)
13. [License](#license)

---

## 🎯 Vision & Problem

### Problem Statement
Traditional reminder apps use fixed timestamps; they remind even when the user is not in the relevant situation (e.g., still at home when a 'leave for work' reminder fires). Human forgetfulness is **contextual** — dependent on place, motion, and mental state.

### Solution
Awarely is an AI-driven reminder system that fuses **time, geolocation, motion, Bluetooth/Wi-Fi state, and learned routine data** to trigger reminders when the real-world situation matches the user's intent.

### Innovation
- **AI-powered Context Engine**: Combines multiple sensor inputs
- **Adaptive Learning**: Learns from user patterns and feedback
- **Natural Language Understanding**: Parses human-like reminder inputs

---

## ✨ Key Features

### MVP (Phase 1)
- ✅ Natural language reminder input ("Remind me to carry my ID when I leave home at 8 AM")
- ✅ Context detection via time, GPS geofence, Wi-Fi connect/disconnect
- ✅ Smart notification triggering based on context match
- ✅ Simple dashboard with active reminders and completion stats
- ✅ Offline-first with local SQLite database
- ✅ Background service for context monitoring

### Beta (Phase 2 - Planned)
- 🔄 Activity recognition (walking/driving/stationary)
- 🔄 Adaptive timing based on learned routines
- 🔄 Smartwatch integration (Wear OS + watchOS)
- 🔄 Shared reminders for family/caregivers
- 🔄 Advanced analytics with completion trends

### Pro (Phase 3 - Planned)
- 🚀 Predictive reminders (anticipate unspoken needs)
- 🚀 IoT triggers and automations
- 🚀 Voice assistant integration (Alexa, Google, Siri)
- 🚀 Cloud sync and multi-device support
- 🚀 Privacy dashboard with opt-in telemetry

---

## 🛠️ Technology Stack

| Layer | Technology |
|-------|-----------|
| **Framework** | Flutter 3.24 + Dart 3 |
| **UI Design** | Material Design 3 + Google Fonts |
| **State Management** | Provider Pattern |
| **Local Database** | SQLite (sqflite) |
| **Context APIs** | geolocator, geofence_service, connectivity_plus |
| **Background Tasks** | workmanager |
| **Notifications** | flutter_local_notifications + timezone |
| **NLU** | Custom parser + OpenAI GPT-4 (future) |
| **Cloud (Future)** | Firebase Auth, Firestore, Cloud Functions |
| **Analytics** | Firebase Analytics / Mixpanel |

---

## 📁 Project Structure

```
awarely/
├── lib/
│   ├── main.dart                          # App entry point
│   ├── core/
│   │   ├── constants/
│   │   │   └── app_constants.dart         # App-wide constants
│   │   ├── utils/
│   │   │   └── date_time_utils.dart       # Date/time utilities
│   │   └── services/
│   │       ├── notification_service.dart   # Local notifications
│   │       ├── permission_service.dart     # Permission handling
│   │       ├── nlu_parser.dart            # Natural language parser
│   │       └── trigger_engine.dart        # Context monitoring engine
│   ├── data/
│   │   ├── models/
│   │   │   ├── reminder.dart              # Reminder model
│   │   │   ├── context_event.dart         # Context event model
│   │   │   └── saved_location.dart        # Saved location model
│   │   ├── database/
│   │   │   └── database_helper.dart       # SQLite database helper
│   │   └── repositories/
│   │       └── reminder_repository.dart   # Data access layer
│   └── presentation/
│       ├── theme/
│       │   └── app_theme.dart             # Material 3 theme
│       ├── providers/
│       │   └── reminder_provider.dart     # State management
│       ├── screens/
│       │   ├── splash_screen.dart         # Splash screen
│       │   ├── onboarding_screen.dart     # First-time onboarding
│       │   ├── home_screen.dart           # Main dashboard
│       │   ├── add_reminder_screen.dart   # Add/edit reminder
│       │   └── analytics_screen.dart      # Statistics & insights
│       └── widgets/
│           └── reminder_card.dart         # Reminder list item widget
├── assets/
│   ├── images/                            # App images
│   ├── icons/                             # App icons
│   └── animations/                        # Lottie animations
├── test/                                  # Unit & widget tests
├── pubspec.yaml                           # Dependencies
├── analysis_options.yaml                  # Linter rules
└── README.md                              # This file
```

---

## 🚀 Installation & Setup

### Prerequisites

- **Flutter SDK**: 3.24 or higher
- **Dart SDK**: 3.2 or higher
- **Android Studio** / **Xcode** (for iOS)
- **Git**

### Step 1: Clone Repository

```powershell
git clone https://github.com/yourusername/awarely.git
cd awarely
```

### Step 2: Install Dependencies

```powershell
flutter pub get
```

### Step 3: Platform-Specific Setup

#### Android (AndroidManifest.xml)

Add permissions to `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

#### iOS (Info.plist)

Add to `ios/Runner/Info.plist`:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Awarely needs location to trigger reminders at the right place</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>Awarely monitors location in background to provide context-aware reminders</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Awarely needs location access to trigger reminders based on your context</string>
```

### Step 4: Run the App

```powershell
# Run on connected device or emulator
flutter run

# Build for release
flutter build apk       # Android
flutter build ios       # iOS
```

---

## 🔐 Permissions Required

| Permission | Purpose | Required |
|-----------|---------|----------|
| **Location (Foreground)** | Geofence detection when app is open | Yes |
| **Location (Background)** | Context monitoring in background | Yes |
| **Notifications** | Display reminder alerts | Yes |
| **Wi-Fi State** | Detect home/office arrival | Optional |
| **Boot Completed** | Restart background service after reboot | Yes |

---

## 📱 Usage Guide

### Adding a Reminder

1. Tap the **"+ Add Reminder"** button on home screen
2. Type or speak your reminder using natural language:
   - "Remind me to take my vitamin when I wake up"
   - "Remind me to turn off the AC when I leave home"
   - "Remind me to call Mom at 8 PM"
3. The app automatically parses:
   - **Task**: What to do
   - **Context**: Time, location, or event trigger
4. Tap **"Create Reminder"**

### Viewing Reminders

- **Home Screen**: Shows all active reminders with context icons
  - ⏰ Time-based
  - 📍 Location-based
  - 📶 Wi-Fi-based
  - 🚪 Leaving trigger
  - 🏠 Arriving trigger

### Analytics

- Tap the **Analytics** icon to view:
  - Completion rate percentage
  - Total reminders created
  - Active reminders count
  - Completion history

---

## 🏗️ Architecture Overview

### Clean Architecture Layers

```
┌─────────────────────────────────────┐
│      Presentation Layer              │
│  (UI, Screens, Widgets, Providers)   │
└──────────────┬──────────────────────┘
               │
┌──────────────┴──────────────────────┐
│      Business Logic Layer            │
│  (Services, Trigger Engine, NLU)     │
└──────────────┬──────────────────────┘
               │
┌──────────────┴──────────────────────┐
│      Data Layer                      │
│  (Models, Database, Repositories)    │
└──────────────────────────────────────┘
```

### Context Trigger Flow

```
User Input → NLU Parser → Extract Context
                             ↓
            Create Reminder → Database
                             ↓
Background Service → Monitor Sensors (GPS, Wi-Fi, Time)
                             ↓
        Context Matched? → Trigger Notification
                             ↓
            User Action → Log Event → Update Stats
```

### Key Components

1. **NLU Parser**: Extracts task, time, location, and trigger type from natural language
2. **Trigger Engine**: Monitors sensors and matches context patterns
3. **Notification Service**: Manages local notifications with priority
4. **Database Helper**: SQLite operations with migrations support
5. **Reminder Repository**: Data access abstraction layer

---

## 🗺️ Roadmap

| Phase | Timeline | Features |
|-------|----------|----------|
| **MVP** | Month 1-3 | Basic reminders, time/location triggers, local storage |
| **Beta** | Month 4-5 | Activity recognition, smartwatch, shared reminders |
| **Launch** | Month 6 | Product Hunt launch, marketing campaign |
| **Pro** | Month 7-9 | Predictive AI, IoT integration, cloud sync |
| **Scale** | Month 10-12 | B2B partnerships, white-label licensing |

---

## 🧪 Testing

### Run Unit Tests

```powershell
flutter test
```

### Run Integration Tests

```powershell
flutter test integration_test/
```

### Test Coverage

```powershell
flutter test --coverage
```

### Example Test Scenarios

- NLU parser correctly extracts time ("at 8 PM")
- NLU parser identifies location context ("when leaving home")
- Database CRUD operations work correctly
- Reminder state toggles properly
- Notification scheduling is accurate

---

## 🤝 Contributing

We welcome contributions! Please follow these steps:

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `git commit -m 'Add amazing feature'`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open a Pull Request

### Code Style

- Follow Dart style guide
- Use `flutter format` before committing
- Add comments for complex logic
- Write tests for new features

---

## 💰 Business Model

| Tier | Features | Price |
|------|----------|-------|
| **Free** | Up to 10 reminders/day, time + Wi-Fi triggers | $0 |
| **Pro** | Unlimited reminders, wearable sync, analytics | $4.99/month |
| **Family** | Shared reminders, caregiver monitoring | $9.99/month |
| **B2B API** | Context Trigger SDK for partners | Custom License |

---

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

---

## 🌟 Acknowledgments

- Flutter team for the amazing framework
- Material Design 3 for beautiful UI components
- Open-source community for incredible packages

---

## 📞 Contact & Support

- **Website**: [awarely.app](https://awarely.app)
- **Email**: support@awarely.app
- **Twitter**: [@AwarelyApp](https://twitter.com/AwarelyApp)
- **Discord**: [Join Community](https://discord.gg/awarely)

---

## 🚦 Status

- ✅ **Core Features**: Complete
- ✅ **MVP Build**: Ready for testing
- 🔄 **Beta Features**: In progress
- 🚀 **Production Launch**: Q2 2025

---

**Built with ❤️ by the Awarely Team**

---

## ✅ Prototype Ready

Run the following command to experience Awarely:

```powershell
flutter run
```

**Note**: Make sure to grant all required permissions on first launch for full functionality.
