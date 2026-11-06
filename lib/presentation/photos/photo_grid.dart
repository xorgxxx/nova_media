import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/widgets/common_widgets.dart';

/// Sliver grid of square photo thumbnails with a Hero tag, favorite badge and
/// optional multi-select overlay.
class PhotoGridSliver extends StatelessWidget {
  const PhotoGridSliver({
    super.key,
    required this.assets,
    required this.favorites,
    required this.onTap,
    this.columns = 3,
    this.selectionMode = false,
    this.selected = const <String>{},
    this.onLongPress,
  });

  final List<AssetEntity> assets;
  final Set<String> favorites;
  final void Function(int index) onTap;
  final int columns;
  final bool selectionMode;
  final Set<String> selected;
  final void Function(int index)? onLongPress;

  @override
  Widget build(BuildContext context) {
    final thumbSize = columns <= 2 ? 460 : (columns == 3 ? 320 : 240);
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      sliver: SliverGrid.builder(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columns,
          mainAxisSpacing: 3,
          crossAxisSpacing: 3,
        ),
        itemCount: assets.length,
        itemBuilder: (context, i) {
          final asset = assets[i];
          final isSelected = selected.contains(asset.id);
          final tile = Stack(
            fit: StackFit.expand,
            children: [
              if (selectionMode)
                AssetThumb(asset: asset, size: thumbSize)
              else
                Hero(
                  tag: 'photo-${asset.id}',
                  child: AssetThumb(asset: asset, size: thumbSize),
                ),
              if (isSelected)
                ColoredBox(
                  color: Theme.of(context).colorScheme.primary.withAlpha(70),
                ),
              if (favorites.contains(asset.id) && !selectionMode)
                Positioned(
                  right: 5,
                  bottom: 5,
                  child: Icon(
                    Icons.favorite_rounded,
                    size: 15,
                    color: Colors.white.withAlpha(230),
                    shadows: const [Shadow(color: Colors.black45, blurRadius: 4)],
                  ),
                ),
              if (selectionMode)
                Positioned(
                  right: 6,
                  top: 6,
                  child: SelectionBadge(selected: isSelected, size: 21),
                ),
            ],
          );

          return RepaintBoundary(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: GestureDetector(
                onTap: () => onTap(i),
                onLongPress: onLongPress == null ? null : () => onLongPress!(i),
                child: tile,
              ),
            ),
          );
        },
      ),
    );
  }
}
