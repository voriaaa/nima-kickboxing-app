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

# Failures are echoed as annotations so they can be read through the API.
step() {
  if ! "$@" > step.log 2>&1; then
    tail -14 step.log | sed 's/%/%25/g' | sed ':a;N;$!ba;s/\n/%0A/g' | sed 's/^/::error::/'
    exit 1
  fi
}
step flutter pub get
step dart run flutter_launcher_icons

# Release builds are shrunk by R8. Keep plugin classes that are called from
# Dart through JNI (shared_preferences crashed startup without this).
cat > android/app/proguard-rules.pro <<'PRO'
-keep class io.flutter.plugins.** { *; }
-keep class dev.fluttercommunity.** { *; }
-keep class com.github.dart_lang.jni.** { *; }
-keep class kotlin.** { *; }
-keep class kotlin.coroutines.** { *; }
-keep class kotlinx.coroutines.** { *; }
-dontwarn io.flutter.embedding.**
-dontwarn kotlin.**
PRO
G=android/app/build.gradle.kts
if ! grep -q "proguard-rules.pro" "$G"; then
  # add the rules file to the release build type
  sed -i 's#signingConfig = signingConfigs.getByName("debug")#signingConfig = signingConfigs.getByName("debug")\n            proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")#' "$G"
fi
echo "--- build.gradle.kts (buildTypes) ---"
grep -n -A6 "buildTypes" "$G"

# Dark splash screen instead of white
R=android/app/src/main/res
mkdir -p $R/values $R/values-v31
cat > $R/values/splash_colors.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="splash_bg">#05070D</color>
</resources>
XML
for f in $R/drawable/launch_background.xml $R/drawable-v21/launch_background.xml; do
  [ -f "$f" ] && sed -i 's#@android:color/white#@color/splash_bg#; s#?android:colorBackground#@color/splash_bg#' "$f"
done
cat > $R/values-v31/styles.xml <<'XML'
<?xml version="1.0" encoding="utf-8"?>
<resources>
    <style name="LaunchTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">@drawable/launch_background</item>
        <item name="android:windowSplashScreenBackground">@color/splash_bg</item>
        <item name="android:windowSplashScreenIconBackgroundColor">@color/splash_bg</item>
    </style>
    <style name="NormalTheme" parent="@android:style/Theme.Black.NoTitleBar">
        <item name="android:windowBackground">@color/splash_bg</item>
    </style>
</resources>
XML
