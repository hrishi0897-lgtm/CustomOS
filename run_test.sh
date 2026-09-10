#!/usr/bin/env bash
set -e

echo "==> Waiting for AVD emulator to complete boot..."
adb wait-for-device
while [ "$(adb shell getprop sys.boot_completed 2>/dev/null | tr -d '\r')" != "1" ]; do
  sleep 2
done
echo "==> Emulator boot completed."

# Configure display properties
adb shell wm size 1080x2400
adb shell wm density 420
adb shell cmd uimode night yes

# Suppress dynamic Monet color generation
adb shell settings put secure theme_customization_overlay_packages '{"android.theme.customization.system_palette":"#000000","android.theme.customization.accent_color":"#FFFFFF","android.theme.customization.theme_style":"SPRITZ"}' || true

# Inject Pitch-Black Wallpaper into User Directory
adb root || true
sleep 1
if [ -f assets/black_wallpaper.png ]; then
  echo "==> Setting pure black wallpaper..."
  adb push assets/black_wallpaper.png /data/system/users/0/wallpaper || true
  adb push assets/black_wallpaper.png /data/system/users/0/wallpaper_lock || true
  adb shell chmod 600 /data/system/users/0/wallpaper* || true
  adb shell chown system:system /data/system/users/0/wallpaper* || true
fi

# Install Launcher
if [ -f artifacts/CustomOS-Launcher.apk ]; then
  echo "==> Installing CustomOS-Launcher..."
  adb install -r -g artifacts/CustomOS-Launcher.apk
  adb shell cmd package set-home-activity com.customos.launcher/.MainActivity
fi

# Install and Enable RRO Overlays for User 0
for apk in artifacts/CustomOS-Overlay-*.apk; do
  if [ -f "$apk" ]; then
    echo "==> Installing $apk..."
    adb install -r -d "$apk" || true
  fi
done

adb shell cmd overlay enable --user 0 com.customos.overlay.framework || true
adb shell cmd overlay enable --user 0 com.customos.overlay.systemui || true
adb shell cmd overlay enable --user 0 com.customos.overlay.settings || true

# Restart SystemUI
adb shell pkill -f com.android.systemui || true
sleep 5

mkdir -p screenshots

# 1. Launcher Home Screen
adb shell am start -c android.intent.category.HOME -a android.intent.action.MAIN
sleep 3
adb shell screencap -p /sdcard/screen_launcher.png
adb pull /sdcard/screen_launcher.png screenshots/screen_launcher.png

# 2. Expanded Quick Settings Shade
adb shell service call statusbar 1 || true
sleep 1
adb shell service call statusbar 2 || true
sleep 4
adb shell screencap -p /sdcard/screen_quicksettings.png
adb pull /sdcard/screen_quicksettings.png screenshots/screen_quicksettings.png
adb shell service call statusbar 2 || true
sleep 1

# 3. Lock Screen Keyguard
adb shell locksettings set-pin 1234 || true
adb shell input keyevent 26
sleep 2
adb shell input keyevent 26
sleep 3
adb shell screencap -p /sdcard/screen_lockscreen.png
adb pull /sdcard/screen_lockscreen.png screenshots/screen_lockscreen.png

echo "==> Test run and screenshot captures finished."
