import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/utils/format.dart';

class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.asset,
    required this.isFavorite,
    required this.isCurrent,
    required this.onTap,
    required this.onFavorite,
    required this.onAddToPlaylist,
  });

  final AssetEntity asset;
  final bool isFavorite;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onAddToPlaylist;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return ListTile(
      onTap: onTap,
      leading: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isCurrent
                ? [cs.primary, cs.primary.withAlpha(150)]
                : [cs.primary.withAlpha(60), cs.primary.withAlpha(25)],
          ),
        ),
        child: Icon(
          isCurrent ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
          color: isCurrent ? cs.onPrimary : cs.primary,
        ),
      ),
      title: Text(
        cleanTitle(asset.title),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.titleSmall?.copyWith(color: isCurrent ? cs.primary : null),
      ),
      subtitle: Text(formatSeconds(asset.duration)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: onFavorite,
            icon: Icon(
              isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
              color: isFavorite ? cs.primary : null,
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'playlist') onAddToPlaylist();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'playlist', child: Text('Add to playlist')),
            ],
          ),
        ],
      ),
    );
  }
}
