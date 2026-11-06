import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart' show MediaItem;
import 'package:photo_manager/photo_manager.dart';

import '../data/models/album_info.dart';
import '../data/models/app_settings.dart';
import '../data/models/media_kind.dart';
import '../data/models/playlist.dart';
import '../data/models/resume_point.dart';
import '../data/repositories/library_repository.dart';
import '../data/repositories/user_data_repository.dart';
import '../data/services/media_sort_service.dart';
import 'audio_controller.dart';

// ---- Repositories ---------------------------------------------------------

/// Overridden in main() with an opened database.
final userDataRepositoryProvider = Provider<UserDataRepository>(
  (ref) => throw UnimplementedError('userDataRepositoryProvider must be overridden in main()'),
);

final libraryRepositoryProvider = Provider<LibraryRepository>((ref) => LibraryRepository());

// ---- Permission -----------------------------------------------------------

class PermissionNotifier extends AsyncNotifier<PermissionState> {
  @override
  Future<PermissionState> build() => ref.read(libraryRepositoryProvider).permissionState();

  Future<void> request() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(libraryRepositoryProvider).requestPermission());
    _reloadIfGranted();
  }

  /// Silent re-check (e.g. after returning from system settings).
  Future<void> refresh() async {
    state = await AsyncValue.guard(() => ref.read(libraryRepositoryProvider).permissionState());
    _reloadIfGranted();
  }

  void _reloadIfGranted() {
    if (state.valueOrNull?.hasAccess ?? false) {
      ref.invalidate(libraryAssetsProvider);
      ref.invalidate(albumsProvider);
    }
  }
}

final permissionProvider =
    AsyncNotifierProvider<PermissionNotifier, PermissionState>(PermissionNotifier.new);

// ---- Settings -------------------------------------------------------------

class SettingsNotifier extends AsyncNotifier<AppSettings> {
  static const _themeKey = 'theme_mode';
  static const _gridKey = 'grid_columns';

  @override
  Future<AppSettings> build() async {
    final defaults = AppSettings.defaults();
    Map<String, String> raw;
    try {
      raw = await ref.read(userDataRepositoryProvider).settings();
    } catch (_) {
      raw = const <String, String>{};
    }

    final fields = <MediaKind, SortField>{};
    final orders = <MediaKind, SortOrder>{};
    for (final kind in MediaKind.values) {
      fields[kind] = parseSortField(
        raw['sort_field_${kind.name}'],
        defaults.fieldFor(kind),
      );
      orders[kind] = parseSortOrder(
        raw['sort_order_${kind.name}'],
        defaults.orderFor(kind),
      );
    }

    final columns = int.tryParse(raw[_gridKey] ?? '') ?? defaults.gridColumns;
    return AppSettings(
      themeMode: parseThemeMode(raw[_themeKey], defaults.themeMode),
      gridColumns: columns.clamp(2, 5).toInt(),
      sortFields: fields,
      sortOrders: orders,
    );
  }

  AppSettings get _current => state.valueOrNull ?? AppSettings.defaults();

  Future<void> _write(Map<String, String> values, AppSettings next) async {
    state = AsyncData(next); // optimistic: the UI reacts immediately
    try {
      final repo = ref.read(userDataRepositoryProvider);
      for (final entry in values.entries) {
        await repo.setSetting(entry.key, entry.value);
      }
    } catch (_) {
      // Keep the in-memory choice even if persistence failed.
    }
  }

  Future<void> setThemeMode(AppThemeMode mode) {
    return _write(
      {_themeKey: mode.name},
      _current.copyWith(themeMode: mode),
    );
  }

  Future<void> setGridColumns(int columns) {
    final clamped = columns.clamp(2, 5).toInt();
    return _write(
      {_gridKey: '$clamped'},
      _current.copyWith(gridColumns: clamped),
    );
  }

  Future<void> setSort(MediaKind kind, SortField field, SortOrder order) {
    return _write(
      {
        'sort_field_${kind.name}': field.name,
        'sort_order_${kind.name}': order.name,
      },
      _current.withSort(kind, field, order),
    );
  }
}

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

// ---- Library --------------------------------------------------------------

class LibraryAssetsNotifier extends FamilyAsyncNotifier<List<AssetEntity>, MediaKind> {
  @override
  Future<List<AssetEntity>> build(MediaKind arg) =>
      ref.read(libraryRepositoryProvider).loadAll(arg);

  /// Removes assets from the in-memory list after a successful deletion,
  /// without re-scanning the whole MediaStore library.
  void removeIds(Iterable<String> ids) {
    final current = state.valueOrNull;
    if (current == null) return;
    final removed = ids.toSet();
    if (removed.isEmpty) return;
    state = AsyncData([
      for (final asset in current)
        if (!removed.contains(asset.id)) asset,
    ]);
  }

  /// Explicit pull-to-refresh: the only path that re-scans MediaStore.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(
      () => ref.read(libraryRepositoryProvider).loadAll(arg),
    );
  }
}

final libraryAssetsProvider =
    AsyncNotifierProvider.family<LibraryAssetsNotifier, List<AssetEntity>, MediaKind>(
  LibraryAssetsNotifier.new,
);

