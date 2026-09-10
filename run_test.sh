#!/usr/bin/env bash
set -e

echo "==> Waiting for AVD emulator to complete boot..."
adb wait-for-device
while [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
  sleep 2
done
echo "==> Emulator boot completed."

# Display configuration: 1080x2400 @ 420 dpi (Standard Phone)
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

mkdir -p screenshots

# 1. Capture Launcher Home Screen
adb shell am start -c android.intent.category.HOME -a android.intent.action.MAIN
sleep 4
adb shell screencap -p /sdcard/screen_launcher.png
adb pull /sdcard/screen_launcher.png screenshots/screen_launcher.png

# 2. Expand Notification Shade & Capture
adb shell cmd statusbar expand-notifications
sleep 2
adb shell screencap -p /sdcard/screen_quicksettings.png
adb pull /sdcard/screen_quicksettings.png screenshots/screen_quicksettings.png

# 3. Collapse Shade & Go to Lock Screen
adb shell cmd statusbar collapse
adb shell input keyevent 26  # Power off
sleep 1
adb shell input keyevent 26  # Power on (wakes keyguard)
sleep 2
adb shell screencap -p /sdcard/screen_lockscreen.png
adb pull /sdcard/screen_lockscreen.png screenshots/screen_lockscreen.png

echo "==> All test screenshots captured successfully."
