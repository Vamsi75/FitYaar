#!/usr/bin/env bash
set -euo pipefail
# Start an Android emulator by name (default: Pixel_10a)
EMULATOR="${1:-Pixel_10a}"

echo "Launching emulator: $EMULATOR"
flutter emulators --launch "$EMULATOR" 2>/dev/null || {
  echo "flutter emulators failed, falling back to emulator -avd"
  emulator -avd "$EMULATOR" &
}

echo "Waiting for device to become available..."
adb wait-for-device
echo "Device is ready"
adb devices

echo "Emulator started."
