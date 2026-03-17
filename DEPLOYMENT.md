# Personal Health Insight Tracker — Deployment Guide

This document outlines the steps to build and deploy the application for production on Android and iOS.

## 1. Prerequisites
- **Flutter SDK**: Ensure you are on the `stable` channel.
- **Firebase**: Project must be configured in [Firebase Console](https://console.firebase.google.com/).
- **RevenueCat**: API Keys and Entitlements configured for subscriptions.
- **OpenAI**: Secret key set in environment or secure vault.

## 2. Environment Configuration
Ensure your `lib/services/ai_insight_service.dart` or `.env` file is populated with production keys.

## 3. Android Deployment
### Release Build
```bash
# 1. Clean build artifacts
flutter clean

# 2. Get dependencies
flutter pub get

# 3. Build App Bundle (for Play Store)
flutter build appbundle --release

# 4. Build APK (for testing)
flutter build apk --release
```
### Signing
- Create an `upload-keystore.jks`.
- Configure `android/key.properties`.
- Update `android/app/build.gradle` to use the signing configuration.

---

## 4. iOS Deployment
### Release Build
```bash
# 1. Open Xcode project
open ios/Runner.xcworkspace

# 2. Configure Signing & Capabilities (Profiles)
# 3. Build the Archive
flutter build ipa --release
```
### App Store Connect
- Use **Transporter** or Xcode to upload the `.ipa` to App Store Connect.

---

## 5. CI/CD Recommendations
- **GitHub Actions**: Automate unit and widget tests on every PR.
- **Codemagic**: Recommended for Flutter cloud builds and automatic store distribution.

## 6. Testing Checklist before Release
- [ ] Run all unit tests: `flutter test`
- [ ] Verify ProGuard/R8 rules for Android.
- [ ] Check iOS `Info.plist` for Notification and Network permissions.
- [ ] Verify Firebase Remote Config (if used) for production toggles.
