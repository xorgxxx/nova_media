import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/utils/format.dart';
import '../../core/widgets/common_widgets.dart';

class VideoTile extends StatelessWidget {
  const VideoTile({
    super.key,
    required this.asset,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
    required this.onAddToPlaylist,
    required this.onDelete,
    this.progress = 0,
    this.selectionMode = false,
    this.selected = false,
    this.onLongPress,
  });

  final AssetEntity asset;
  final bool isFavorite;
  final double progress; // 0..1
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
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
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: SizedBox(
                    width: 126,
                    height: 73,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AssetThumb(asset: asset, size: 360),
                        Positioned(
                          right: 6,
                          bottom: progress > 0 ? 8 : 6,
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(165),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              formatSeconds(asset.duration),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                        if (progress > 0)
                          Positioned(
                            left: 0,
                            right: 0,
                            bottom: 0,
                            child: LinearProgressIndicator(value: progress, minHeight: 2.5),
                          ),
                        if (selectionMode)
                          Positioned(
                            left: 6,
                            top: 6,
                            child: SelectionBadge(selected: selected, size: 22),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cleanTitle(asset.title),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 5),
                      Text(
                        '${asset.width}×${asset.height} · ${formatDate(asset.createDateTime)}',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                if (!selectionMode) ...[
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
                ] else
                  const SizedBox(width: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
