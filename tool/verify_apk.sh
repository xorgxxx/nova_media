#!/usr/bin/env bash
# Sanity-checks the release APK. Exit code != 0 means the APK is not acceptable.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
APK="build/app/outputs/flutter-apk/app-release.apk"
[ -f "$APK" ] || { echo "FAIL: $APK not found"; exit 1; }
size=$(stat -c%s "$APK"); echo "size: $size bytes"
[ "$size" -gt 5000000 ] || { echo "FAIL: APK suspiciously small"; exit 1; }
listing=$(unzip -l "$APK")
for entry in AndroidManifest.xml classes.dex "lib/arm64-v8a/libflutter.so"; do
  echo "$listing" | grep -q "$entry" || { echo "FAIL: missing $entry"; exit 1; }
done
echo "$listing" | grep -q "libapp.so" || { echo "FAIL: missing libapp.so (AOT snapshot)"; exit 1; }
AAPT="$(command -v aapt2 || true)"
[ -z "$AAPT" ] && AAPT="$(find "${ANDROID_SDK_ROOT:-/nonexistent}/build-tools" -name aapt2 2>/dev/null | sort | tail -1 || true)"
if [ -n "$AAPT" ]; then
  "$AAPT" dump badging "$APK" | grep -E "^package:|sdkVersion:|uses-permission: name='android.permission.(READ_MEDIA|FOREGROUND)" || true
else
  echo "note: aapt2 not found, skipped manifest dump"
fi
sha256sum "$APK"
echo "APK OK: $APK"
