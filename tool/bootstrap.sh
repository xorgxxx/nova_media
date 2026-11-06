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

# AS Vault artwork (adaptive + legacy launcher icons from the official photo).
if [ -d android_overrides/res ]; then
  echo ">> Applying res/ overrides (icons)"
  mkdir -p android/app/src/main/res
  cp -R android_overrides/res/. android/app/src/main/res/
fi

python3 - <<'PY'
import pathlib, re

done = False
kts = pathlib.Path("android/app/build.gradle.kts")
grv = pathlib.Path("android/app/build.gradle")

if kts.exists():
    s = kts.read_text()
    n = re.sub(r"minSdk(Version)?\s*=\s*flutter\.minSdkVersion", "minSdk = 24", s)
    if "abiFilters" not in n:
        n = n.replace(
            "defaultConfig {",
            'defaultConfig {\n'
            '        ndk {\n'
            '            abiFilters.clear()\n'
            '            abiFilters.add("arm64-v8a")\n'
            '        }',
            1,
        )
    kts.write_text(n)
    done = True
elif grv.exists():
    s = grv.read_text()
    n = re.sub(r"minSdk(Version)?\s+flutter\.minSdkVersion", "minSdkVersion 24", s)
    if "abiFilters" not in n:
        n = n.replace(
            "defaultConfig {",
            'defaultConfig {\n'
            '        ndk {\n'
            '            abiFilters.clear()\n'
            '            abiFilters.add("arm64-v8a")\n'
            '        }',
            1,
        )
    grv.write_text(n)
    done = True

if not done:
    print("WARNING: no android/app/build.gradle(.kts) found")
else:
    print("patched minSdk 24 + arm64-v8a abiFilters")
PY

flutter pub get
echo ">> Bootstrap complete"
