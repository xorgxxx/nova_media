#!/usr/bin/env bash
# Sanity-checks the release APK. Exit code != 0 means the APK is not acceptable.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
APK="${1:-build/app/outputs/flutter-apk/app-release.apk}"
[ -f "$APK" ] || { echo "FAIL: $APK not found"; exit 1; }
size=$(stat -c%s "$APK"); echo "size: $size bytes"
[ "$size" -gt 5000000 ] || { echo "FAIL: APK suspiciously small"; exit 1; }
listing=$(unzip -l "$APK")
for entry in AndroidManifest.xml classes.dex "lib/arm64-v8a/libflutter.so"; do
  echo "$listing" | grep -q "$entry" || { echo "FAIL: missing $entry"; exit 1; }
done
echo "$listing" | grep -q "libapp.so" || { echo "FAIL: missing libapp.so (AOT snapshot)"; exit 1; }

# AS Vault ships arm64-v8a only. Any other ABI means the build is wrong.
others=$(echo "$listing" | grep -E "lib/(armeabi-v7a|x86|x86_64)/" || true)
if [ -n "$others" ]; then
  echo "FAIL: non-arm64 native libraries present:"
  echo "$others"
  exit 1
fi
echo "ABI check: arm64-v8a only"

AAPT="$(command -v aapt2 || true)"
[ -z "$AAPT" ] && AAPT="$(find "${ANDROID_SDK_ROOT:-/nonexistent}/build-tools" -name aapt2 2>/dev/null | sort | tail -1 || true)"
if [ -n "$AAPT" ]; then
  badging="$("$AAPT" dump badging "$APK")"
  echo "$badging" | grep -E "^package:|sdkVersion:|targetSdkVersion:|native-code:" || true
  echo "$badging" | grep -q "application-label:'AS Vault'" \
    || { echo "FAIL: launcher label is not 'AS Vault'"; exit 1; }
  echo "$badging" | grep -q "native-code:.*arm64-v8a" \
    || { echo "FAIL: native-code does not list arm64-v8a"; exit 1; }
  if echo "$badging" | grep -q "application-label:'Nova Media'"; then
    echo "FAIL: old Nova Media label still present"; exit 1
  fi
  echo "Manifest check: label AS Vault, native-code arm64-v8a"
else
  echo "note: aapt2 not found, skipped manifest dump"
fi
sha256sum "$APK"
echo "APK OK: $APK"
