import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../../application/providers.dart';
import '../../core/utils/format.dart';
import '../../data/models/album_info.dart';
import '../../data/models/media_kind.dart';
import '../common/delete_actions.dart';

/// Full-screen swipeable viewer: pinch / double-tap zoom, immersive mode,
/// favorites, file info and deletion.
class PhotoViewerPage extends ConsumerStatefulWidget {
  const PhotoViewerPage({
    super.key,
    required this.assets,
    required this.initialIndex,
    this.album,
  });

  final List<AssetEntity> assets;
  final int initialIndex;
  final AlbumRef? album;

  @override
  ConsumerState<PhotoViewerPage> createState() => _PhotoViewerPageState();
}

class _PhotoViewerPageState extends ConsumerState<PhotoViewerPage> {
  late final PageController _pageController = PageController(initialPage: widget.initialIndex);
  late int _index = widget.initialIndex;
  bool _chromeVisible = true;
  bool _zoomed = false;

  @override
  void dispose() {
    _pageController.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  void _toggleChrome() {
    setState(() => _chromeVisible = !_chromeVisible);
    SystemChrome.setEnabledSystemUIMode(
      _chromeVisible ? SystemUiMode.edgeToEdge : SystemUiMode.immersiveSticky,
    );
  }

  void _showInfo(AssetEntity a) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.title ?? 'Photo', style: Theme.of(ctx).textTheme.titleMedium),
              const SizedBox(height: 12),
              Text('Resolution: ${a.width} × ${a.height}'),
              Text('Date: ${formatDate(a.createDateTime)}'),
              if (a.relativePath != null) Text('Folder: ${a.relativePath}'),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteCurrent(AssetEntity asset) async {
    final deleted = await deleteMediaAssets(
      context: context,
      ref: ref,
      kind: MediaKind.image,
      assetIds: [asset.id],
      album: widget.album,
    );
    if (deleted > 0 && mounted) {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.assets[_index];
    final favs = ref.watch(favoritesProvider(MediaKind.image)).valueOrNull ?? const <String>{};
    final isFav = favs.contains(current.id);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          PageView.builder(
            controller: _pageController,
            physics: _zoomed ? const NeverScrollableScrollPhysics() : const ClampingScrollPhysics(),
            itemCount: widget.assets.length,
            onPageChanged: (i) => setState(() {
              _index = i;
              _zoomed = false;
            }),
            itemBuilder: (context, i) => _ZoomablePage(
              key: ValueKey(widget.assets[i].id),
              asset: widget.assets[i],
              onTap: _toggleChrome,
              onZoomChanged: (z) {
                if (z != _zoomed) setState(() => _zoomed = z);
              },
            ),
          ),
          AnimatedOpacity(
            opacity: _chromeVisible ? 1 : 0,
            duration: const Duration(milliseconds: 180),
            child: IgnorePointer(
              ignoring: !_chromeVisible,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black.withAlpha(170), Colors.transparent, Colors.transparent, Colors.black.withAlpha(170)],
                          stops: const [0, 0.2, 0.8, 1],
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      bottom: false,
                      child: Row(
                        children: [
                          IconButton(
                            color: Colors.white,
                            icon: const Icon(Icons.arrow_back_rounded),
                            onPressed: () => Navigator.of(context).maybePop(),
                          ),
                          Expanded(
                            child: Text(
                              '${_index + 1} / ${widget.assets.length}',
                              style: const TextStyle(color: Colors.white, fontSize: 16),
                            ),
                          ),
                          IconButton(
                            color: isFav ? Theme.of(context).colorScheme.primary : Colors.white,
                            icon: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                            onPressed: () => ref.read(favoritesProvider(MediaKind.image).notifier).toggle(current.id),
                          ),
                          IconButton(
                            color: Colors.white,
                            icon: const Icon(Icons.info_outline_rounded),
                            onPressed: () => _showInfo(current),
                          ),
                          IconButton(
                            color: Colors.white,
                            icon: const Icon(Icons.delete_outline_rounded),
                            onPressed: () => _deleteCurrent(current),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 0,
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          cleanTitle(current.title),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ZoomablePage extends StatefulWidget {
  const _ZoomablePage({
    super.key,
    required this.asset,
    required this.onTap,
    required this.onZoomChanged,
  });

  final AssetEntity asset;
  final VoidCallback onTap;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_ZoomablePage> createState() => _ZoomablePageState();
}

class _ZoomablePageState extends State<_ZoomablePage> with SingleTickerProviderStateMixin {
  final TransformationController _transform = TransformationController();
  late final AnimationController _anim =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 220));
  Offset _doubleTapPosition = Offset.zero;

  @override
  void initState() {
    super.initState();
    _transform.addListener(() {
      widget.onZoomChanged(_transform.value.getMaxScaleOnAxis() > 1.02);
    });
  }

  @override
  void dispose() {
    _anim.dispose();
    _transform.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    final current = _transform.value;
    final startScale = current.getMaxScaleOnAxis();
    final startTx = current.entry(0, 3);
    final startTy = current.entry(1, 3);

    double endScale = 1;
    double endTx = 0;
    double endTy = 0;
    if (startScale < 1.02) {
      endScale = 2.5;
      endTx = -_doubleTapPosition.dx * (endScale - 1);
      endTy = -_doubleTapPosition.dy * (endScale - 1);
    }

    final animation = CurvedAnimation(parent: _anim, curve: Curves.easeOutCubic);
    void tick() {
      final t = animation.value;
      final s = lerpDouble(startScale, endScale, t)!;
      _transform.value = Matrix4.identity()
        ..setEntry(0, 0, s)
        ..setEntry(1, 1, s)
        ..setEntry(0, 3, lerpDouble(startTx, endTx, t)!)
        ..setEntry(1, 3, lerpDouble(startTy, endTy, t)!);
    }

    animation.addListener(tick);
    _anim.forward(from: 0).whenComplete(() => animation.removeListener(tick));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onDoubleTapDown: (d) => _doubleTapPosition = d.localPosition,
      onDoubleTap: _onDoubleTap,
      child: InteractiveViewer(
        transformationController: _transform,
        minScale: 1,
        maxScale: 5,
        child: SizedBox.expand(
          child: Hero(
            tag: 'photo-${widget.asset.id}',
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Low-res (already cached by the grid) shown instantly, original on top.
                AssetEntityImage(
                  widget.asset,
                  isOriginal: false,
                  thumbnailSize: const ThumbnailSize.square(320),
                  fit: BoxFit.contain,
                ),
                AssetEntityImage(
                  widget.asset,
                  isOriginal: true,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stack) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
