#!/usr/bin/env bash
# Shared CI preparation: generate the Android project, app name, link
# permissions, packages and launcher icon. Used by build and device workflows.
set -euo pipefail

flutter create . --platforms=android --org ir.nimaafshar --project-name nima_kickboxing

M=android/app/src/main/AndroidManifest.xml
sed -i 's/android:label="[^"]*"/android:label="باشگاه نیما افشار"/' "$M"
# Android 11+ must declare which apps we open (browser/Instagram/Telegram, dialer, SMS)
sed -i 's#<application#<queries><intent><action android:name="android.intent.action.VIEW"/><data android:scheme="https"/></intent><intent><action android:name="android.intent.action.DIAL"/><data android:scheme="tel"/></intent><intent><action android:name="android.intent.action.SENDTO"/><data android:scheme="sms"/></intent></queries>\n    <application#' "$M"
echo "--- AndroidManifest.xml ---"
cat "$M"

flutter pub get
dart run flutter_launcher_icons
