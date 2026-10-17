#!/usr/bin/env bash
# iOS CI preparation: generate the ios/ project, app name, link permissions, icon.
set -euo pipefail

flutter create . --platforms=ios --org ir.nimaafshar --project-name nima_kickboxing

PL=ios/Runner/Info.plist
/usr/libexec/PlistBuddy -c "Set :CFBundleDisplayName 'باشگاه نیما افشار'" "$PL" \
  || /usr/libexec/PlistBuddy -c "Add :CFBundleDisplayName string 'باشگاه نیما افشار'" "$PL"
/usr/libexec/PlistBuddy -c "Set :CFBundleName 'نیما افشار'" "$PL" || true
# schemes the app opens (Instagram/Telegram via https, dialer, SMS)
/usr/libexec/PlistBuddy -c "Add :LSApplicationQueriesSchemes array" "$PL" || true
for sc in https tel sms; do
  /usr/libexec/PlistBuddy -c "Add :LSApplicationQueriesSchemes: string $sc" "$PL" || true
done
# timer sounds should play even when the phone is on silent only if the user wants; mix with music
/usr/libexec/PlistBuddy -c "Add :UIBackgroundModes array" "$PL" || true

flutter pub get
dart run flutter_launcher_icons -f flutter_launcher_icons-ios.yaml
