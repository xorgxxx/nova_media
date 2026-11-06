import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../application/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/media_kind.dart';
import '../../data/models/playlist.dart';
import '../common/delete_actions.dart';
import '../music/track_tile.dart';
import '../video/video_actions.dart';
import '../video/video_tile.dart';
import 'playlist_widgets.dart';

class PlaylistDetailPage extends ConsumerWidget {
  const PlaylistDetailPage({super.key, required this.playlistId, required this.kind});

  final int playlistId;
  final MediaKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider(kind)).valueOrNull ?? const <Playlist>[];
    Playlist? playlist;
    for (final p in playlists) {
      if (p.id == playlistId) playlist = p;
    }
    final ids = ref.watch(playlistItemsProvider(playlistId));
    final map = ref.watch(assetMapProvider(kind));
    final favs = ref.watch(favoritesProvider(kind)).valueOrNull ?? const <String>{};
    final currentId = ref.watch(currentMediaItemProvider).valueOrNull?.id;
    final notifier = ref.read(playlistsProvider(kind).notifier);

    final items = <AssetEntity>[
      for (final id in ids.valueOrNull ?? const <String>[])
        if (map[id] != null) map[id]!,
    ];

    Future<void> playAll({bool shuffle = false}) async {
      if (items.isEmpty) return;
      if (kind == MediaKind.video) {
        await openVideoPlayer(context, items, 0);
      } else {
        await ref.read(audioControllerProvider).playQueue(items, 0, shuffle: shuffle ? true : null);
      }
    }

    Future<void> deleteItem(AssetEntity asset) async {
      final deleted = await deleteMediaAssets(
        context: context,
        ref: ref,
        kind: kind,
        assetIds: [asset.id],
      );
      if (deleted > 0 && kind == MediaKind.audio) {
        final currentId = ref.read(currentMediaItemProvider).valueOrNull?.id;
        if (currentId == asset.id) {
          await ref.read(audioControllerProvider).player.stop();
        }
      }
    }

    return SectionTheme(
      accent: accentFor(kind),
      child: Scaffold(
        appBar: AppBar(
          title: Text(playlist?.name ?? 'Playlist'),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) async {
                final navigator = Navigator.of(context);
                if (value == 'rename') {
                  final name = await promptForName(context,
                      title: 'Rename playlist', initial: playlist?.name ?? '');
                  if (name != null) await notifier.rename(playlistId, name);
                } else if (value == 'delete') {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete playlist?'),
                      content: const Text('The files themselves are not deleted.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                        FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await notifier.delete(playlistId);
                    navigator.pop();
                  }
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'rename', child: Text('Rename')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ],
        ),
        floatingActionButton: items.isEmpty
            ? null
            : FloatingActionButton.extended(
                onPressed: () => playAll(),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Play all'),
              ),
        body: ids.isLoading
            ? const Center(child: CircularProgressIndicator())
            : items.isEmpty
                ? const EmptyState(
                    icon: Icons.queue_music_rounded,
                    title: 'This playlist is empty',
                    message: 'Add items from the ⋮ menu of any video or track.',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(bottom: 96),
                    itemCount: items.length,
                    itemBuilder: (context, i) {
                      final asset = items[i];
                      final tile = kind == MediaKind.video
                          ? VideoTile(
                              asset: asset,
                              isFavorite: favs.contains(asset.id),
                              onTap: () => openVideoPlayer(context, items, i),
                              onFavorite: () =>
                                  ref.read(favoritesProvider(kind).notifier).toggle(asset.id),
                              onAddToPlaylist: () => showAddToPlaylistSheet(context, kind, asset.id),
                              onDelete: () => deleteItem(asset),
                            )
                          : TrackTile(
                              asset: asset,
                              isFavorite: favs.contains(asset.id),
                              isCurrent: currentId == asset.id,
                              onTap: () => ref.read(audioControllerProvider).playQueue(items, i),
                              onFavorite: () =>
                                  ref.read(favoritesProvider(kind).notifier).toggle(asset.id),
                              onAddToPlaylist: () => showAddToPlaylistSheet(context, kind, asset.id),
                              onDelete: () => deleteItem(asset),
                            );
                      return Dismissible(
                        key: ValueKey('pl-$playlistId-${asset.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 24),
                          color: Theme.of(context).colorScheme.errorContainer,
                          child: const Icon(Icons.remove_circle_outline),
                        ),
                        onDismissed: (_) => notifier.removeItem(playlistId, asset.id),
                        child: tile,
                      );
                    },
                  ),
      ),
    );
  }
}
