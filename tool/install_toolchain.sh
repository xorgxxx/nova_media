#!/usr/bin/env bash
# Installs JDK 17 (if missing), Flutter (stable), Android cmdline-tools + SDK packages on Linux.
# Idempotent. Writes tool/env.sh which must be sourced afterwards:  source tool/env.sh
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS_DIR="${NOVA_TOOLS_DIR:-$HOME/dev-tools}"
FLUTTER_DIR="$TOOLS_DIR/flutter"
export ANDROID_SDK_ROOT="${ANDROID_SDK_ROOT:-$TOOLS_DIR/android-sdk}"
CMDLINE_ZIP_URL="https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip"
PLATFORM="android-35"
BUILD_TOOLS="35.0.0"

mkdir -p "$TOOLS_DIR" "$ANDROID_SDK_ROOT"
SUDO=""; [ "$(id -u)" -ne 0 ] && command -v sudo >/dev/null && SUDO="sudo"

# 1) System packages + JDK 17
if ! command -v java >/dev/null || ! java -version 2>&1 | grep -qE '"(17|21)\.'; then
  echo ">> Installing JDK 17 and base packages"
  if command -v apt-get >/dev/null; then
    $SUDO apt-get update -y
    $SUDO apt-get install -y openjdk-17-jdk curl git unzip xz-utils zip libglu1-mesa ca-certificates
  else
    echo "!! No apt-get. Install JDK 17, git, curl, unzip, xz manually, then re-run." >&2; exit 1
  fi
fi
JAVA_HOME_GUESS="$(dirname "$(dirname "$(readlink -f "$(command -v javac || command -v java)")")")"
export JAVA_HOME="${JAVA_HOME:-$JAVA_HOME_GUESS}"

# 2) Flutter
if [ ! -x "$FLUTTER_DIR/bin/flutter" ]; then
  echo ">> Cloning Flutter stable"
  git clone --depth 1 -b stable https://github.com/flutter/flutter.git "$FLUTTER_DIR"
fi
export PATH="$FLUTTER_DIR/bin:$PATH"

# 3) Android cmdline-tools
if [ ! -x "$ANDROID_SDK_ROOT/cmdline-tools/latest/bin/sdkmanager" ]; then
  echo ">> Installing Android cmdline-tools"
  tmp="$(mktemp -d)"; curl -fL "$CMDLINE_ZIP_URL" -o "$tmp/cmd.zip"
  unzip -q "$tmp/cmd.zip" -d "$tmp"
  mkdir -p "$ANDROID_SDK_ROOT/cmdline-tools"
  rm -rf "$ANDROID_SDK_ROOT/cmdline-tools/latest"
  mv "$tmp/cmdline-tools" "$ANDROID_SDK_ROOT/cmdline-tools/latest"
fi
export PATH="$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:$PATH"

# 4) SDK packages + licenses
yes | sdkmanager --licenses >/dev/null || true
sdkmanager "platform-tools" "platforms;$PLATFORM" "build-tools;$BUILD_TOOLS"

# 5) Flutter config
flutter config --no-analytics >/dev/null 2>&1 || true
flutter config --android-sdk "$ANDROID_SDK_ROOT"
yes | flutter doctor --android-licenses >/dev/null 2>&1 || true
flutter precache --android

cat > "$ROOT/tool/env.sh" <<ENV
export JAVA_HOME="$JAVA_HOME"
export ANDROID_SDK_ROOT="$ANDROID_SDK_ROOT"
export ANDROID_HOME="$ANDROID_SDK_ROOT"
export PATH="$FLUTTER_DIR/bin:$ANDROID_SDK_ROOT/cmdline-tools/latest/bin:$ANDROID_SDK_ROOT/platform-tools:\$PATH"
ENV
echo ">> Done. Run: source tool/env.sh && flutter doctor -v"
