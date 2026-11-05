import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/routes.dart';
import '../../data/models/album_info.dart';
import '../../data/models/media_kind.dart';
import 'photo_grid.dart';
import 'photo_viewer_page.dart';

class AlbumPage extends ConsumerWidget {
  const AlbumPage({super.key, required this.album});

  final AlbumRef album;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assets = ref.watch(albumAssetsProvider(album));
    final favs = ref.watch(favoritesProvider(MediaKind.image)).valueOrNull ?? const <String>{};

    return SectionTheme(
      accent: Accents.photo,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar.large(title: Text(album.name)),
            ...assets.when(
              loading: () => [loadingSliver()],
              error: (e, _) => [emptySliver(icon: Icons.error_outline, title: 'Could not load folder', message: '$e')],
              data: (list) => list.isEmpty
                  ? [emptySliver(icon: Icons.photo_outlined, title: 'This folder is empty')]
                  : [
                      PhotoGridSliver(
                        assets: list,
                        favorites: favs,
                        onTap: (i) => Navigator.of(context).push(
                          fadeRoute<void>(PhotoViewerPage(assets: list, initialIndex: i)),
                        ),
                      ),
                    ],
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}
