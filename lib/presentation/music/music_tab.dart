import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../application/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/media_kind.dart';
import '../playlists/playlist_widgets.dart';
import 'track_tile.dart';

class MusicTab extends ConsumerStatefulWidget {
  const MusicTab({super.key});

  @override
  ConsumerState<MusicTab> createState() => _MusicTabState();
}

class _MusicTabState extends ConsumerState<MusicTab> {
  static const _kind = MediaKind.audio;
  int _segment = 0; // 0 songs, 1 favorites, 2 playlists

  Future<void> _refresh() async {
    ref.invalidate(libraryAssetsProvider(_kind));
    await ref.read(libraryAssetsProvider(_kind).future);
  }

  @override
  Widget build(BuildContext context) {
    final assets = ref.watch(libraryAssetsProvider(_kind));
    final favs = ref.watch(favoritesProvider(_kind)).valueOrNull ?? const <String>{};
    final currentId = ref.watch(currentMediaItemProvider).valueOrNull?.id;

    return SectionTheme(
      accent: Accents.music,
      child: SectionPage(
        title: 'Music',
        onRefresh: _refresh,
        header: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 0, label: Text('Songs')),
              ButtonSegment(value: 1, label: Text('Favorites')),
              ButtonSegment(value: 2, label: Text('Playlists')),
            ],
            selected: {_segment},
            onSelectionChanged: (s) => setState(() => _segment = s.first),
          ),
        ),
        slivers: _segment == 2
            ? [const PlaylistsSliver(kind: _kind)]
            : assets.when(
                loading: () => [loadingSliver()],
                error: (e, _) => [emptySliver(icon: Icons.error_outline, title: 'Could not load music', message: '$e')],
                data: (tracks) => _buildList(tracks, favs, currentId),
              ),
      ),
    );
  }

  List<Widget> _buildList(List<AssetEntity> tracks, Set<String> favs, String? currentId) {
    final list = _segment == 1 ? tracks.where((t) => favs.contains(t.id)).toList() : tracks;
    if (list.isEmpty) {
      return [
        emptySliver(
          icon: _segment == 1 ? Icons.favorite_border_rounded : Icons.library_music_outlined,
          title: _segment == 1 ? 'No favorite songs' : 'No music found',
          message: _segment == 1
              ? 'Tap the heart on a song to keep it here.'
              : 'Audio files on this device will appear here.',
        ),
      ];
    }
    final audio = ref.read(audioControllerProvider);
    return [
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => audio.playQueue(list, 0, shuffle: false),
                  icon: const Icon(Icons.play_arrow_rounded),
                  label: const Text('Play all'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton.tonalIcon(
                  onPressed: () => audio.playQueue(list, DateTime.now().millisecond % list.length, shuffle: true),
                  icon: const Icon(Icons.shuffle_rounded),
                  label: const Text('Shuffle'),
                ),
              ),
            ],
          ),
        ),
      ),
      SliverList.builder(
        itemCount: list.length,
        itemBuilder: (context, i) {
          final t = list[i];
          return TrackTile(
            asset: t,
            isFavorite: favs.contains(t.id),
            isCurrent: currentId == t.id,
            onTap: () => audio.playQueue(list, i),
            onFavorite: () => ref.read(favoritesProvider(_kind).notifier).toggle(t.id),
            onAddToPlaylist: () => showAddToPlaylistSheet(context, _kind, t.id),
          );
        },
      ),
    ];
  }
}
