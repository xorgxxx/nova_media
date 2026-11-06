import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/utils/format.dart';
import '../../core/widgets/common_widgets.dart';

class TrackTile extends StatelessWidget {
  const TrackTile({
    super.key,
    required this.asset,
    required this.isFavorite,
    required this.isCurrent,
    required this.onTap,
    required this.onFavorite,
    required this.onAddToPlaylist,
    required this.onDelete,
    this.selectionMode = false,
    this.selected = false,
    this.onLongPress,
  });

  final AssetEntity asset;
  final bool isFavorite;
  final bool isCurrent;
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onAddToPlaylist;
  final VoidCallback onDelete;
  final bool selectionMode;
  final bool selected;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final highlight = isCurrent && !selectionMode;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: selected
            ? Color.alphaBlend(cs.primary.withAlpha(30), cs.surface)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: highlight
                          ? [cs.primary, cs.primary.withAlpha(150)]
                          : [
                              cs.primary.withAlpha(56),
                              cs.primary.withAlpha(20),
                            ],
                    ),
                  ),
                  child: Icon(
                    highlight ? Icons.graphic_eq_rounded : Icons.music_note_rounded,
                    size: 21,
                    color: highlight ? cs.onPrimary : cs.primary,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cleanTitle(asset.title),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: highlight ? cs.primary : null,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatSeconds(asset.duration),
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (selectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: SelectionBadge(selected: selected, size: 22),
                  )
                else ...[
                  IconButton(
                    onPressed: onFavorite,
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 21,
                      color: isFavorite ? cs.primary : cs.onSurfaceVariant,
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'playlist') onAddToPlaylist();
                      if (value == 'delete') onDelete();
                    },
                    icon: Icon(Icons.more_vert_rounded,
                        size: 21, color: cs.onSurfaceVariant),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'playlist',
                        child: Text('Add to playlist'),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
