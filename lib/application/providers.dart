import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart' show MediaItem;
import 'package:photo_manager/photo_manager.dart';

import '../data/models/album_info.dart';
import '../data/models/media_kind.dart';
import '../data/models/playlist.dart';
import '../data/models/resume_point.dart';
import '../data/repositories/library_repository.dart';
import '../data/repositories/user_data_repository.dart';
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

// ---- Library --------------------------------------------------------------

final libraryAssetsProvider = FutureProvider.family<List<AssetEntity>, MediaKind>(
  (ref, kind) => ref.watch(libraryRepositoryProvider).loadAll(kind),
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
