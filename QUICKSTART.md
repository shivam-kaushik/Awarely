# 🚀 Quick Start Guide - Awarely

This guide will help you get Awarely up and running in **under 10 minutes**.

---

## Prerequisites Checklist

Before you begin, ensure you have:

- ✅ **Flutter SDK** (3.24+): [Install Flutter](https://docs.flutter.dev/get-started/install)
- ✅ **Android Studio** or **Xcode** (for simulators/emulators)
- ✅ **Git**: [Download Git](https://git-scm.com/downloads)
- ✅ **VS Code** or **Android Studio** (recommended IDEs)

Verify your Flutter installation:

```powershell
flutter doctor
```

You should see all checkmarks (✓). If not, follow the prompts to install missing components.

---

## Step 1: Clone the Repository

```powershell
# Navigate to your projects folder
cd c:\Users\Public\Documents\Learning

# Clone the repo (or use your fork)
git clone https://github.com/yourusername/awarely.git
cd awarely
```

---

## Step 2: Install Dependencies

```powershell
# Fetch all packages from pubspec.yaml
flutter pub get
```

**Expected Output:**
```
Running "flutter pub get" in awarely...
Resolving dependencies... 
Got dependencies!
```

---

## Step 3: Platform-Specific Configuration

### Android Setup

#### 3.1 Edit `android/app/src/main/AndroidManifest.xml`

Add the following permissions **inside** the `<manifest>` tag (before `<application>`):

```xml
<!-- Location Permissions -->
<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
<uses-permission android:name="android.permission.ACCESS_BACKGROUND_LOCATION"/>

<!-- Notification Permission (Android 13+) -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>

<!-- Background Task Permissions -->
<uses-permission android:name="android.permission.WAKE_LOCK"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>

<!-- Internet for future cloud sync -->
<uses-permission android:name="android.permission.INTERNET"/>
```

#### 3.2 Update Minimum SDK Version

In `android/app/build.gradle`, ensure:

```gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 21  // Required for workmanager
        targetSdkVersion 34
    }
}
```

### iOS Setup

#### 3.3 Edit `ios/Runner/Info.plist`

Add location permission descriptions **inside** the `<dict>` tag:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Awarely needs location to trigger reminders at the right place</string>

<key>NSLocationAlwaysUsageDescription</key>
<string>Awarely monitors location in background to provide context-aware reminders</string>

<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>Awarely needs location access to trigger reminders based on your context</string>

<key>UIBackgroundModes</key>
<array>
  <string>location</string>
  <string>fetch</string>
</array>
```

#### 3.4 Update iOS Deployment Target

In `ios/Podfile`, ensure:

```ruby
platform :ios, '12.0'
```

Then run:

```powershell
cd ios
pod install
cd ..
```

---

## Step 4: Run the App

### On Android Emulator

1. Open Android Studio → AVD Manager
2. Start an emulator (API 30+ recommended)
3. In terminal:

```powershell
flutter run
```

### On iOS Simulator

1. Open Xcode → Window → Devices and Simulators
2. Start an iPhone simulator
3. In terminal:

```powershell
flutter run
```

### On Physical Device

#### Android
1. Enable Developer Options on your device
2. Enable USB Debugging
3. Connect via USB
4. Run: `flutter run`

#### iOS
1. Connect iPhone via USB
2. Open Xcode → select your device as target
3. Trust developer certificate
4. Run: `flutter run`

**Expected Output:**
```
Launching lib/main.dart on iPhone 14 in debug mode...
Running Xcode build...
✓ Built build/ios/iphoneos/Runner.app
```

---

## Step 5: Grant Permissions (First Launch)

When the app opens:

1. **Onboarding Screen** appears
2. Tap **"Get Started"** or **"Next"**
3. Grant permissions when prompted:
   - ✅ **Location** → "Allow While Using App" → "Change to Always Allow"
   - ✅ **Notifications** → "Allow"

---

## Step 6: Create Your First Reminder

1. On the **Home Screen**, tap **"+ Add Reminder"**
2. Type or speak:
   ```
   Remind me to take my vitamin when I wake up
   ```
3. Tap **"Create Reminder"**
4. See it appear in your reminder list with ⏰ icon

---

## Testing Context Triggers

### Test Time-Based Reminder

```
Remind me to drink water at 3:30 PM
```

- Wait until 3:30 PM
- Notification should appear

### Test Location-Based Reminder

```
Remind me to turn off lights when leaving home
```

- Set "home" location (future feature)
- Walk away from home
- Notification triggers when you exit geofence

---

## Troubleshooting

### Issue: "Target of URI doesn't exist" errors

**Solution**: Run `flutter pub get` again. These errors are expected before dependencies are fetched.

### Issue: Android build fails with "Execution failed for task ':app:processDebugResources'"

**Solution**: 
```powershell
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter run
```

### Issue: iOS "No development team selected"

**Solution**:
1. Open `ios/Runner.xcworkspace` in Xcode
2. Select Runner in left panel
3. Go to "Signing & Capabilities"
4. Select your Apple ID team

### Issue: Notifications not appearing

**Solution**:
1. Check device settings → Apps → Awarely → Notifications → Enabled
2. For iOS: Settings → Awarely → Notifications → Allow Notifications

### Issue: Location not updating

**Solution**:
1. Ensure location services are enabled
2. Grant "Always Allow" location permission
3. For Android: Settings → Apps → Awarely → Permissions → Location → Allow all the time

---

## Running Tests

```powershell
# Run unit tests
flutter test

# Run with coverage
flutter test --coverage

# View coverage report (requires lcov)
genhtml coverage/lcov.info -o coverage/html
```

---

## Building for Release

### Android APK

```powershell
flutter build apk --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (for Play Store)

```powershell
flutter build appbundle --release
```

Output: `build/app/outputs/bundle/release/app-release.aab`

### iOS (requires Mac + Xcode)

```powershell
flutter build ios --release
```

Then open `ios/Runner.xcworkspace` in Xcode and archive.

---

## Next Steps

1. **Explore Features**: Try different reminder phrases
2. **Check Analytics**: Tap analytics icon to see stats
3. **Customize Settings**: (Coming soon)
4. **Join Community**: [Discord](https://discord.gg/awarely)

---

## Development Workflow

### Hot Reload (during development)

- Press `r` in terminal to hot reload
- Press `R` to hot restart
- Press `q` to quit

### Debug with VS Code

1. Open `awarely` folder in VS Code
2. Install "Flutter" extension
3. Press `F5` to start debugging
4. Set breakpoints in code

---

## Environment Variables (Optional)

For cloud features (future), create `.env` file:

```env
FIREBASE_API_KEY=your_key_here
OPENAI_API_KEY=your_key_here
```

Then load with `flutter_dotenv` package.

---

## Useful Commands

```powershell
# Check Flutter version
flutter --version

# Update Flutter SDK
flutter upgrade

# Analyze code quality
flutter analyze

# Format code
flutter format lib/

# Clean build artifacts
flutter clean

# Check for outdated packages
flutter pub outdated
```

---

## Resources

- **Documentation**: [ARCHITECTURE.md](./ARCHITECTURE.md)
- **Investor Deck**: [INVESTOR_SUMMARY.md](./INVESTOR_SUMMARY.md)
- **Bug Reports**: [GitHub Issues](https://github.com/yourusername/awarely/issues)
- **Feature Requests**: [GitHub Discussions](https://github.com/yourusername/awarely/discussions)

---

## Support

Need help? Contact us:

- **Email**: support@awarely.app
- **Discord**: [Join Server](https://discord.gg/awarely)
- **Twitter**: [@AwarelyApp](https://twitter.com/AwarelyApp)

---

**Happy Reminding! 🔔**

✅ Prototype ready — run `flutter run` to experience Awarely.
