import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../application/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/routes.dart';
import '../../data/models/album_info.dart';
import '../../data/models/media_kind.dart';
import 'album_page.dart';
import 'photo_grid.dart';
import 'photo_viewer_page.dart';

class PhotosTab extends ConsumerStatefulWidget {
  const PhotosTab({super.key});

  @override
  ConsumerState<PhotosTab> createState() => _PhotosTabState();
}

class _PhotosTabState extends ConsumerState<PhotosTab> {
  static const _kind = MediaKind.image;
  int _segment = 0; // 0 folders, 1 all, 2 favorites

  Future<void> _refresh() async {
    ref.invalidate(libraryAssetsProvider(_kind));
    ref.invalidate(albumsProvider(_kind));
    await ref.read(libraryAssetsProvider(_kind).future);
  }

  void _openViewer(List<AssetEntity> list, int index) {
    Navigator.of(context).push(fadeRoute<void>(PhotoViewerPage(assets: list, initialIndex: index)));
  }

  @override
  Widget build(BuildContext context) {
    final favs = ref.watch(favoritesProvider(_kind)).valueOrNull ?? const <String>{};

    return SectionTheme(
      accent: Accents.photo,
      child: SectionPage(
        title: 'Photos',
        onRefresh: _refresh,
        header: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: SegmentedButton<int>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: 0, label: Text('Folders')),
              ButtonSegment(value: 1, label: Text('All')),
              ButtonSegment(value: 2, label: Text('Favorites')),
            ],
            selected: {_segment},
            onSelectionChanged: (s) => setState(() => _segment = s.first),
          ),
        ),
        slivers: _segment == 0 ? _folders() : _photos(favs),
      ),
    );
  }

  List<Widget> _folders() {
    final albums = ref.watch(albumsProvider(_kind));
    return albums.when(
      loading: () => [loadingSliver()],
      error: (e, _) => [emptySliver(icon: Icons.error_outline, title: 'Could not load folders', message: '$e')],
      data: (list) {
        if (list.isEmpty) {
          return [emptySliver(icon: Icons.photo_library_outlined, title: 'No photos found')];
        }
        return [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: list.length,
              itemBuilder: (context, i) => _AlbumCard(
                info: list[i],
                onTap: () => Navigator.of(context).push(fadeSlideRoute<void>(AlbumPage(album: list[i].ref))),
              ),
            ),
          ),
        ];
      },
    );
  }

  List<Widget> _photos(Set<String> favs) {
    final assets = ref.watch(libraryAssetsProvider(_kind));
    return assets.when(
      loading: () => [loadingSliver()],
      error: (e, _) => [emptySliver(icon: Icons.error_outline, title: 'Could not load photos', message: '$e')],
      data: (all) {
        final list = _segment == 2 ? all.where((a) => favs.contains(a.id)).toList() : all;
        if (list.isEmpty) {
          return [
            emptySliver(
              icon: _segment == 2 ? Icons.favorite_border_rounded : Icons.photo_library_outlined,
              title: _segment == 2 ? 'No favorite photos' : 'No photos found',
              message: _segment == 2 ? 'Open a photo and tap the heart.' : null,
            ),
          ];
        }
        return [
          PhotoGridSliver(assets: list, favorites: favs, onTap: (i) => _openViewer(list, i)),
        ];
      },
    );
  }
}

class _AlbumCard extends StatelessWidget {
  const _AlbumCard({required this.info, required this.onTap});

  final AlbumInfo info;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (info.cover != null)
              AssetThumb(asset: info.cover!, size: 420)
            else
              ColoredBox(color: theme.colorScheme.primary.withAlpha(40)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                ),
              ),
            ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    info.ref.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                  Text('${info.count}', style: const TextStyle(color: Colors.white70, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
