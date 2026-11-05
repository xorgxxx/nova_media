#!/usr/bin/env bash
# Generates the Android host project (android/) with the INSTALLED Flutter version, then applies
# this project's required overrides (manifest, MainActivity, minSdk). Idempotent.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"

command -v flutter >/dev/null || { echo "flutter not on PATH. Run tool/install_toolchain.sh then 'source tool/env.sh'." >&2; exit 1; }

if [ ! -d android ]; then
  echo ">> flutter create (Android scaffold)"
  backup="$(mktemp -d)"
  cp -r lib test pubspec.yaml analysis_options.yaml "$backup/"
  flutter create --platforms=android --org com.novamedia --project-name nova_media --no-pub .
  # flutter create may overwrite our files: restore them.
  rm -rf lib test; cp -r "$backup/lib" "$backup/test" .
  cp "$backup/pubspec.yaml" "$backup/analysis_options.yaml" .
fi

echo ">> Applying overrides"
cp android_overrides/AndroidManifest.xml android/app/src/main/AndroidManifest.xml
find android/app/src/main -name 'MainActivity.*' -delete
mkdir -p android/app/src/main/kotlin/com/novamedia/nova_media
cp android_overrides/MainActivity.kt android/app/src/main/kotlin/com/novamedia/nova_media/MainActivity.kt

python3 - <<'PY'
import pathlib, re
done = False
kts = pathlib.Path("android/app/build.gradle.kts")
grv = pathlib.Path("android/app/build.gradle")
if kts.exists():
    s = kts.read_text()
    n = re.sub(r"minSdk(Version)?\s*=\s*flutter\.minSdkVersion", "minSdk = 24", s)
    kts.write_text(n); done = n != s or "minSdk = 24" in n
if grv.exists():
    s = grv.read_text()
    n = re.sub(r"minSdk(Version)?\s+flutter\.minSdkVersion", "minSdkVersion 24", s)
    grv.write_text(n); done = n != s or "minSdkVersion 24" in n
print("minSdk patched to 24" if done else "WARNING: could not patch minSdk; set minSdk 24 manually in android/app/build.gradle(.kts)")
PY

flutter pub get
echo ">> Bootstrap complete"
