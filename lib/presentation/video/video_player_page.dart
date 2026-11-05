import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../application/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/media_kind.dart';
import '../../data/repositories/user_data_repository.dart';
import '../playlists/playlist_widgets.dart';

/// Full-screen player: speed control, resume, queue (next/previous), double-tap seek,
/// rotate button, favorites and add-to-playlist.
class VideoPlayerPage extends ConsumerStatefulWidget {
  const VideoPlayerPage({super.key, required this.queue, required this.startIndex});

  final List<AssetEntity> queue;
  final int startIndex;

  @override
  ConsumerState<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends ConsumerState<VideoPlayerPage> {
  static const _speeds = [0.25, 0.5, 0.75, 1.0, 1.25, 1.5, 1.75, 2.0];

  VideoPlayerController? _controller;
  late int _index = widget.startIndex;
  late final UserDataRepository _repo;
  Timer? _hideTimer;
  Timer? _saveTimer;
  Timer? _hintTimer;
  bool _controlsVisible = true;
  bool _loading = true;
  bool _completedHandled = false;
  String? _error;
  String? _hint;
  double _speed = 1.0;
  double? _dragMs;
  Orientation? _lastOrientation;

  @override
  void initState() {
    super.initState();
    _repo = ref.read(userDataRepositoryProvider);
    WakelockPlus.enable();
    SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    _saveTimer = Timer.periodic(const Duration(seconds: 5), (_) => _saveProgress());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load(_index);
    });
  }

  @override
  void dispose() {
    _hideTimer?.cancel();
    _saveTimer?.cancel();
    _hintTimer?.cancel();
    _saveProgress(); // reads controller values synchronously before it is disposed
    final c = _controller;
    c?.removeListener(_onTick);
    c?.dispose();
    WakelockPlus.disable();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
  }

  // ---- Loading / persistence -------------------------------------------

  Future<void> _load(int index) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    await _saveProgress();
    final old = _controller;
    _controller = null;
    old?.removeListener(_onTick);
    await old?.dispose();

    final asset = widget.queue[index];
    try {
      final file = await asset.originFile;
      if (file == null) throw Exception('The file is no longer available.');
      final c = VideoPlayerController.file(file);
      await c.initialize();
      await c.setPlaybackSpeed(_speed);
      final saved = await _repo.getProgress(asset.id);
      if (saved != null && saved.isResumable) {
        await c.seekTo(Duration(milliseconds: saved.positionMs));
        _showHint('Resumed at ${formatDuration(Duration(milliseconds: saved.positionMs))}');
      }
      if (!mounted) {
        await c.dispose();
        return;
      }
      _completedHandled = false;
      c.addListener(_onTick);
      setState(() {
        _controller = c;
        _index = index;
        _loading = false;
      });
      await c.play();
      _scheduleHide();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _index = index;
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _saveProgress() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final pos = c.value.position.inMilliseconds;
    final dur = c.value.duration.inMilliseconds;
    if (dur <= 0) return;
    final id = widget.queue[_index].id;
    if (pos >= dur - 3000) {
      await _repo.clearProgress(id);
    } else if (pos > 1000) {
      await _repo.saveProgress(id, pos, dur);
    }
  }

  void _onTick() {
    final c = _controller;
    if (c == null || _completedHandled) return;
    if (c.value.isInitialized && c.value.isCompleted) {
      _completedHandled = true;
      if (_index < widget.queue.length - 1) {
        _load(_index + 1);
      } else if (mounted) {
        setState(() => _controlsVisible = true);
      }
    }
  }

  // ---- Controls ----------------------------------------------------------

  void _scheduleHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (mounted && (_controller?.value.isPlaying ?? false)) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _toggleControls() {
    setState(() => _controlsVisible = !_controlsVisible);
    if (_controlsVisible) _scheduleHide();
  }

  void _showHint(String text) {
    _hintTimer?.cancel();
    if (mounted) setState(() => _hint = text);
    _hintTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) setState(() => _hint = null);
    });
  }

  void _seekBy(int seconds) {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    final dur = c.value.duration;
    var target = c.value.position + Duration(seconds: seconds);
    if (target < Duration.zero) target = Duration.zero;
    if (target > dur) target = dur;
    c.seekTo(target);
    _showHint(seconds > 0 ? '+${seconds}s' : '${seconds}s');
  }

  void _togglePlay() {
    final c = _controller;
    if (c == null) return;
    if (c.value.isPlaying) {
      c.pause();
      _hideTimer?.cancel();
    } else {
      if (c.value.isCompleted) c.seekTo(Duration.zero);
      c.play();
      _scheduleHide();
    }
  }

  void _setSpeed(double speed) {
    setState(() => _speed = speed);
    _controller?.setPlaybackSpeed(speed);
  }

  void _toggleOrientation() {
    final landscape = MediaQuery.orientationOf(context) == Orientation.landscape;
    SystemChrome.setPreferredOrientations(
      landscape
          ? [DeviceOrientation.portraitUp]
          : [DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight],
    );
    // Re-enable auto-rotate shortly after, so the sensor keeps working.
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) SystemChrome.setPreferredOrientations(DeviceOrientation.values);
    });
  }

  void _syncSystemUi(Orientation orientation) {
    if (_lastOrientation == orientation) return;
    _lastOrientation = orientation;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemChrome.setEnabledSystemUIMode(
        orientation == Orientation.landscape ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge,
      );
    });
  }

  void _openSpeedSheet() {
    _hideTimer?.cancel();
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => SafeArea(
        child: ListView(
          shrinkWrap: true,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Text('Playback speed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
            for (final s in _speeds)
              ListTile(
                title: Text(s == 1.0 ? 'Normal' : '${s}x'),
                trailing: s == _speed ? const Icon(Icons.check_rounded) : null,
                onTap: () {
                  _setSpeed(s);
                  Navigator.pop(ctx);
                },
              ),
          ],
        ),
      ),
    ).whenComplete(_scheduleHide);
  }

  // ---- UI ----------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final asset = widget.queue[_index];
    return SectionTheme(
      accent: Accents.video,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: OrientationBuilder(
          builder: (context, orientation) {
            _syncSystemUi(orientation);
            return Stack(
              fit: StackFit.expand,
              children: [
                Center(child: _buildVideo()),
                _buildGestureLayer(),
                if (_loading) const Center(child: CircularProgressIndicator()),
                if (_error != null) _buildError(),
                if (_hint != null)
                  Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(160),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(_hint!, style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ),
                  ),
                AnimatedOpacity(
                  opacity: _controlsVisible ? 1 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: IgnorePointer(ignoring: !_controlsVisible, child: _buildControls(asset)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildVideo() {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return const SizedBox.shrink();
    return AspectRatio(aspectRatio: c.value.aspectRatio, child: VideoPlayer(c));
  }

  Widget _buildGestureLayer() {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleControls,
            onDoubleTap: () => _seekBy(-10),
          ),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggleControls,
            onDoubleTap: () => _seekBy(10),
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.white70, size: 48),
            const SizedBox(height: 12),
            Text(
              'This video cannot be played.\n$_error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            if (_index < widget.queue.length - 1)
              FilledButton(onPressed: () => _load(_index + 1), child: const Text('Next video')),
          ],
        ),
      ),
    );
  }

  Widget _buildControls(AssetEntity asset) {
    final favs = ref.watch(favoritesProvider(MediaKind.video)).valueOrNull ?? const <String>{};
    final isFav = favs.contains(asset.id);
    final c = _controller;
    final hasPrev = _index > 0;
    final hasNext = _index < widget.queue.length - 1;

    return Stack(
      fit: StackFit.expand,
      children: [
        IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.black.withAlpha(190), Colors.transparent, Colors.transparent, Colors.black.withAlpha(200)],
                stops: const [0, 0.25, 0.7, 1],
              ),
            ),
          ),
        ),
        // Top bar
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
                    cleanTitle(asset.title),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  color: isFav ? Accents.video : Colors.white,
                  icon: Icon(isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded),
                  onPressed: () => ref.read(favoritesProvider(MediaKind.video).notifier).toggle(asset.id),
                ),
                IconButton(
                  color: Colors.white,
                  icon: const Icon(Icons.playlist_add_rounded),
                  onPressed: () => showAddToPlaylistSheet(context, MediaKind.video, asset.id),
                ),
                IconButton(
                  color: Colors.white,
                  icon: const Icon(Icons.screen_rotation_rounded),
                  onPressed: _toggleOrientation,
                ),
              ],
            ),
          ),
        ),
        // Centre transport
        Center(
          child: c == null
              ? const SizedBox.shrink()
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      iconSize: 36,
                      color: Colors.white,
                      icon: const Icon(Icons.skip_previous_rounded),
                      onPressed: hasPrev ? () => _load(_index - 1) : null,
                    ),
                    IconButton(
                      iconSize: 36,
                      color: Colors.white,
                      icon: const Icon(Icons.replay_10_rounded),
                      onPressed: () => _seekBy(-10),
                    ),
                    ValueListenableBuilder<VideoPlayerValue>(
                      valueListenable: c,
                      builder: (context, value, _) => IconButton.filled(
                        iconSize: 44,
                        icon: Icon(value.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                        onPressed: _togglePlay,
                      ),
                    ),
                    IconButton(
                      iconSize: 36,
                      color: Colors.white,
                      icon: const Icon(Icons.forward_10_rounded),
                      onPressed: () => _seekBy(10),
                    ),
                    IconButton(
                      iconSize: 36,
                      color: Colors.white,
                      icon: const Icon(Icons.skip_next_rounded),
                      onPressed: hasNext ? () => _load(_index + 1) : null,
                    ),
                  ],
                ),
        ),
        // Bottom bar
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: SafeArea(
            top: false,
            child: c == null
                ? const SizedBox(height: 56)
                : Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ValueListenableBuilder<VideoPlayerValue>(
                          valueListenable: c,
                          builder: (context, value, _) {
                            final maxMs = value.duration.inMilliseconds.toDouble();
                            final posMs = value.position.inMilliseconds.toDouble();
                            final shown = (_dragMs ?? posMs).clamp(0.0, maxMs > 0 ? maxMs : 1.0).toDouble();
                            return Row(
                              children: [
                                Text(formatDuration(Duration(milliseconds: shown.round())),
                                    style: const TextStyle(color: Colors.white)),
                                Expanded(
                                  child: Slider(
                                    value: shown,
                                    min: 0,
                                    max: maxMs > 0 ? maxMs : 1.0,
                                    onChanged: (v) {
                                      setState(() => _dragMs = v);
                                      _hideTimer?.cancel();
                                    },
                                    onChangeEnd: (v) {
                                      c.seekTo(Duration(milliseconds: v.round()));
                                      setState(() => _dragMs = null);
                                      _scheduleHide();
                                    },
                                  ),
                                ),
                                Text(formatDuration(value.duration),
                                    style: const TextStyle(color: Colors.white)),
                              ],
                            );
                          },
                        ),
                        Row(
                          children: [
                            TextButton.icon(
                              style: TextButton.styleFrom(foregroundColor: Colors.white),
                              onPressed: _openSpeedSheet,
                              icon: const Icon(Icons.speed_rounded),
                              label: Text('${_speed}x'),
                            ),
                            const Spacer(),
                            if (widget.queue.length > 1)
                              Text('${_index + 1} / ${widget.queue.length}',
                                  style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ],
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}
