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
import 'photo_grid.dart';
import 'photo_viewer_page.dart';

class AlbumPage extends ConsumerStatefulWidget {
  const AlbumPage({super.key, required this.album});

  final AlbumRef album;

  @override
  ConsumerState<AlbumPage> createState() => _AlbumPageState();
}

class _AlbumPageState extends ConsumerState<AlbumPage> {
  static const _kind = MediaKind.image;
  final Set<String> _selected = <String>{};

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
      album: widget.album,
    );
    if (deleted > 0 && mounted) _clearSelection();
  }

  Future<void> _refresh() async {
    ref.invalidate(albumAssetsProvider(widget.album));
    ref.invalidate(albumsProvider(_kind));
    await ref.read(libraryAssetsProvider(_kind).notifier).refresh();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final assets = ref.watch(sortedAlbumAssetsProvider(widget.album));
    final favs = ref.watch(favoritesProvider(_kind)).valueOrNull ?? const <String>{};
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? AppSettings.defaults();
    final list = assets.valueOrNull ?? const <AssetEntity>[];
    final selecting = _selected.isNotEmpty;

    return SectionTheme(
      accent: Accents.photo,
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: _refresh,
          color: cs.primary,
          backgroundColor: cs.surfaceContainerHighest,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              if (selecting)
                SliverAppBar(
                  pinned: true,
                  toolbarHeight: 62,
                  backgroundColor: cs.surface,
                  surfaceTintColor: Colors.transparent,
                  leading: IconButton(
                    tooltip: 'Cancel selection',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _clearSelection,
                  ),
                  title: Text(
                    '${_selected.length} selected',
                    style: theme.textTheme.titleMedium,
                  ),
                  actions: [
                    IconButton(
                      tooltip:
                          _selected.length == list.length ? 'Clear selection' : 'Select all',
                      icon: Icon(
                        _selected.length == list.length
                            ? Icons.deselect_rounded
                            : Icons.select_all_rounded,
                      ),
                      onPressed: () => _selectAll(list),
                    ),
                    IconButton(
                      tooltip: 'Delete',
                      icon: const Icon(Icons.delete_outline_rounded),
                      color: cs.error,
                      onPressed: () => _deleteSelected(),
                    ),
                    const SizedBox(width: 6),
                  ],
                )
              else
                SliverAppBar(
                  pinned: true,
                  toolbarHeight: 58,
                  backgroundColor: cs.surface,
                  surfaceTintColor: Colors.transparent,
                  titleSpacing: 0,
                  title: Text(
                    widget.album.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  actions: [
                    IconButton(
                      tooltip: 'Sort',
                      icon: const Icon(Icons.swap_vert_rounded),
                      onPressed: () => showSortSheet(context, ref, _kind),
                    ),
                    const SizedBox(width: 6),
                  ],
                ),
              if (!selecting)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
                    child: Text(
                      list.isEmpty
                          ? 'Folder'
                          : '${list.length} photos · '
                              '${settings.fieldFor(_kind).label} · '
                              '${settings.orderFor(_kind).label}',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ),
                ),
              ...assets.when(
                loading: () => [loadingSliver(label: 'Loading folder…')],
                error: (e, _) => [
                  emptySliver(
                    icon: Icons.error_outline_rounded,
                    title: 'Could not load folder',
                    message: '$e',
                  ),
                ],
                data: (items) => items.isEmpty
                    ? [
                        emptySliver(
                          icon: Icons.photo_outlined,
                          title: 'This folder is empty',
                          message: 'Photos in this folder will appear here.',
                        ),
                      ]
                    : [
                        PhotoGridSliver(
                          assets: items,
                          favorites: favs,
                          columns: settings.gridColumns,
                          selectionMode: selecting,
                          selected: _selected,
                          onTap: (i) {
                            if (selecting) {
                              _toggleSelection(items[i]);
                            } else {
                              Navigator.of(context).push(
                                fadeRoute<void>(
                                  PhotoViewerPage(
                                    assets: items,
                                    initialIndex: i,
                                    album: widget.album,
                                  ),
                                ),
                              );
                            }
                          },
                          onLongPress: (i) => _startSelection(items[i]),
                        ),
                      ],
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          ),
        ),
      ),
    );
  }
}
