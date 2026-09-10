#!/usr/bin/env bash
set -e

echo "==> Waiting for AVD emulator to complete boot..."
adb wait-for-device
while [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
  sleep 2
done
echo "==> Emulator boot completed."

# Display resolution & density: 1080x2400 @ 420 dpi (Standard Phone)
adb shell wm size 1080x2400
adb shell wm density 420

# Install Launcher
if [ -f artifacts/CustomOS-Launcher.apk ]; then
  echo "==> Installing CustomOS-Launcher..."
  adb install -r -g artifacts/CustomOS-Launcher.apk
  adb shell cmd package set-home-activity com.customos.launcher/.MainActivity
fi

# Install RRO Overlays
if [ -f artifacts/CustomOS-Overlay-Framework.apk ]; then
  echo "==> Installing Framework Overlay..."
  adb install -r artifacts/CustomOS-Overlay-Framework.apk || true
  adb shell cmd overlay enable com.customos.overlay.framework || true
fi

if [ -f artifacts/CustomOS-Overlay-SystemUI.apk ]; then
  echo "==> Installing SystemUI Overlay..."
  adb install -r artifacts/CustomOS-Overlay-SystemUI.apk || true
  adb shell cmd overlay enable com.customos.overlay.systemui || true
fi

# Launch CustomOS Home Screen
adb shell am start -c android.intent.category.HOME -a android.intent.action.MAIN
sleep 5

# Capture Verification Screenshot
mkdir -p screenshots
adb shell screencap -p /sdcard/launcher_screen.png
adb pull /sdcard/launcher_screen.png screenshots/launcher_screen.png
echo "==> Screenshot captured successfully."
