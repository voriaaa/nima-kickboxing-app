#!/usr/bin/env bash
# Runs inside the Android emulator job: installs the release APK, launches it,
# visits each tab and saves real screenshots plus the crash log to ./device/.
set -u
PKG=ir.nimaafshar.nima_kickboxing
OUT=device
mkdir -p "$OUT"

adb install -r build/app/outputs/flutter-apk/app-release.apk > "$OUT/install.txt" 2>&1
adb logcat -c
adb shell am start -W -n "$PKG/.MainActivity" > "$OUT/start.txt" 2>&1
sleep 15

shot() { adb exec-out screencap -p > "$OUT/$1.png"; }
alive() { adb shell pidof "$PKG" > /dev/null && echo yes || echo no; }

shot d01_launch
echo "running after launch: $(alive)" > "$OUT/status.txt"

# Tap a widget by its accessibility label (Flutter exposes semantics to uiautomator)
tap() {
  adb shell uiautomator dump /sdcard/ui.xml > /dev/null 2>&1
  adb pull /sdcard/ui.xml "$OUT/ui.xml" > /dev/null 2>&1
  python3 - "$1" "$OUT/ui.xml" <<'PY' > "$OUT/tap.txt"
import re, sys
label, path = sys.argv[1], sys.argv[2]
xml = open(path, encoding="utf-8").read()
for m in re.finditer(r'<node [^>]*>', xml):
    n = m.group(0)
    desc = re.search(r'content-desc="([^"]*)"', n).group(1)
    text = re.search(r' text="([^"]*)"', n).group(1)
    if desc.startswith(label) or text.startswith(label):
        x1, y1, x2, y2 = map(int, re.search(r'bounds="\[(\d+),(\d+)\]\[(\d+),(\d+)\]"', n).groups())
        print((x1 + x2) // 2, (y1 + y2) // 2)
        break
PY
  if [ -s "$OUT/tap.txt" ]; then
    adb shell input tap $(cat "$OUT/tap.txt")
    sleep 3
    return 0
  fi
  echo "label not found: $1" >> "$OUT/status.txt"
  return 1
}

SIZE=$(adb shell wm size | grep -oE "[0-9]+x[0-9]+" | tail -1)
W=${SIZE%x*}; H=${SIZE#*x}
DENS=$(adb shell wm density | grep -oE "[0-9]+" | tail -1)
echo "screen $W x $H @ $DENS dpi" >> "$OUT/status.txt"
# bottom nav: 5 tabs, right-to-left (home is right-most), ~68dp tall above the gesture bar
NAVY=$(( H - (48 + 34) * DENS / 160 ))
tabx() { echo $(( W * (9 - 2 * $1) / 10 )); }   # 0=home .. 4=club
tapxy() { adb shell input tap "$1" "$2"; sleep 3; }

if [ "$(alive)" = yes ]; then
  tapxy "$(tabx 1)" "$NAVY"; shot d02_techniques
  tapxy $(( W * 3 / 4 )) $(( H * 30 / 100 )); sleep 2; shot d03_move_detail
  adb shell input keyevent 4; sleep 2
  tapxy "$(tabx 2)" "$NAVY"; shot d04_combos
  tapxy $(( W / 2 )) $(( H * 38 / 100 )); sleep 3; shot d05_combo_detail
  adb shell input keyevent 4; sleep 2
  tapxy "$(tabx 3)" "$NAVY"; shot d06_timer
  tapxy "$(tabx 4)" "$NAVY"; shot d07_club
  tapxy "$(tabx 0)" "$NAVY"; shot d08_home
  # start the timer: after the 10 s get-ready phase the round bell plays (audio engine check)
  tapxy "$(tabx 3)" "$NAVY"
  tap "شروع تمرین" && sleep 14 && shot d09_timer_running
fi
echo "running at end: $(alive)" >> "$OUT/status.txt"

adb logcat -d > "$OUT/logcat.txt"
grep -q "storage unavailable" "$OUT/logcat.txt" && echo "STORAGE BROKEN" >> "$OUT/status.txt" || echo "storage ok" >> "$OUT/status.txt"
grep -E " E flutter|FATAL EXCEPTION|storage unavailable" "$OUT/logcat.txt" \
  | grep -v "ResourcesCompat\|ExternalEnable" | head -60 > "$OUT/errors.txt" || true
cat "$OUT/status.txt"
exit 0
