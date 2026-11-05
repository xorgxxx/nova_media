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

**Not verified yet**

- First CI run: Gradle/AGP ↔ plugin compatibility, manifest merger, and any
  analyzer errors the author could not see without a compiler.
- No APK has been installed on a real device or emulator; the workflow only
  performs the static checks in `tool/verify_apk.sh`.
