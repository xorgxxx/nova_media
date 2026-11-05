import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../application/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../core/widgets/common_widgets.dart';
import '../../data/models/media_kind.dart';
import '../../data/models/resume_point.dart';
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

  Future<void> _refresh() async {
    ref.invalidate(libraryAssetsProvider(_kind));
    ref.invalidate(videoProgressProvider);
    await ref.read(libraryAssetsProvider(_kind).future);
  }

  @override
  Widget build(BuildContext context) {
    final assets = ref.watch(libraryAssetsProvider(_kind));
    final favs = ref.watch(favoritesProvider(_kind)).valueOrNull ?? const <String>{};
    final progress = ref.watch(videoProgressProvider).valueOrNull ?? const <String, ResumePoint>{};

    return SectionTheme(
      accent: Accents.video,
      child: SectionPage(
        title: 'Videos',
        onRefresh: _refresh,
        header: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 0, label: Text('All')),
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
                error: (e, _) => [
                  emptySliver(
                    icon: Icons.error_outline,
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
    final list = _segment == 1 ? videos.where((v) => favs.contains(v.id)).toList() : videos;
    if (list.isEmpty) {
      return [
        emptySliver(
          icon: _segment == 1 ? Icons.favorite_border_rounded : Icons.video_library_outlined,
          title: _segment == 1 ? 'No favorite videos' : 'No videos found',
          message: _segment == 1
              ? 'Tap the heart on a video to keep it here.'
              : 'Videos stored on this device will appear here.',
        ),
      ];
    }

    final map = ref.watch(assetMapProvider(_kind));
    final resumables = progress.values.where((p) => p.isResumable && map.containsKey(p.assetId)).toList()
      ..sort((a, b) => b.updatedAt.compareTo(a.updatedAt));

    return [
      if (_segment == 0 && resumables.isNotEmpty)
        SliverToBoxAdapter(child: _ContinueWatching(points: resumables.take(10).toList(), map: map)),
      SliverList.builder(
        itemCount: list.length,
        itemBuilder: (context, i) {
          final v = list[i];
          return VideoTile(
            asset: v,
            isFavorite: favs.contains(v.id),
            progress: progress[v.id]?.fraction ?? 0,
            onTap: () => openVideoPlayer(context, list, i),
            onFavorite: () => ref.read(favoritesProvider(_kind).notifier).toggle(v.id),
            onAddToPlaylist: () => showAddToPlaylistSheet(context, _kind, v.id),
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
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
          child: Text('Continue watching', style: theme.textTheme.titleMedium),
        ),
        SizedBox(
          height: 132,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
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
                                child: Icon(Icons.play_circle_fill_rounded, color: Colors.white70, size: 38),
                              ),
                              Positioned(
                                left: 0,
                                right: 0,
                                bottom: 0,
                                child: LinearProgressIndicator(value: point.fraction, minHeight: 3),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
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
        const SizedBox(height: 8),
      ],
    );
  }
}
