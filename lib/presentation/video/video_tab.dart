import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../application/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/media_kind.dart';
import '../../data/models/resume_point.dart';
import '../common/delete_actions.dart';
import '../common/sort_sheet.dart';
import '../playlists/playlist_widgets.dart';
import 'video_actions.dart';
import 'video_tile.dart';

class VideoTab extends ConsumerStatefulWidget {
  const VideoTab({super.key});

  @override
  ConsumerState<VideoTab> createState() => _VideoTabState();
}

class _VideoTabState extends ConsumerState<VideoTab> {
  static const _kind = MediaKind.video;
  int _segment = 0; // 0 all, 1 favorites, 2 playlists
  final Set<String> _selected = <String>{};

  Future<void> _refresh() async {
    ref.invalidate(videoProgressProvider);
    await ref.read(libraryAssetsProvider(_kind).notifier).refresh();
  }

  void _toggleSelection(AssetEntity asset) {
    setState(() {
      if (!_selected.remove(asset.id)) _selected.add(asset.id);
    });
  }

  void _startSelection(AssetEntity asset) {
    setState(() => _selected.add(asset.id));
  }

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

  Future<void> _deleteSelected() async {
    final deleted = await deleteMediaAssets(
      context: context,
      ref: ref,
      kind: _kind,
      assetIds: _selected,
    );
    if (deleted > 0 && mounted) _clearSelection();
  }

  Future<void> _deleteOne(AssetEntity asset) async {
    final deleted = await deleteMediaAssets(
      context: context,
      ref: ref,
      kind: _kind,
      assetIds: [asset.id],
    );
    if (deleted > 0 && mounted && _selected.contains(asset.id)) {
      setState(() => _selected.remove(asset.id));
    }
  }

  @override
  Widget build(BuildContext context) {
    final assets = ref.watch(sortedAssetsProvider(_kind));
    final favs = ref.watch(favoritesProvider(_kind)).valueOrNull ?? const <String>{};
    final progress =
        ref.watch(videoProgressProvider).valueOrNull ?? const <String, ResumePoint>{};
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? AppSettings.defaults();
    final count = assets.valueOrNull?.length ?? 0;
    final sortLabel =
        '${settings.fieldFor(_kind).label} · ${settings.orderFor(_kind).label}';

    return SectionTheme(
      accent: Accents.video,
      child: SectionPage(
        title: 'Videos',
        subtitle: count == 0 ? 'Your local video library' : '$count videos · $sortLabel',
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
                ButtonSegment(value: 0, label: Text('All')),
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
                loading: () => [loadingSliver(label: 'Reading your video library…')],
                error: (e, _) => [
                  emptySliver(
                    icon: Icons.error_outline_rounded,
                    title: 'Could not load videos',
                    message: '$e',
                  ),
                ],
                data: (videos) => _buildList(videos, favs, progress),
              ),
      ),
    );
  }

  List<Widget> _buildList(
    List<AssetEntity> videos,
    Set<String> favs,
    Map<String, ResumePoint> progress,
  ) {
    final list = _segment == 1
        ? videos.where((v) => favs.contains(v.id)).toList()
        : videos;
    if (list.isEmpty) {
      return [
        emptySliver(
          icon: _segment == 1
              ? Icons.favorite_border_rounded
              : Icons.video_library_outlined,
          title: _segment == 1 ? 'No favorite videos' : 'No videos found',
          message: _segment == 1
              ? 'Tap the heart on a video to keep it here.'
              : 'Videos stored on this device will appear here.',
        ),
      ];
    }

    final map = ref.watch(assetMapProvider(_kind));
    final resumables = progress.values
        .where((p) => p.isResumable && map.containsKey(p.assetId))
        .toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return [
      if (_segment == 0 && resumables.isNotEmpty && _selected.isEmpty)
        SliverToBoxAdapter(
          child: _ContinueWatching(
            points: resumables.take(10).toList(),
            map: map,
          ),
        ),
      SliverList.builder(
        itemCount: list.length,
        itemBuilder: (context, i) {
          final v = list[i];
          return VideoTile(
            asset: v,
            isFavorite: favs.contains(v.id),
            progress: progress[v.id]?.fraction ?? 0,
            selectionMode: _selected.isNotEmpty,
            selected: _selected.contains(v.id),
            onTap: () {
              if (_selected.isNotEmpty) {
                _toggleSelection(v);
              } else {
                openVideoPlayer(context, list, i);
              }
            },
            onLongPress: () => _startSelection(v),
            onFavorite: () => ref.read(favoritesProvider(_kind).notifier).toggle(v.id),
            onAddToPlaylist: () => showAddToPlaylistSheet(context, _kind, v.id),
            onDelete: () => _deleteOne(v),
          );
        },
      ),
    ];
  }
}

class _ContinueWatching extends StatelessWidget {
  const _ContinueWatching({required this.points, required this.map});

  final List<ResumePoint> points;
  final Map<String, AssetEntity> map;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
          child: Text('Continue watching', style: theme.textTheme.titleMedium),
        ),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: points.length,
            separatorBuilder: (context, i) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final point = points[i];
              final asset = map[point.assetId]!;
              return GestureDetector(
                onTap: () => openVideoPlayer(context, [asset], 0),
                child: SizedBox(
                  width: 190,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: SizedBox(
                          height: 107,
                          width: 190,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              AssetThumb(asset: asset, size: 400),
                              const Center(
                                child: Icon(
                                  Icons.play_circle_fill_rounded,
                                  color: Colors.white70,
                                  size: 38,
                                ),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: LinearProgressIndicator(
                                  value: point.fraction,
                                  minHeight: 3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        cleanTitle(asset.title),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
      ],
    );
  }
}