/// Raw list sorted with the user's current "Sort by" + "Sort order" choice.
final sortedAssetsProvider = FutureProvider.family<List<AssetEntity>, MediaKind>(
  (ref, kind) async {
    final assets = await ref.watch(libraryAssetsProvider(kind).future);
    final settings = await ref.watch(settingsProvider.future);
    return MediaSortService(ref.watch(userDataRepositoryProvider)).sort(
      assets,
      kind: kind,
      field: settings.fieldFor(kind),
      order: settings.orderFor(kind),
    );
  },
);

final assetMapProvider = Provider.family<Map<String, AssetEntity>, MediaKind>((ref, kind) {
  final list = ref.watch(libraryAssetsProvider(kind)).valueOrNull ?? const <AssetEntity>[];
  return {for (final a in list) a.id: a};
});

final albumsProvider = FutureProvider.family<List<AlbumInfo>, MediaKind>(
  (ref, kind) => ref.watch(libraryRepositoryProvider).loadAlbums(kind),
);

final albumAssetsProvider = FutureProvider.family<List<AssetEntity>, AlbumRef>(
  (ref, album) => ref.watch(libraryRepositoryProvider).loadAlbumAssets(album),
);

/// Album contents sorted with the same rules as the main photo grid.
final sortedAlbumAssetsProvider = FutureProvider.family<List<AssetEntity>, AlbumRef>(
  (ref, album) async {
    final assets = await ref.watch(albumAssetsProvider(album).future);
    final settings = await ref.watch(settingsProvider.future);
    return MediaSortService(ref.watch(userDataRepositoryProvider)).sort(
      assets,
      kind: album.kind,
      field: settings.fieldFor(album.kind),
      order: settings.orderFor(album.kind),
    );
  },
);

// ---- Favorites ------------------------------------------------------------

class FavoritesNotifier extends FamilyAsyncNotifier<Set<String>, MediaKind> {
  @override
  Future<Set<String>> build(MediaKind arg) =>
      ref.read(userDataRepositoryProvider).favoriteIds(arg);

  Future<void> toggle(String assetId) async {
    final next = <String>{...(state.valueOrNull ?? <String>{})};
    final nowFavorite = !next.remove(assetId);
    if (nowFavorite) next.add(assetId);
    state = AsyncData(next); // optimistic
    await ref.read(userDataRepositoryProvider).setFavorite(arg, assetId, nowFavorite);
  }
}

final favoritesProvider =
    AsyncNotifierProvider.family<FavoritesNotifier, Set<String>, MediaKind>(FavoritesNotifier.new);

// ---- Playlists ------------------------------------------------------------

class PlaylistsNotifier extends FamilyAsyncNotifier<List<Playlist>, MediaKind> {
  @override
  Future<List<Playlist>> build(MediaKind arg) =>
      ref.read(userDataRepositoryProvider).playlists(arg);

  Future<int> create(String name) async {
    final id = await ref.read(userDataRepositoryProvider).createPlaylist(arg, name);
    ref.invalidateSelf();
    await future;
    return id;
  }

  Future<void> rename(int id, String name) async {
    await ref.read(userDataRepositoryProvider).renamePlaylist(id, name);
    ref.invalidateSelf();
  }

  Future<void> delete(int id) async {
    await ref.read(userDataRepositoryProvider).deletePlaylist(id);
    ref.invalidate(playlistItemsProvider(id));
    ref.invalidateSelf();
  }

  Future<void> addItem(int playlistId, String assetId) async {
    await ref.read(userDataRepositoryProvider).addToPlaylist(playlistId, assetId);
    ref.invalidate(playlistItemsProvider(playlistId));
    ref.invalidateSelf();
  }

  Future<void> removeItem(int playlistId, String assetId) async {
    await ref.read(userDataRepositoryProvider).removeFromPlaylist(playlistId, assetId);
    ref.invalidate(playlistItemsProvider(playlistId));
    ref.invalidateSelf();
  }
}

final playlistsProvider =
    AsyncNotifierProvider.family<PlaylistsNotifier, List<Playlist>, MediaKind>(PlaylistsNotifier.new);

final playlistItemsProvider = FutureProvider.family<List<String>, int>(
  (ref, playlistId) => ref.watch(userDataRepositoryProvider).playlistItemIds(playlistId),
);

// ---- Video resume points --------------------------------------------------

final videoProgressProvider = FutureProvider<Map<String, ResumePoint>>(
  (ref) => ref.watch(userDataRepositoryProvider).allProgress(),
);

// ---- Audio ----------------------------------------------------------------

final audioControllerProvider = Provider<AudioController>((ref) {
  final controller = AudioController();
  ref.onDispose(controller.dispose);
  return controller;
});

final currentMediaItemProvider = StreamProvider<MediaItem?>((ref) {
  final player = ref.watch(audioControllerProvider).player;
  return player.sequenceStateStream.map((s) => s.currentSource?.tag as MediaItem?);
});

final playerStateProvider = StreamProvider<PlayerState>(
  (ref) => ref.watch(audioControllerProvider).player.playerStateStream,
);
