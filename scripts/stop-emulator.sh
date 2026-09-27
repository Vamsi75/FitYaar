#!/usr/bin/env bash
set -euo pipefail
# Stop emulator by device id or default to emulator-5554
DEVICE_ID="${1:-emulator-5554}"

echo "Stopping emulator/device: $DEVICE_ID"
adb -s "$DEVICE_ID" emu kill || {
  echo "Failed to kill via adb; attempting to find processes"
  pkill -f "emulator.*$DEVICE_ID" || true
}

echo "Stopped."
