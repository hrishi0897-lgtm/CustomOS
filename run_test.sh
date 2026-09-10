#!/usr/bin/env bash
set -e

echo "==> Waiting for AVD emulator to complete boot..."
adb wait-for-device
while [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
  sleep 2
done
echo "==> Emulator boot completed."

# Display configuration: 1080x2400 @ 420 dpi
adb shell wm size 1080x2400
adb shell wm density 420

# Force Global System Dark Mode
adb shell cmd uimode night yes

# Install Launcher
if [ -f artifacts/CustomOS-Launcher.apk ]; then
  echo "==> Installing CustomOS-Launcher..."
  adb install -r -g artifacts/CustomOS-Launcher.apk
  adb shell cmd package set-home-activity com.customos.launcher/.MainActivity
fi

# Install and Enable RRO Overlays
for apk in artifacts/CustomOS-Overlay-*.apk; do
  [ -f "$apk" ] && adb install -r "$apk" || true
done
adb shell cmd overlay enable com.customos.overlay.framework || true
adb shell cmd overlay enable com.customos.overlay.systemui || true
adb shell cmd overlay enable com.customos.overlay.settings || true

mkdir -p screenshots

# 1. Launcher Capture
adb shell am start -c android.intent.category.HOME -a android.intent.action.MAIN
sleep 4
adb shell screencap -p /sdcard/screen_launcher.png
adb pull /sdcard/screen_launcher.png screenshots/screen_launcher.png

# 2. Quick Settings Shade Capture
adb shell cmd statusbar expand-notifications
sleep 2
adb shell screencap -p /sdcard/screen_quicksettings.png
adb pull /sdcard/screen_quicksettings.png screenshots/screen_quicksettings.png

# 3. Set Device Lock PIN & Capture Keyguard
adb shell locksettings set-pin 1234 || true
adb shell cmd statusbar collapse
adb shell input keyevent 26  # Power off
sleep 1
adb shell input keyevent 26  # Power on to show keyguard
sleep 2
adb shell screencap -p /sdcard/screen_lockscreen.png
adb pull /sdcard/screen_lockscreen.png screenshots/screen_lockscreen.png

echo "==> All test screenshots captured successfully."
