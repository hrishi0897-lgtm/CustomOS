#!/usr/bin/env bash
set -e

echo "==> Waiting for AVD emulator to boot..."
adb wait-for-device
while [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
  sleep 2
done
echo "==> Emulator boot completed."

adb shell wm size 1080x2400
adb shell wm density 420
adb shell cmd uimode night yes
adb shell settings put secure theme_customization_overlay_packages '{"android.theme.customization.system_palette":"#000000","android.theme.customization.accent_color":"#FFFF5722","android.theme.customization.color_source":"preset"}' || true

# Root Wallpaper Injection
adb root || true
sleep 1
if [ -f assets/black_wallpaper.png ]; then
  echo "==> Injecting pure pitch-black wallpaper..."
  adb push assets/black_wallpaper.png /data/system/users/0/wallpaper || true
  adb push assets/black_wallpaper.png /data/system/users/0/wallpaper_lock || true
  adb shell chmod 600 /data/system/users/0/wallpaper* || true
  adb shell chown system:system /data/system/users/0/wallpaper* || true
fi

# Install Launcher
if [ -f artifacts/CustomOS-Launcher.apk ]; then
  adb install -r -g artifacts/CustomOS-Launcher.apk
  adb shell cmd package set-home-activity com.customos.launcher/.MainActivity
fi

# Install & Enable Overlays for User 0
for apk in artifacts/CustomOS-Overlay-*.apk; do
  [ -f "$apk" ] && adb install -r "$apk" || true
done
adb shell cmd overlay enable --user 0 com.customos.overlay.framework || true
adb shell cmd overlay enable --user 0 com.customos.overlay.systemui || true
adb shell cmd overlay enable --user 0 com.customos.overlay.settings || true

# Restart SystemUI
adb shell pkill -f com.android.systemui || true
sleep 5

mkdir -p screenshots

# 1. Capture Launcher Home Screen
adb shell am start -c android.intent.category.HOME -a android.intent.action.MAIN
sleep 3
adb shell screencap -p /sdcard/screen_launcher.png
adb pull /sdcard/screen_launcher.png screenshots/screen_launcher.png

# 2. Expand Quick Settings Shade Completely & Capture
adb shell cmd statusbar expand-settings
sleep 3
adb shell screencap -p /sdcard/screen_quicksettings.png
adb pull /sdcard/screen_quicksettings.png screenshots/screen_quicksettings.png
adb shell cmd statusbar collapse
sleep 1

# 3. Lock Screen Keyguard Capture
adb shell locksettings set-pin 1234 || true
adb shell input keyevent 26  # Screen off
sleep 2
adb shell input keyevent 26  # Screen on (keyguard active)
sleep 3
adb shell screencap -p /sdcard/screen_lockscreen.png
adb pull /sdcard/screen_lockscreen.png screenshots/screen_lockscreen.png

echo "==> All test states captured."
