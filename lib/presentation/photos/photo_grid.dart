import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../core/widgets/common_widgets.dart';

/// Sliver grid of square photo thumbnails with a Hero tag and favorite badge.
class PhotoGridSliver extends StatelessWidget {
  const PhotoGridSliver({
    super.key,
    required this.assets,
    required this.favorites,
    required this.onTap,
  });

  final List<AssetEntity> assets;
  final Set<String> favorites;
  final void Function(int index) onTap;

  @override
  Widget build(BuildContext context) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      sliver: SliverGrid.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 2,
          crossAxisSpacing: 2,
        ),
        itemCount: assets.length,
        itemBuilder: (context, i) {
          final a = assets[i];
          return GestureDetector(
            onTap: () => onTap(i),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Hero(tag: 'photo-${a.id}', child: AssetThumb(asset: a, size: 320)),
                if (favorites.contains(a.id))
                  const Positioned(
                    right: 6,
                    bottom: 6,
                    child: Icon(Icons.favorite_rounded, size: 18, color: Colors.white),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
