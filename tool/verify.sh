#!/usr/bin/env bash
# One-shot local verification. Run from the project root.
set -euo pipefail

flutter pub get
dart fix --apply          # trailing commas / const hints
dart format .
flutter analyze
flutter test

echo
echo "OK. Next: flutter run --dart-define=DATA_SOURCE=remote"
echo "Release APK: flutter build apk --release --dart-define=DATA_SOURCE=remote"
