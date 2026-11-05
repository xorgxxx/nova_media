# Architecture

Layers (dependencies point downward only):

```
presentation/  widgets & pages (no business logic, no direct plugin calls except playback widgets)
application/   Riverpod providers + AudioController (state and use-cases)
data/          LibraryRepository (photo_manager), UserDataRepository (sqflite), models
core/          theme, routes, shared widgets, formatting helpers
```

## Key decisions
- **One media source for all three sections**: `photo_manager` reads Android MediaStore for images, videos and audio, and handles runtime permissions (READ_MEDIA_* on API 33+, READ_EXTERNAL_STORAGE below).
- **IDs, not paths**: favorites, playlists and resume points store `AssetEntity.id`. Items whose file disappeared are silently dropped when resolving against the library (`assetMapProvider`).
- **SQLite schema** (`data/database/app_database.dart`): `favorites(kind, asset_id)`, `playlists(id, kind, name)`, `playlist_items(playlist_id, asset_id, position)`, `progress(asset_id, position_ms, duration_ms)`. Bump `_version` and add `onUpgrade` for any schema change.
- **Video**: `video_player` (ExoPlayer). `VideoPlayerPage` owns its controller, saves progress every 5s and on dispose, and rotates/immersive-mode itself.
- **Audio**: `AudioController` wraps `just_audio`; `just_audio_background` (initialised in `main()`) gives notification + lock-screen controls when each source carries a `MediaItem` tag. Android needs `MainActivity : AudioServiceActivity` and the service/receiver in the manifest (both in `android_overrides/`).
- **Identity**: each section has an accent (`Accents.video/photo/music`); `SectionTheme` re-tints the subtree.
- **Navigation**: plain Navigator with custom transitions (`core/widgets/routes.dart`) + Hero for photos and now-playing art.

## Provider map (application/providers.dart)
`permissionProvider` · `libraryAssetsProvider(kind)` · `assetMapProvider(kind)` · `albumsProvider(kind)` · `albumAssetsProvider(albumRef)` · `favoritesProvider(kind)` · `playlistsProvider(kind)` · `playlistItemsProvider(id)` · `videoProgressProvider` · `audioControllerProvider` · `currentMediaItemProvider` · `playerStateProvider`

## Adding a feature
1. Data access → repository method. 2. Expose via provider. 3. Build UI that only watches providers. 4. Add a unit test for pure logic.
