# AGENTS.md — instructions for the coding agent (OpenCode)

You are receiving a **complete Flutter/Dart source project** (`nova_media`) written by another model.
**It has never been compiled** (the author had no Flutter SDK). Your job: make it build, produce a release APK, and verify it.
Work autonomously; do not ask the human to write code. Do not rewrite the app or change its architecture — fix only what is needed.

## 0. Ground rules
- Keep the layered structure in `docs/ARCHITECTURE.md`. Keep Riverpod on 2.x APIs (`FamilyAsyncNotifier`, `valueOrNull`).
- Prefer the smallest fix. After each fix re-run the failing command.
- Never delete features or stub them out to "make it compile". If a plugin API differs from what the code uses, adapt the call site.
- Keep a log of every change in `docs/BUILD_LOG.md` (what failed, root cause, fix).
- Never commit/print secrets. No signing keys are needed (debug-signed release APK is acceptable).

## 1. Inspect
1. Read `README.md`, `docs/ARCHITECTURE.md`, `pubspec.yaml`, `android_overrides/*`, `tool/*.sh`.
2. `bash tool/doctor.sh` — shows OS, disk, java, flutter, SDK, network reachability, sudo.

## 2. Prepare the environment (do not assume anything is installed)
- If `flutter` / Java 17 / Android SDK are missing: `bash tool/install_toolchain.sh`, then `source tool/env.sh`.
  It needs network access to: github.com, storage.googleapis.com, dl.google.com, maven.google.com, repo.maven.apache.org, pub.dev, and apt (or sudo for apt).
- If the script fails: read the error, fix the cause (missing package, no sudo → install JDK locally from a tarball into `$HOME/dev-tools`, proxy variables, etc.), re-run. The script is idempotent.
- If the network blocks a required host and you cannot work around it, STOP and report exactly which host is blocked (do not fake a build).
- Verify: `flutter doctor -v` — the Android toolchain line must be OK. Licenses: `yes | flutter doctor --android-licenses`.

## 3. Bootstrap
`bash tool/bootstrap.sh` — generates `android/` with `flutter create`, restores our `lib/ test/ pubspec.yaml`, applies:
- `android_overrides/AndroidManifest.xml` (permissions + audio service/receiver),
- `android_overrides/MainActivity.kt` (`AudioServiceActivity`, required by just_audio_background),
- `minSdk 24` patch in `android/app/build.gradle(.kts)` (the script prints a WARNING if it could not patch; then do it by hand).
Then it runs `flutter pub get`.

## 4. Fix loop (expected work)
```
flutter pub get      # version conflicts → loosen/adjust the caret in pubspec.yaml, keep majors sensible
flutter analyze      # must end with 0 errors (warnings/infos acceptable, fix cheap ones)
flutter test         # must pass
flutter build apk --release
```
Known risk points (the code was written without a compiler):
- **photo_manager API**: `PermissionRequestOption`, `AndroidPermission`, `getPermissionState`, `assetCountAsync`, `getAssetListRange`, `AssetPathEntity.fromId`, `AssetEntity.originFile/title/relativePath`. If a name differs in the resolved version, check the package changelog/docs (pub.dev) and adapt `lib/data/repositories/library_repository.dart` and call sites.
- **just_audio / just_audio_background**: `ConcatenatingAudioSource` may be deprecated in just_audio 0.10 (still works; migrate to `setAudioSources` only if removed). `SequenceState` nullability may differ (harmless warnings).
- **video_player**: `VideoPlayerValue.isCompleted`, `setPlaybackSpeed`.
- **Flutter version drift**: deprecated Material APIs are only warnings. If `flutter analyze` reports removed APIs, replace with the documented successor.
- **Gradle/AGP/Kotlin errors**: the scaffold comes from your installed Flutter, so versions are consistent. If a plugin needs a newer `compileSdk`/NDK/Kotlin, follow Flutter's migration docs, change only the minimum. If Gradle cannot download dependencies, check network/proxy; retry with `flutter build apk --release --verbose` and read the first real error, not the last.
- Out-of-memory in Gradle: set `org.gradle.jvmargs=-Xmx3g` in `android/gradle.properties`.
- `Android resource linking failed` / manifest merger errors: compare with `android_overrides/AndroidManifest.xml`; keep the `tools` namespace and the `service`/`receiver` entries.

## 5. Verify the APK
`bash tool/verify_apk.sh` must print `APK OK`. It checks existence, size, `AndroidManifest.xml`, `classes.dex`, `libflutter.so`, `libapp.so`, and dumps package/minSdk/permissions when `aapt2` exists.
Expected: package `com.novamedia.nova_media`, minSdk 24, permissions READ_MEDIA_IMAGES/VIDEO/AUDIO and FOREGROUND_SERVICE_MEDIA_PLAYBACK.
Optionally (if an emulator/device exists): `flutter install` and smoke-test: grant media access, open each tab, play a video and a song, lock the screen and confirm media controls.

## 6. Definition of done
- [ ] `flutter analyze` → 0 errors
- [ ] `flutter test` → all pass
- [ ] `build/app/outputs/flutter-apk/app-release.apk` exists and `tool/verify_apk.sh` passes
- [ ] `docs/BUILD_LOG.md` lists every change you made
- [ ] Final report to the human: Flutter/Dart/AGP versions used, APK path + SHA-256, what you fixed, anything you could not verify (e.g., no device to run on)

## 7. Report honestly
If something could not be done or verified, say so explicitly. Never claim the APK was tested on a device unless you did.
