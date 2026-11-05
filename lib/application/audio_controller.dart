import 'dart:async';

import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart' show MediaItem;
import 'package:photo_manager/photo_manager.dart';

import '../core/utils/format.dart';

/// Wraps [AudioPlayer]. Because just_audio_background is initialised in main(),
/// every source tagged with a [MediaItem] gets a notification, lock-screen
/// controls and background playback automatically.
class AudioController {
  AudioController() : player = AudioPlayer();

  final AudioPlayer player;

  /// Replaces the queue with [queue] and starts at [startIndex].
  /// [shuffle]: null keeps the current shuffle mode.
  Future<void> playQueue(List<AssetEntity> queue, int startIndex, {bool? shuffle}) async {
    if (queue.isEmpty) return;
    final files = await Future.wait(queue.map((a) => a.originFile));
    final sources = <AudioSource>[];
    var initial = 0;
    for (var i = 0; i < queue.length; i++) {
      final file = files[i];
      if (file == null) continue;
      if (i == startIndex) initial = sources.length;
      final asset = queue[i];
      sources.add(AudioSource.uri(
        Uri.file(file.path),
        tag: MediaItem(
          id: asset.id,
          title: cleanTitle(asset.title),
          album: _folderName(asset),
          artist: _folderName(asset) ?? 'Nova Media',
          duration: Duration(seconds: asset.duration),
        ),
      ));
    }
    if (sources.isEmpty) return;
    if (shuffle != null) await player.setShuffleModeEnabled(shuffle);
    await player.setAudioSource(
      ConcatenatingAudioSource(children: sources),
      initialIndex: initial,
      initialPosition: Duration.zero,
    );
    if (shuffle == true) await player.shuffle();
    unawaited(player.play());
  }

  String? _folderName(AssetEntity asset) {
    final rel = asset.relativePath;
    if (rel == null || rel.isEmpty) return null;
    final parts = rel.split('/').where((s) => s.isNotEmpty).toList();
    return parts.isEmpty ? null : parts.last;
  }

  Future<void> togglePlay() async {
    if (player.playing) {
      await player.pause();
      return;
    }
    if (player.processingState == ProcessingState.completed) {
      await player.seek(Duration.zero, index: 0);
    }
    unawaited(player.play());
  }

  Future<void> next() => player.seekToNext();
  Future<void> previous() => player.seekToPrevious();
  Future<void> seek(Duration position) => player.seek(position);

  Future<void> toggleShuffle() async {
    final enable = !player.shuffleModeEnabled;
    if (enable) await player.shuffle();
    await player.setShuffleModeEnabled(enable);
  }

  Future<void> cycleLoopMode() {
    switch (player.loopMode) {
      case LoopMode.off:
        return player.setLoopMode(LoopMode.all);
      case LoopMode.all:
        return player.setLoopMode(LoopMode.one);
      case LoopMode.one:
        return player.setLoopMode(LoopMode.off);
    }
  }

  Future<void> dispose() => player.dispose();
}
