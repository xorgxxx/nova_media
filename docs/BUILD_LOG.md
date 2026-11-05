# Build log

Every change made while getting `nova_media` to build is recorded here (see `AGENTS.md`).

## 2026-11-05 — Cloud build pipeline (GitHub Actions)

**Context.** The project had never been compiled. On the author's machine
`dl.google.com` is blocked (every `/android/repository/*` URL returns a fake
404) and the measured bandwidth is ~50 KB/s, which makes a local SDK build
impractical (~10–11 h of downloads). The build was therefore moved to
GitHub-hosted `ubuntu-latest` runners; nothing is installed locally.

**Added**

- `.github/workflows/android-build.yml` — checkout → JDK 17 → Flutter 3.47.9 →
  Android SDK → `flutter pub get` → `flutter analyze` → `flutter test` →
  `tool/bootstrap.sh` → `flutter build apk --release` → `tool/verify_apk.sh` →
  `actions/upload-artifact` → job summary with the artifact link + SHA-256.
  Triggers: push to `main`/`master` and `workflow_dispatch`.
- `.gitattributes` — forces LF line endings for `.sh`, `.yml`, `.dart`, `.kt`,
  `.xml` so the shell scripts keep working when checked out on Windows.
- `docs/CLOUD_BUILD.md` — step-by-step (Arabic) instructions for the user.
- `docs/BUILD_LOG.md` — this file.

