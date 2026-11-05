#!/usr/bin/env bash
# Full pipeline: bootstrap -> analyze -> test -> build release APK -> verify.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"; cd "$ROOT"
[ -f tool/env.sh ] && source tool/env.sh
bash tool/bootstrap.sh
flutter analyze
flutter test
flutter build apk --release
bash tool/verify_apk.sh
