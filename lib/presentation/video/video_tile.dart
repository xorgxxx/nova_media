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
    this.progress = 0,
  });

  final AssetEntity asset;
  final bool isFavorite;
  final double progress; // 0..1
  final VoidCallback onTap;
  final VoidCallback onFavorite;
  final VoidCallback onAddToPlaylist;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: SizedBox(
                width: 128,
                height: 74,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    AssetThumb(asset: asset, size: 360),
                    Positioned(
                      right: 6,
                      bottom: progress > 0 ? 8 : 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(170),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          formatSeconds(asset.duration),
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                    if (progress > 0)
                      Positioned(
                        left: 0,
                        right: 0,
                        bottom: 0,
                        child: LinearProgressIndicator(value: progress, minHeight: 3),
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
                  const SizedBox(height: 4),
                  Text(
                    '${asset.width}×${asset.height} · ${formatDate(asset.createDateTime)}',
                    style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurface.withAlpha(150)),
                  ),
                ],
              ),
            ),
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
      ),
    );
  }
}
