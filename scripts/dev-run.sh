#!/usr/bin/env bash
set -euo pipefail
# dev-run: start emulator (optional), force-stop app, run flutter with hot reload
EMULATOR_NAME="${1:-Pixel_10a}"
DEVICE_ID="${2:-emulator-5554}"
PACKAGE_NAME="${3:-com.fityaar.fityaar}"

echo "Starting emulator: $EMULATOR_NAME (if not running)"
./scripts/start-emulator.sh "$EMULATOR_NAME"

echo "Force-stopping $PACKAGE_NAME on $DEVICE_ID (if installed)"
adb -s "$DEVICE_ID" shell am force-stop "$PACKAGE_NAME" || true

echo "Running flutter..."
cd FitYaar-Mobile
flutter run -d "$DEVICE_ID"