**Toolchain pinned (verified against Flutter's release metadata)**

| Component | Version | Source |
|---|---|---|
| Flutter | 3.47.9 (stable) | `releases_linux.json` (`current_release.stable`), released 2026-10-29 |
| Dart | 3.13.7 | same metadata |
| JDK | 17 (Temurin) | Gradle 9.3.1 / AGP 9.x require Java ≥ 17; template targets Java 17 |
| compileSdk | 36 | `flutter_tools/lib/src/android/gradle_utils.dart` |
| minSdk | 24 | same (also patched explicitly by `tool/bootstrap.sh`) |
| targetSdk | 36 | same |
| NDK | 28.2.13676358 | same (`ndkVersion`) |
| Gradle | 9.3.1 | `templateDefaultGradleVersion` |

`flutter create` (run inside `tool/bootstrap.sh`) generates AGP/Kotlin versions
that match this Flutter release, so no manual Gradle/AGP override is needed.
The generated `gradle.properties` already sets `org.gradle.jvmargs=-Xmx8G`,
so no memory override was added.

**Static API review (before the first build).** Resolved versions were taken
from pub.dev and their sources checked; no call site needed changing yet:

- `just_audio` 0.10.6 — `AudioSource.uri(..., tag:)`,
  `setAudioSource(ConcatenatingAudioSource, initialIndex:, initialPosition:)`,
  `sequenceStateStream`, `playerStateStream`, `shuffleModeEnabled`,
  `shuffleModeEnabledStream`, `loopModeStream`, `seekToNext`, `seekToPrevious`,
  `LoopMode`, `ProcessingState` all still exist.
- `photo_manager` 3.12.0 — `PermissionRequestOption`, `AndroidPermission`,
  `getPermissionState`, `requestPermissionExtend`, `getAssetPathList(hasAll:,
  onlyAll:)`, `AssetPathEntity.fromId(id, type:)`, `assetCountAsync`,
  `getAssetListRange(start:, end:)`, `AssetEntity.originFile/title/duration/
  relativePath`, `PermissionState.hasAccess` all exist.
- `video_player` 2.14.1 — `VideoPlayerValue.isCompleted`, `setPlaybackSpeed`,
  `aspectRatio`, `initialize`, `seekTo` exist.
- `flutter_riverpod` 2.6.1 — `FamilyAsyncNotifier`,
  `AsyncNotifierProvider.family`, `AsyncNotifier.future`, `invalidateSelf`
  exist (Riverpod stays on 2.x as required).
- `just_audio_background` 0.0.1-beta.17 — `JustAudioBackground.init(...)`
  parameters used by `main.dart` exist; it exports `MediaItem`.
- `photo_manager_image_provider` 2.2.0 — `AssetEntityImage(..., isOriginal,
  thumbnailSize, fit, errorBuilder)` exists.

**Workflow environment fixes**

- `flutter analyze` runs with `--no-fatal-warnings --no-fatal-infos`: lints
  such as `prefer_const_constructors` are treated as advisory, while compile
  errors still fail the job (matches the definition of done in `AGENTS.md`).
- `flutter doctor -v` is informational only (`|| true`), so a cosmetic warning
  cannot fail an otherwise good build.
- Android licenses are accepted and `platforms;android-36`,
  `build-tools;36.0.0`, `ndk;28.2.13676358` are installed explicitly, because
  the runner image lags behind Flutter's `compileSdk`.

## 2026-11-05 — CI run #1 (first real compile)

Environment steps all passed: JDK 17, Flutter 3.47.9 / Dart 3.13.7,
Android SDK 36, `flutter pub get` (all constraints resolved), toolchain print.

**Failed:** `flutter analyze` (1 error, 2 warnings, 2 infos).

| Location | Message | Root cause | Fix |
|---|---|---|---|
| `lib/presentation/home/permission_gate.dart:43` | `The getter 'hasAccess' isn't defined for the type 'PermissionState'` | **error** — `hasAccess` is an extension (`PermissionStateExt`) that photo_manager exports, but this file never imported `photo_manager`, so the extension was not in scope. | Added `import 'package:photo_manager/photo_manager.dart';` |
| `lib/application/providers.dart:151` | `invalid_null_aware_operator` | warning — since just_audio 0.10 `sequenceStateStream` emits a non-null `SequenceState`, so `s?.` was redundant. | `s?.currentSource` → `s.currentSource` |
| `lib/data/repositories/library_repository.dart:9,10` | `prefer_const_constructors` | info — `PermissionRequestOption` / `AndroidPermission` have const constructors. | `=> const PermissionRequestOption(...)` |
| `lib/application/audio_controller.dart:43` | `ConcatenatingAudioSource` is deprecated | info — just_audio 0.10 prefers `AudioPlayer.setAudioSources`. The old API still works and is the only one that accepts a prebuilt `AudioSource` list with `initialIndex`. | **Left as-is**: no behavioural risk, deprecation is info-level and non-fatal. |

No Gradle/AGP code was involved yet — the job fails on analysis, before
`tool/bootstrap.sh`. Tests/APK build therefore still unverified.

## 2026-11-05 — CI run #2: **SUCCESS** (APK produced and verified)

Run: https://github.com/xorgxxx/nova_media/actions/runs/42036653331
Job: 8m13s (Gradle `assembleRelease` 5m35s). Every step green:
`pub get` → `analyze` (0 errors) → `test` → `bootstrap.sh` → `build apk
--release` → `verify_apk.sh` → artifact upload → summary.

`tool/bootstrap.sh` generated the Android host project from the Flutter 3.47.9
template, so AGP/Kotlin/Gradle came from the template itself
(Gradle 9.3.1, AGP 9.x, compileSdk 36, minSdk 24, NDK 28.2.13676358) and no
plugin needed a code change. `flutter create` and the override copies worked
unchanged.

**APK**

| Field | Value |
|---|---|
| Package | `com.novamedia.nova_media` |
| versionName / versionCode | `1.0.0` / `1` |
| compileSdk / targetSdk | 36 / 36 |
| Size | 56,460,374 bytes (53.9 MiB) — universal APK with all ABIs |
| SHA-256 | `6e5ccebad04399978e81bd455b4152487cd601fdb79c9f021262d5aedc0295d8` |
| Signature | debug key (per `AGENTS.md`; not accepted by Google Play) |

`verify_apk.sh` confirmed: `AndroidManifest.xml`, `classes.dex`,
`lib/arm64-v8a/libflutter.so`, `libapp.so` (AOT), and `aapt2 dump badging`
reported the expected package and `READ_MEDIA_*` / `FOREGROUND_SERVICE*`
permissions.

**Remaining caveats**

- No run on a real device/emulator: install, permissions, playback and
  background audio are still untested at runtime.
- One info-level lint remains (`ConcatenatingAudioSource` deprecated in
  just_audio 0.10) — deliberately not changed, see the table above.
- `actions/checkout@v4`, `actions/setup-java@v4` print a Node.js 20
  deprecation warning (still functional).

**Not verified yet**

- First CI run: Gradle/AGP ↔ plugin compatibility, manifest merger, and any
  analyzer errors the author could not see without a compiler.
- No APK has been installed on a real device or emulator; the workflow only
  performs the static checks in `tool/verify_apk.sh`.
