import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../core/widgets/routes.dart';
import '../../data/models/media_kind.dart';
import '../../data/models/playlist.dart';
import 'playlist_detail_page.dart';

Color accentFor(MediaKind kind) {
  switch (kind) {
    case MediaKind.video:
      return Accents.video;
    case MediaKind.image:
      return Accents.photo;
    case MediaKind.audio:
      return Accents.music;
  }
}

/// Bottom sheet: pick a playlist (or create one) and add [assetId] to it.
Future<void> showAddToPlaylistSheet(
  BuildContext context,
  MediaKind kind,
  String assetId,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => SectionTheme(
      accent: accentFor(kind),
      child: _AddToPlaylistSheet(kind: kind, assetId: assetId),
    ),
  );
}

class _AddToPlaylistSheet extends ConsumerWidget {
  const _AddToPlaylistSheet({required this.kind, required this.assetId});

  final MediaKind kind;
  final String assetId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final playlists = ref.watch(playlistsProvider(kind));
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    Future<void> addTo(Playlist p) async {
      await ref.read(playlistsProvider(kind).notifier).addItem(p.id, assetId);
      navigator.pop();
      messenger.showSnackBar(SnackBar(content: Text('Added to "${p.name}"')));
    }

    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Add to playlist', style: Theme.of(context).textTheme.titleLarge),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add_rounded),
              title: const Text('New playlist'),
              onTap: () async {
                final name = await promptForName(context, title: 'New playlist');
                if (name == null) return;
                final id = await ref.read(playlistsProvider(kind).notifier).create(name);
                await ref.read(playlistsProvider(kind).notifier).addItem(id, assetId);
                navigator.pop();
                messenger.showSnackBar(SnackBar(content: Text('Added to "$name"')));
              },
            ),
            Flexible(
              child: playlists.when(
                loading: () => const Padding(
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                ),
                error: (e, _) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Could not load playlists: $e'),
                ),
                data: (list) => ListView(
                  shrinkWrap: true,
                  children: [
                    for (final p in list)
                      ListTile(
                        leading: const Icon(Icons.queue_music_rounded),
                        title: Text(p.name),
                        subtitle: Text('${p.itemCount} items'),
                        onTap: () => addTo(p),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Sliver list of playlists for a kind, with a "New playlist" row.
class PlaylistsSliver extends ConsumerWidget {
  const PlaylistsSliver({super.key, required this.kind});

  final MediaKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(playlistsProvider(kind));
    final cs = Theme.of(context).colorScheme;
    return async.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(padding: EdgeInsets.all(32), child: Center(child: CircularProgressIndicator())),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: EmptyState(icon: Icons.error_outline, title: 'Could not load playlists', message: '$e'),
      ),
      data: (lists) => SliverList.list(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: cs.primary,
              foregroundColor: cs.onPrimary,
              child: const Icon(Icons.add_rounded),
            ),
            title: const Text('New playlist'),
            onTap: () async {
              final name = await promptForName(context, title: 'New playlist');
              if (name != null) {
                await ref.read(playlistsProvider(kind).notifier).create(name);
              }
            },
          ),
          if (lists.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('No playlists yet. Create one, then add items from the ⋮ menu.',
                  textAlign: TextAlign.center),
            ),
          for (final p in lists)
            ListTile(
              leading: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: cs.primary.withAlpha(40),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.queue_music_rounded, color: cs.primary),
              ),
              title: Text(p.name),
              subtitle: Text('${p.itemCount} items'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(fadeSlideRoute(PlaylistDetailPage(playlistId: p.id, kind: kind))),
            ),
        ],
      ),
    );
  }
}
