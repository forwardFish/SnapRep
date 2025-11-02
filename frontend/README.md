# SnapRep

A lightweight Flutter fitness app for quick, location-agnostic workouts using everyday objects.

## Overview

SnapRep enables users to **exercise anywhere, anytime with objects at hand**. The app provides targeted workout recommendations based on:
- Selected muscle groups/goals (chest, back, legs, glutes, shoulders, arms, core, full body)
- Available objects around you (chair, backpack, water bottle, towel, book, stairs, etc.)

## Key Features

- **Quick Setup**: Select target muscle group and available objects
- **Smart Recommendations**: Get 3 safe, actionable exercises customized to your equipment
- **Offline-First**: Fully functional without internet connection
- **Share Success**: Generate completion cards to celebrate achievements
- **Safety First**: All exercises from curated safe exercise whitelist

## Getting Started

### Prerequisites
- Flutter 3.1.0 or higher
- Dart 3.1.0 or higher

### Installation

1. Clone the repository
2. Install dependencies:
   ```bash
   flutter pub get
   ```
3. Run the app:
   ```bash
   flutter run
   ```

### Development

- Run tests: `flutter test`
- Analyze code: `flutter analyze`
- Build for production: `flutter build [platform]`

## Project Structure

```
lib/
├── main.dart              # App entry point
├── screens/               # UI screens
├── models/                # Data models
├── services/              # Business logic
└── widgets/               # Reusable components
```

## Documentation

See [docs/需求文档.md](docs/需求文档.md) for detailed requirements and specifications.
