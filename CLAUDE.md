# CLAUDE.md — Snazzy Spelling

## Build & Release

- **Build APK**: `flutter build apk --release`
- **Correct APK path**: `build/app/outputs/apk/release/snazzyspelling-v{version}.apk`
  - ⚠️ Do NOT use `build/app/outputs/flutter-apk/app-release.apk` — that's Flutter's generic copy without the custom filename
- **Release flow**: bump version in `pubspec.yaml`, build, commit, push, tag, `gh release create` with the correct APK path
- **Version format**: `X.Y.Z+buildNumber` in pubspec.yaml (e.g. `1.0.7+8`), tag as `vX.Y.Z`

## Project Structure

- Flutter app targeting Android, iOS, macOS
- Provider for state management, SQLite for persistence
- Custom QWERTY keyboard widget (no native keyboard in test mode)
- TTS via flutter_tts (OS-native engine)
