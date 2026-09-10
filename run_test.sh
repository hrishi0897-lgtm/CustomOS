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

# 1. Enforce Global Night Mode & Suppress Dynamic Theming
adb shell cmd uimode night yes
adb shell settings put secure theme_customization_overlay_packages '{"android.theme.customization.system_palette":"#000000","android.theme.customization.accent_color":"#FFFF5722","android.theme.customization.color_source":"preset"}' || true

# 2. Direct Root System Wallpaper Injection
adb root || true
sleep 1
if [ -f assets/black_wallpaper.png ]; then
  echo "==> Injecting pure pitch-black wallpaper..."
  adb push assets/black_wallpaper.png /data/system/users/0/wallpaper || true
  adb push assets/black_wallpaper.png /data/system/users/0/wallpaper_lock || true
  adb shell chmod 600 /data/system/users/0/wallpaper* || true
  adb shell chown system:system /data/system/users/0/wallpaper* || true
fi

# 3. Install Launcher App
if [ -f artifacts/CustomOS-Launcher.apk ]; then
  echo "==> Installing CustomOS-Launcher..."
  adb install -r -g artifacts/CustomOS-Launcher.apk
  adb shell cmd package set-home-activity com.customos.launcher/.MainActivity
fi

# 4. Install & Force-Enable RRO Overlays for User 0
for apk in artifacts/CustomOS-Overlay-*.apk; do
  [ -f "$apk" ] && adb install -r "$apk" || true
done
adb shell cmd overlay enable --user 0 com.customos.overlay.framework || true
adb shell cmd overlay enable --user 0 com.customos.overlay.systemui || true
adb shell cmd overlay enable --user 0 com.customos.overlay.settings || true

# 5. Restart SystemUI to bind new tokens
adb shell pkill -f com.android.systemui || true
sleep 4

mkdir -p screenshots

# Capture 1: Launcher Home Screen
adb shell am start -c android.intent.category.HOME -a android.intent.action.MAIN
sleep 4
adb shell screencap -p /sdcard/screen_launcher.png
adb pull /sdcard/screen_launcher.png screenshots/screen_launcher.png

# Capture 2: Quick Settings Shade
adb shell cmd statusbar expand-notifications
sleep 2
adb shell screencap -p /sdcard/screen_quicksettings.png
adb pull /sdcard/screen_quicksettings.png screenshots/screen_quicksettings.png

# Capture 3: Lock Screen
adb shell locksettings set-pin 1234 || true
adb shell cmd statusbar collapse
adb shell input keyevent 26
sleep 1
adb shell input keyevent 26
sleep 2
adb shell screencap -p /sdcard/screen_lockscreen.png
adb pull /sdcard/screen_lockscreen.png screenshots/screen_lockscreen.png

echo "==> All test screenshots captured successfully."
