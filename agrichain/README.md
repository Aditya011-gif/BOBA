# Agrichain

Production-ready Flutter app for an agricultural marketplace with ratings, loans, wallets, and optional blockchain integrations.

This README documents the project structure, setup, environment, build/run instructions, and key modules so that tools and contributors can understand and work with the codebase effectively.

## Overview

- Cross-platform Flutter app targeting Android, Web, Windows, macOS, and Linux.
- Uses Firebase (Firestore, Auth, Storage, Messaging, Crashlytics) for backend services.
- Optional blockchain integration via `web3dart` and `wallet` with example smart contracts and deployment scripts.
- State management via `Provider` (see `lib/providers/app_state.dart`).

## Quick Start

Prerequisites:
- Flutter SDK installed (`flutter --version`).
- Dart SDK ships with Flutter.
- Firebase project configured (required for production features).

Install dependencies:
- `flutter pub get`

Run (Web):
- `flutter run -d chrome`

Run (Windows desktop):
- `flutter run -d windows`

Run (Android device/emulator):
- `flutter devices` then `flutter run -d <device_id>`

Build Android release APK:
- `flutter build apk --release`
- Output: `build/app/outputs/flutter-apk/app-release.apk`

Note: This project’s Android release config currently disables code minification and resource shrinking to avoid compatibility issues with certain libraries.

## Project Structure

Top-level folders:
- `agrichain/android` — Gradle, app module, ProGuard rules, signing configs.
- `agrichain/ios` — Xcode project/workspace, iOS runner.
- `agrichain/lib` — Main Flutter application code.
- `agrichain/docs` — Setup and integration guides.
- `agrichain/test` — Unit and widget tests.
- `contracts` — Example Solidity smart contracts.
- `scripts` — Node/TypeScript deployment scripts for blockchain.

Key Dart folders (inside `agrichain/lib`):
- `main.dart` — Application entry point.
- `config/` — App configuration and constants.
- `models/` — Data models (e.g., `firestore_models.dart` defines enums and models such as `Rating`, `UserRatingStats`, etc.).
- `providers/` — App state (e.g., `app_state.dart` manages authentication, ratings, marketplace data).
- `services/` — External services (e.g., `database_service.dart` wraps Firestore and related operations).
- `screens/` — Feature screens (e.g., marketplace, profile, loans, ratings).
- `widgets/` — Reusable UI components (e.g., `crop_card.dart`, `rating_widgets.dart`, `stat_card.dart`).
- `theme/` — Color schemes and theming utilities.
- `utils/` — Helper functions and utilities.

Web assets:
- `agrichain/web/` — `index.html`, icons, web manifests, and WebAssembly files.

## Configuration

Environment variables:
- See `agrichain/.env.example` for required keys and formats.

Firebase config:
- Android: place `google-services.json` in `agrichain/android/app/`.
- iOS: place `GoogleService-Info.plist` in `agrichain/ios/Runner/`.
- Dart: `lib/firebase_options.dart` contains generated options via `flutterfire configure`.

Android build settings:
- `agrichain/android/app/build.gradle.kts` — Release config with `isMinifyEnabled = false` and `isShrinkResources = false`.
- `agrichain/android/app/proguard-rules.pro` — Custom rules for compatibility.

## Key Modules and Responsibilities

- `lib/models/firestore_models.dart`
  - Enums: `RatingType`, `UserType`, `LoanStatus`, `OrderStatus`, etc.
  - Models: `FirestoreUser`, `Rating`, `UserRatingStats` with Firestore serialization.

- `lib/providers/app_state.dart`
  - Central state for user, ratings, marketplace data.
  - Exposes methods: `addRating`, `getRatingsForUser`, `calculateRatingStats`.

- `lib/services/database_service.dart`
  - Firestore access: read/write ratings and stats.
  - Methods: `getRatingsForUser`, `calculateRatingStats`, `updateUserRatingStats`.

- `lib/widgets/rating_widgets.dart`
  - `StarRatingDisplay`, `ReviewCard`, `RatingSummary` UI components.
  - Requires models from `firestore_models.dart`.

- `lib/widgets/crop_card.dart`
  - Core marketplace card UI with ellipsis and responsive layouts to avoid overflow.

- `lib/screens/marketplace_screen.dart`, `lib/screens/profile_screen.dart`, `lib/screens/loans_screen.dart`, `lib/screens/rating_screen.dart`
  - Feature screens that compose widgets and provider state.

## Run and Build

Install:
- `flutter pub get`

Debug (Chrome):
- `flutter run -d chrome`

Debug (Android):
- Ensure an emulator/device is connected, then `flutter run -d <device_id>`.

Release APK:
- `flutter build apk --release`
- Result: `build/app/outputs/flutter-apk/app-release.apk`

Windows desktop:
- `flutter run -d windows`

## Testing and Quality

- Run tests: `flutter test`
- Linting: `flutter analyze`
- Format: `dart format .`

## Troubleshooting

- Android build fails due to shrink/ProGuard:
  - Release build disables code minification and resource shrink: check `android/app/build.gradle.kts`.
  - ProGuard rules include keep directives for libraries used.

- Web compile errors referencing models:
  - Ensure `lib/models/firestore_models.dart` is imported in UI widgets using `Rating`, `UserRatingStats`, and enums.
  - Run `flutter clean` then `flutter pub get` if type resolution issues persist.

- Firebase setup:
  - Verify `google-services.json` and `GoogleService-Info.plist` are in the correct locations.
  - Confirm `firebase_options.dart` exists and matches your Firebase project.

## Blockchain (Optional)

- Contracts: `contracts/` includes sample Solidity files and tests.
- Deployment: `scripts/` provides `deploy_with_ethers.ts` and `deploy_with_web3.ts` for contract deployment.

## Build Artifacts

- Android APK: `agrichain/build/app/outputs/flutter-apk/app-release.apk`
- APK SHA1: `agrichain/build/app/outputs/flutter-apk/app-release.apk.sha1`

## Documentation

- See `agrichain/docs/` for detailed guides:
  - `API_INTEGRATION_GUIDE.md`
  - `CONFIGURATION_SETUP.md`
  - `DIGILOCKER_SANDBOX_SETUP.md`
  - `INFURA_SETUP_GUIDE.md`
  - `MOCK_DIGILOCKER_DEMO_GUIDE.md`

---
For contributions, keep changes minimal and consistent with existing patterns. Focus on clear feature boundaries, avoid unrelated refactors, and update documentation when behavior or interfaces change.
