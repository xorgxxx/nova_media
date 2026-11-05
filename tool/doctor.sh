#!/usr/bin/env bash
# Prints a diagnostic report of the build environment. Never modifies anything.
echo "== OS ==";        uname -a
echo "== Disk (need ~8GB free) =="; df -h . | tail -1
echo "== Java ==";      (java -version 2>&1 | head -1) || echo "java: MISSING (need JDK 17)"
echo "== Flutter ==";   (flutter --version 2>&1 | head -2) || echo "flutter: MISSING"
echo "== ANDROID_SDK_ROOT =="; echo "${ANDROID_SDK_ROOT:-<unset>}"
echo "== sdkmanager =="; (command -v sdkmanager || echo "MISSING")
echo "== Network =="
for u in https://storage.googleapis.com https://dl.google.com https://maven.google.com https://repo.maven.apache.org https://pub.dev https://github.com; do
  code=$(curl -s -o /dev/null -m 8 -w "%{http_code}" "$u" || echo ERR)
  echo "$u -> $code"
done
echo "== sudo =="; (sudo -n true 2>/dev/null && echo "passwordless sudo: yes") || echo "passwordless sudo: no"
