# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**SnapRep** is a Flutter fitness app that enables users to "exercise anywhere, anytime with objects at hand." The core concept is: Target muscle group → Available objects → 3 safe exercise recommendations.

**Key Product Principles:**
- **Offline-First**: Fully functional without internet connection
- **Safety-First**: All exercises from curated safe whitelist with contraindications
- **Speed**: ≤30 seconds from app open to 3 exercise recommendations (P75)
- **Object-Aware**: Uses everyday objects (chair, backpack, water bottle, etc.)

## Architecture Status

**Current State**: Early development with Flutter scaffolding complete but only template code in `lib/main.dart`

**Target Architecture**: Clean Architecture with feature-based modules:
```
lib/
├── features/               # Feature modules (exercise, objects, recommendation, sharing)
├── core/                   # Shared utilities, widgets, services
├── app/                    # Root app widget and theme
└── config/                 # Routes, localization
```

**Critical Requirements**:
- All exercises must be stored locally (offline requirement)
- Exercise data structure: Title, muscle group, difficulty, 3 key points, 2 safety contraindications, dosage
- Completion cards must generate in ≤800ms
- Object detection with fallback to manual grid selection

## Development Commands

### Setup & Daily Development
```bash
# Initial setup
flutter clean && flutter pub get

# Run app (development)
flutter run
flutter run -d <device_id>              # Specific device

# Code quality
flutter analyze                         # Lint analysis
flutter test                           # Run tests
flutter test --verbose                 # Verbose test output
```

### Platform-Specific Development

**Android**:
```bash
# Android builds
flutter build apk                      # Debug APK
flutter build appbundle               # Release App Bundle (Google Play)

# Gradle operations
cd android
./gradlew assembleDebug
./gradlew clean
```

**iOS** (macOS only):
```bash
flutter build ios --release           # Requires Xcode + Apple Developer
```

### Build Configuration

**Android**:
- Compile SDK: API 35 (must match installed Android SDK)
- Target SDK: API 31 (matches current device Android 12)
- Gradle: 7.6.3 (downgraded for Flutter 3.13.0 compatibility)
- Java: Version 17

**Known Build Issues**:
- If Android SDK API 35 is corrupted, install API 33 or 34 via Android Studio SDK Manager
- Flutter 3.13.0 has compatibility issues with newer Android SDK versions

## Key Documentation

**Requirements**: [docs/需求文档.md](docs/需求文档.md) - Complete Chinese product requirements
**UI Specs**: [docs/页面设计.md](docs/页面设计.md) - Detailed page designs with dimensions
**README**: Contains basic setup and project structure overview

## Data Model Essentials

Based on requirements, core entities include:

**Exercise**:
- Title, primary muscle group, difficulty level
- 3 key points (form/breathing/trajectory)
- 2 safety contraindications (hard red lines)
- Dosage (reps × sets or seconds × sets)
- Available objects compatibility

**Objects**:
- 9 common items: chair, backpack, water bottle, towel, book, stairs, wall, resistance band, dumbbells
- Empty-handed option as fallback
- Weight/strength guidelines for safety

**User Flow**:
1. Home: Object grid (3×3) + goal chips + "Give me 60s" CTA
2. Result: 3 exercise cards with swap functionality
3. Complete: Completion card generation and sharing

## State Management

**Not Yet Implemented** - Consider for architecture:
- **Riverpod** (recommended for modern Flutter)
- **Provider** (lightweight option)
- **GetX** (all-in-one solution)

## Critical Performance Requirements

- **Time to Value (TTV)**: ≤30 seconds P75 from app open to exercises
- **Exercise Generation**: ≤5 seconds
- **Completion Card Export**: ≤800ms
- **Session Completion Rate**: ≥95% target

## Dependencies Strategy

**Current Dependencies**: Minimal (flutter, cupertino_icons, flutter_lints)

**Required for MVP**:
- Image picker/camera integration
- Local data storage (consider `hive`, `sqflite`, or `isar`)
- Object detection model (TensorFlow Lite or similar)
- Sharing functionality (`share_plus`)

## Development Priorities

1. **Architecture Setup**: Implement feature-based structure, choose state management
2. **Core Data Models**: Exercise, Object, Recommendation entities
3. **Home Screen**: 9-grid object selection, goal chips, main CTA
4. **Exercise Engine**: Local exercise database and recommendation logic
5. **Result Screen**: 3 exercise cards with swap functionality
6. **Completion Flow**: Card generation and sharing

## Platform Considerations

**Android**: Uses Chinese Maven mirrors for faster builds (Aliyun, Huawei Cloud, Tsinghua, Tencent Cloud)
**iOS**: Standard setup, requires macOS for development
**Multi-platform**: Web, Windows, Linux, macOS platforms scaffolded but not target platforms

## Safety & Compliance

- All exercises must include safety contraindications
- Object weight/strength guidelines required
- No user data collection by default (privacy-first)
- Images used only for local object recognition, no uploads

## Testing Strategy

**Current**: Only default `widget_test.dart` template
**Required**: Unit tests for exercise logic, widget tests for screens, integration tests for complete user flows

When implementing features, prioritize the offline-first architecture and ensure all exercise data is available locally before adding advanced features like object detection.