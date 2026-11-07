import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../application/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/routes.dart';
import '../../data/models/album_info.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/media_kind.dart';
import '../common/delete_actions.dart';
import '../common/sort_sheet.dart';
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
  final Set<String> _selected = <String>{};

  Future<void> _refresh() async {
    ref.invalidate(albumsProvider(_kind));
    await ref.read(libraryAssetsProvider(_kind).notifier).refresh();
  }

  void _openViewer(List<AssetEntity> list, int index) {
    Navigator.of(context).push(fadeRoute<void>(PhotoViewerPage(assets: list, initialIndex: index)));
  }

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

  Future<void> _deleteSelected() async {
    final deleted = await deleteMediaAssets(
      context: context,
      ref: ref,
      kind: _kind,
      assetIds: _selected,
    );
    if (deleted > 0 && mounted) _clearSelection();
  }

  @override
  Widget build(BuildContext context) {
    final favs = ref.watch(favoritesProvider(_kind)).valueOrNull ?? const <String>{};
    final assets = ref.watch(sortedAssetsProvider(_kind));
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? AppSettings.defaults();
    final count = assets.valueOrNull?.length ?? 0;
    final sortLabel =
        '${settings.fieldFor(_kind).label} · ${settings.orderFor(_kind).label}';

    return SectionTheme(
      accent: Accents.photo,
      child: SectionPage(
        title: 'Photos',
        subtitle: count == 0 ? 'Your local photo library' : '$count photos · $sortLabel',
        onRefresh: _refresh,
        onOpenSort: () => showSortSheet(context, ref, _kind),
        selectionCount: _segment == 0 ? 0 : _selected.length,
        allSelected: _segment != 0 &&
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
                ButtonSegment(value: 0, label: Text('Folders')),
                ButtonSegment(value: 1, label: Text('All')),
                ButtonSegment(value: 2, label: Text('Favorites')),
              ],
              selected: {_segment},
              onSelectionChanged: (s) => setState(() {
                _segment = s.first;
                _selected.clear();
              }),
            ),
          ),
        ),
        slivers: _segment == 0 ? _folders() : _photos(favs, assets, settings),
      ),
    );
  }

  List<Widget> _folders() {
    final albums = ref.watch(albumsProvider(_kind));
    return albums.when(
      loading: () => [loadingSliver(label: 'Indexing your folders…')],
      error: (e, _) => [
        emptySliver(
          icon: Icons.error_outline_rounded,
          title: 'Could not load folders',
          message: '$e',
        ),
      ],
      data: (list) {
        if (list.isEmpty) {
          return [
            emptySliver(
              icon: Icons.photo_library_outlined,
              title: 'No photos found',
              message: 'Photos stored on this device will appear here.',
            ),
          ];
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
                onTap: () => Navigator.of(context).push(
                  fadeSlideRoute<void>(AlbumPage(album: list[i].ref)),
                ),
              ),
            ),
          ),
        ];
      },
    );
  }

  List<Widget> _photos(
    Set<String> favs,
    AsyncValue<List<AssetEntity>> assets,
    AppSettings settings,
  ) {
    return assets.when(
      skipLoadingOnReload: true,
      loading: () => [loadingSliver(label: 'Loading photos…')],
      error: (e, _) => [
        emptySliver(
          icon: Icons.error_outline_rounded,
          title: 'Could not load photos',
          message: '$e',
        ),
      ],
      data: (all) {
        final list = _segment == 2 ? all.where((a) => favs.contains(a.id)).toList() : all;
        if (list.isEmpty) {
          return [
            emptySliver(
              icon: _segment == 2
                  ? Icons.favorite_border_rounded
                  : Icons.photo_library_outlined,
              title: _segment == 2 ? 'No favorite photos' : 'No photos found',
              message: _segment == 2
                  ? 'Open a photo and tap the heart to keep it here.'
                  : 'Photos stored on this device will appear here.',
            ),
          ];
        }
        return [
          PhotoGridSliver(
            assets: list,
            favorites: favs,
            columns: settings.gridColumns,
            selectionMode: _selected.isNotEmpty,
            selected: _selected,
            onTap: (i) {
              if (_selected.isNotEmpty) {
                _toggleSelection(list[i]);
              } else {
                _openViewer(list, i);
              }
            },
            onLongPress: (i) => _startSelection(list[i]),
          ),
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
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (info.cover != null)
              AssetThumb(asset: info.cover!, size: 420)
            else
              ColoredBox(color: theme.colorScheme.primary.withAlpha(36)),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xD9000000)],
                ),
              ),
            ),
            Positioned(
              left: 13,
              right: 13,
              bottom: 11,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    info.ref.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${info.count} photos',
                    style: const TextStyle(color: Colors.white70, fontSize: 11.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
