# Build log

Every change made while getting `nova_media` to build is recorded here (see `AGENTS.md`).

## 2026-11-07 — AS Vault 1.1.0 (arm64-only): real delete, sorting, redesign, settings, new icon

**Scope.** The app keeps its layered architecture, package id (`com.novamedia.nova_media`),
database (`nova_media.db`) and every 1.0.0 feature. Version bumped to `1.1.0+2`;
user-visible name is **AS Vault** everywhere (launcher, app title, settings, release,
README). The package id is deliberately unchanged so an in-place update keeps
favorites, playlists and resume points.

**Real deletion (images / videos / audio)**

- `lib/presentation/common/delete_actions.dart` — in-app confirmation, then
  `PhotoManager.editor.deleteWithIds()` which uses Android's official
  `MediaStore.createDeleteRequest` sheet on API 30+. Only the ids Android
  actually deleted are removed from the in-memory list; favorites, playlists,
  resume points and album counts are invalidated. No full MediaStore rescan.
- Multi-select + select-all wired into the video, photo and music tabs
  (`video_tab.dart`, `photos_tab.dart`, `music_tab.dart`), plus playlist item
  removal (`playlist_widgets.dart`).
- `UserDataRepository.removeAssets()` cleans DB rows for deleted ids.
- Permissions: `READ_MEDIA_IMAGES/VIDEO/AUDIO` (API 33+),
  `READ_EXTERNAL_STORAGE` (maxSdk 32), `WRITE_EXTERNAL_STORAGE` (maxSdk 29) —
  no storage-management or broad file permissions.

**Sorting**

- `lib/core/utils/media_sort.dart` — pure sort for **Name / Size / Date /
  Duration** × **Ascending / Descending**, per media type (Duration hidden for
  still images), deterministic ties, original list never mutated.
- `lib/data/services/media_sort_service.dart` — byte sizes resolved with
  12-way concurrency and cached in SQLite (`asset_sizes`, keyed by modified
  date) so later sorts do not touch MediaStore.
- Settings persisted per kind (`sort_field_<kind>`, `sort_order_<kind>`);
  `sort_sheet.dart` offers the two independent choices with directional hints.
- `test/sort_test.dart` covers fields, orders, parse fallbacks, duration on
  images, name/size/date/duration ordering and input immutability.

**UI redesign**

- New premium theme (`app_theme.dart`), typography scale, section accents,
  cards, empty states, sort sheet, confirmations and a 4-tab shell
  (`home_shell.dart`) with animated tab transitions.
- Rewritten video/photos/music tabs and tiles, album page, photo viewer,
  mini-player integration; list rows and grids share spacing and radii.

**Performance**

- Bounded Flutter image cache (600 images / 160 MB) in `main.dart`.
- `photo_manager_image_provider` thumbnails + `cacheWidth` on grids; lazy
  `SliverList`/`SliverGrid` and range-based album loading (`LibraryRepository`).
- Deletion updates only the affected list; pull-to-refresh is the only path
  that rescans MediaStore.
- `AsyncValue.when(skipLoadingOnReload: true)` keeps lists on screen while a
  re-sort completes, avoiding a loading flash after each change.

**Settings page** (`settings_page.dart`)

- Recent files, real storage free/used from Android (`as_vault/system` channel:
  `storageStats`, `clearAppCache`), thumbnail cache size + clear, theme
  (System/Light/Dark), photo grid density 2–5, per-kind sorting, version/build,
  architecture, package, privacy. All controls perform real work.

**Icon**

- `tool/generate_icon.py` builds the launcher art from
  `assets/icon/source_rose.jpg` (byte-identical to the supplied photo):
  feathered 68% foreground, dark blurred backdrop with a restrained red halo,
  no text/frame. Outputs adaptive foreground/background, legacy icons
  (48–192 px), round variants, 512/1024 exports and circle/square/squircle
  mask previews. `tool/bootstrap.sh` copies `android_overrides/res` into the
  generated project.
- Manifest: label `AS Vault`, `android:icon` / `android:roundIcon` wired; adaptive
  XML keeps no monochrome layer (keeps the rose visible on every mask).

**CI / build**

- Workflow builds `flutter build apk --release --target-platform android-arm64`,
  bootstraps `abiFilters arm64-v8a`, verifies no other ABI, checks label /
  `native-code`, and publishes `AS-Vault-<version>-arm64.apk` to a GitHub
  Release (public, resumable).
- Fixed a YAML indentation error that made the workflow file invalid, and the
  analyzer errors surfaced by the first 1.1.0 run (`outlineVariant` scope,
  `_IdentityCard.build` field name, unused import, const lints).
- `tool/build.sh` now builds arm64 only, matching CI.

**Verification**

- `flutter analyze` → 0 errors; `flutter test` → all pass (sorting + formatting).
- CI run [42350072438](https://github.com/xorgxxx/nova_media/actions/runs/42350072438)
  (commit `7e79684`) green: analyze → tests → bootstrap → arm64 build → verify →
  Release publish.
- Release `v1.1.0` asset `AS-Vault-1.1.0-arm64.apk`:
  **21,937,428 bytes**, SHA-256
  `dd718dc2a8d9a9cd6d6994a3c62ad269896edcd64f4b017eaad93c3394612e13`,
  versionName `1.1.0` / versionCode `2`, targetSdk 36.
- `tool/verify_apk.sh`: label `AS Vault`, `native-code: arm64-v8a`, no
  `armeabi-v7a`/`x86`/`x86_64` libraries ("ABI check: arm64-v8a only").

**Not verifiable in CI**

- No device/emulator: permissions, system delete sheet, playback and icon masks
  are not runtime-tested. Icon resources are linked and the APK label verified
  with `aapt2`; visual mask check must be done on a phone.
- Debug signing (unchanged), so the APK is for direct install, not Play Store.

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

### Release publishing (run #3)

Artifact downloads from the Azure blob CDN kept dying on the author's
connection (`wsarecv` timeout, 0 bytes received), so the pipeline now also
publishes the APK as a **GitHub Release** asset, which is served from
`objects.githubusercontent.com` and supports HTTP range / resume:

- New step `Publish APK to GitHub Releases` (after the artifact upload):
  tag `v<version from pubspec>`, asset `app-release.apk` + `app-release.apk.sha256`,
  re-uploaded with `--clobber` on every build so the URL stays stable.
- `permissions` changed from `contents: read` to `contents: write` (needed for
  the release; the workflow never writes to the source tree).
- Direct link: https://github.com/xorgxxx/nova_media/releases/download/v1.0.0/app-release.apk
- Run: https://github.com/xorgxxx/nova_media/actions/runs/42065563450 (9m)

That build's APK SHA-256 is
`f73afeb0366310d6da132d1596e13904b475252c16713e23a1c7ddbfa9d1b451`
(same size, 56,460,374 bytes). Flutter builds are not byte-reproducible, so
the hash of run #2 above differs — always compare against the release asset.

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
