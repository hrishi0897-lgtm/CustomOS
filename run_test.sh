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

# Root and Remount System Partition as Read-Write
adb root
sleep 2
adb remount || adb shell mount -o rw,remount /
sleep 2

# Direct Root System Overlay Installation
adb shell mkdir -p /system/product/overlay
for apk in artifacts/CustomOS-Overlay-*.apk; do
  if [ -f "$apk" ]; then
    echo "==> Pushing $apk to /system/product/overlay/..."
    adb push "$apk" /system/product/overlay/
  fi
done
adb shell chmod 644 /system/product/overlay/*.apk || true
adb shell chown root:root /system/product/overlay/*.apk || true

# Root Wallpaper Injection
if [ -f assets/black_wallpaper.png ]; then
  echo "==> Injecting pure pitch-black wallpaper..."
  adb push assets/black_wallpaper.png /data/system/users/0/wallpaper || true
  adb push assets/black_wallpaper.png /data/system/users/0/wallpaper_lock || true
  adb shell chmod 600 /data/system/users/0/wallpaper* || true
  adb shell chown system:system /data/system/users/0/wallpaper* || true
fi

# Install CustomOS Launcher
if [ -f artifacts/CustomOS-Launcher.apk ]; then
  echo "==> Installing CustomOS-Launcher..."
  adb install -r -g artifacts/CustomOS-Launcher.apk
  adb shell cmd package set-home-activity com.customos.launcher/.MainActivity
fi

# Disable Dynamic Monet Engine Palette
adb shell settings put secure theme_customization_overlay_packages '{"android.theme.customization.system_palette":"#000000","android.theme.customization.accent_color":"#FFFFFF","android.theme.customization.theme_style":"SPRITZ"}'

# Restart SystemUI to bind system overlays
adb shell pkill -f com.android.systemui || true
sleep 6

mkdir -p screenshots

# 1. Capture Launcher Home Screen
adb shell am start -c android.intent.category.HOME -a android.intent.action.MAIN
sleep 3
adb shell screencap -p /sdcard/screen_launcher.png
adb pull /sdcard/screen_launcher.png screenshots/screen_launcher.png

# 2. Capture Expanded Quick Settings Shade
adb shell cmd statusbar expand-notifications
sleep 2
adb shell screencap -p /sdcard/screen_quicksettings.png
adb pull /sdcard/screen_quicksettings.png screenshots/screen_quicksettings.png
adb shell cmd statusbar collapse
sleep 1

# 3. Capture Lock Screen
adb shell locksettings set-pin 1234 || true
adb shell input keyevent 26
sleep 2
adb shell input keyevent 26
sleep 3
adb shell screencap -p /sdcard/screen_lockscreen.png
adb pull /sdcard/screen_lockscreen.png screenshots/screen_lockscreen.png

echo "==> All test states captured."
