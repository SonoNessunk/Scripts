#!/bin/bash

TARGET_IP="${1:-192.168.1.100}"
TARGET="$TARGET_IP:5555"

adb start-server >/dev/null 2>&1

echo "Verifying connection with $TARGET..."

if ! adb devices | grep -q "$TARGET"; then
    timeout 3 adb connect "$TARGET" >/dev/null 2>&1
fi

echo "Starting scrcpy on $TARGET..."

scrcpy -s "$TARGET" -w --no-mouse-hover -K -b 8M -G