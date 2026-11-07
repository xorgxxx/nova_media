import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../application/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/media_kind.dart';
import '../common/delete_actions.dart';
import '../common/sort_sheet.dart';
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
  final Set<String> _selected = <String>{};

  Future<void> _refresh() =>
      ref.read(libraryAssetsProvider(_kind).notifier).refresh();

  void _toggleSelection(AssetEntity asset) {
    setState(() {
      if (!_selected.remove(asset.id)) _selected.add(asset.id);
    });
  }

  void _startSelection(AssetEntity asset) =>
      setState(() => _selected.add(asset.id));

  void _clearSelection() => setState(_selected.clear);

  void _selectAll(List<AssetEntity> assets) {
    setState(() {
      if (_selected.length == assets.length) {
        _selected.clear();
      } else {
        _selected
          ..clear()
          ..addAll(assets.map((asset) => asset.id));
      }
    });
  }

  Future<void> _stopIfPlayingDeleted(Iterable<String> ids) async {
    final currentId = ref.read(currentMediaItemProvider).valueOrNull?.id;
    if (currentId != null && ids.contains(currentId)) {
      await ref.read(audioControllerProvider).player.stop();
    }
  }

  Future<void> _deleteSelected() async {
    final ids = _selected.toList(growable: false);
    final deleted = await deleteMediaAssets(
      context: context,
      ref: ref,
      kind: _kind,
      assetIds: ids,
    );
    if (deleted > 0) {
      await _stopIfPlayingDeleted(ids);
      if (mounted) _clearSelection();
    }
  }

  Future<void> _deleteOne(AssetEntity asset) async {
    final deleted = await deleteMediaAssets(
      context: context,
      ref: ref,
      kind: _kind,
      assetIds: [asset.id],
    );
    if (deleted > 0) {
      await _stopIfPlayingDeleted([asset.id]);
      if (mounted && _selected.contains(asset.id)) {
        setState(() => _selected.remove(asset.id));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final assets = ref.watch(sortedAssetsProvider(_kind));
    final favs = ref.watch(favoritesProvider(_kind)).valueOrNull ?? const <String>{};
    final currentId = ref.watch(currentMediaItemProvider).valueOrNull?.id;
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? AppSettings.defaults();
    final count = assets.valueOrNull?.length ?? 0;
    final sortLabel =
        '${settings.fieldFor(_kind).label} · ${settings.orderFor(_kind).label}';

    return SectionTheme(
      accent: Accents.music,
      child: SectionPage(
        title: 'Music',
        subtitle: count == 0 ? 'Your local music library' : '$count tracks · $sortLabel',
        onRefresh: _refresh,
        onOpenSort: () => showSortSheet(context, ref, _kind),
        selectionCount: _segment == 2 ? 0 : _selected.length,
        allSelected: _segment != 2 &&
            _selected.isNotEmpty &&
            _selected.length == (assets.valueOrNull?.length ?? 0),
        onExitSelection: _clearSelection,
        onSelectAll: () => _selectAll(assets.valueOrNull ?? const []),
        onDeleteSelected: _deleteSelected,
        header: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: SizedBox(
            width: double.infinity,
            child: SegmentedButton<int>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: 0, label: Text('Songs')),
                ButtonSegment(value: 1, label: Text('Favorites')),
                ButtonSegment(value: 2, label: Text('Playlists')),
              ],
              selected: {_segment},
              onSelectionChanged: (s) => setState(() {
                _segment = s.first;
                _selected.clear();
              }),
            ),
          ),
        ),
        slivers: _segment == 2
            ? [const PlaylistsSliver(kind: _kind)]
            : assets.when(
                skipLoadingOnReload: true,
                loading: () => [loadingSliver(label: 'Reading your music library…')],
                error: (e, _) => [
                  emptySliver(
                    icon: Icons.error_outline_rounded,
                    title: 'Could not load music',
                    message: '$e',
                  ),
                ],
                data: (tracks) => _buildList(tracks, favs, currentId),
              ),
      ),
    );
  }

  List<Widget> _buildList(
    List<AssetEntity> tracks,
    Set<String> favs,
    String? currentId,
  ) {
    final list = _segment == 1
        ? tracks.where((t) => favs.contains(t.id)).toList()
        : tracks;
    if (list.isEmpty) {
      return [
        emptySliver(
          icon: _segment == 1
              ? Icons.favorite_border_rounded
              : Icons.library_music_outlined,
          title: _segment == 1 ? 'No favorite songs' : 'No music found',
          message: _segment == 1
              ? 'Tap the heart on a song to keep it here.'
              : 'Audio files on this device will appear here.',
        ),
      ];
    }
    final audio = ref.read(audioControllerProvider);
    return [
      if (_selected.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
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
                  child: OutlinedButton.icon(
                    onPressed: () => audio.playQueue(
                      list,
                      DateTime.now().millisecond % list.length,
                      shuffle: true,
                    ),
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
            selectionMode: _selected.isNotEmpty,
            selected: _selected.contains(t.id),
            onTap: () {
              if (_selected.isNotEmpty) {
                _toggleSelection(t);
              } else {
                audio.playQueue(list, i);
              }
            },
            onLongPress: () => _startSelection(t),
            onFavorite: () => ref.read(favoritesProvider(_kind).notifier).toggle(t.id),
            onAddToPlaylist: () => showAddToPlaylistSheet(context, _kind, t.id),
            onDelete: () => _deleteOne(t),
          );
        },
      ),
    ];
  }
}
