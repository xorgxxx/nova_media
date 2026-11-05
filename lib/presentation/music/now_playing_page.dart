import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../application/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/format.dart';
import '../../data/models/media_kind.dart';
import '../playlists/playlist_widgets.dart';

class NowPlayingPage extends ConsumerWidget {
  const NowPlayingPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(currentMediaItemProvider).valueOrNull;
    final state = ref.watch(playerStateProvider).valueOrNull;
    final favs = ref.watch(favoritesProvider(MediaKind.audio)).valueOrNull ?? const <String>{};
    final audio = ref.read(audioControllerProvider);
    final player = audio.player;

    return SectionTheme(
      accent: Accents.music,
      child: Builder(builder: (context) {
        final cs = Theme.of(context).colorScheme;
        final theme = Theme.of(context);
        final playing = state?.playing ?? false;
        final busy = state?.processingState == ProcessingState.loading ||
            state?.processingState == ProcessingState.buffering;
        final isFav = item != null && favs.contains(item.id);

        return Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [cs.primary.withAlpha(110), cs.surface, cs.surface],
                stops: const [0, 0.55, 1],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 32),
                        ),
                        const Spacer(),
                        Text('Now playing', style: theme.textTheme.labelLarge),
                        const Spacer(),
                        IconButton(
                          onPressed: item == null
                              ? null
                              : () => showAddToPlaylistSheet(context, MediaKind.audio, item.id),
                          icon: const Icon(Icons.playlist_add_rounded),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Hero(
                      tag: 'now-playing-art',
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(32),
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [cs.primary, cs.primary.withAlpha(90)],
                            ),
                            boxShadow: [
                              BoxShadow(color: cs.primary.withAlpha(90), blurRadius: 40, offset: const Offset(0, 20)),
                            ],
                          ),
                          child: Icon(Icons.music_note_rounded, size: 110, color: cs.onPrimary.withAlpha(220)),
                        ),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item?.title ?? '—',
                                  maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.headlineSmall),
                              const SizedBox(height: 4),
                              Text(item?.artist ?? item?.album ?? '',
                                  maxLines: 1, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodyMedium),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: item == null
                              ? null
                              : () => ref.read(favoritesProvider(MediaKind.audio).notifier).toggle(item.id),
                          icon: Icon(
                            isFav ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                            color: isFav ? cs.primary : null,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _SeekBar(player: player),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        StreamBuilder<bool>(
                          stream: player.shuffleModeEnabledStream,
                          initialData: player.shuffleModeEnabled,
                          builder: (context, snap) => IconButton(
                            onPressed: audio.toggleShuffle,
                            icon: Icon(Icons.shuffle_rounded, color: (snap.data ?? false) ? cs.primary : null),
                          ),
                        ),
                        IconButton(
                          iconSize: 40,
                          onPressed: audio.previous,
                          icon: const Icon(Icons.skip_previous_rounded),
                        ),
                        busy
                            ? const SizedBox(
                                width: 72,
                                height: 72,
                                child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()),
                              )
                            : IconButton.filled(
                                iconSize: 44,
                                onPressed: audio.togglePlay,
                                icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                              ),
                        IconButton(
                          iconSize: 40,
                          onPressed: audio.next,
                          icon: const Icon(Icons.skip_next_rounded),
                        ),
                        StreamBuilder<LoopMode>(
                          stream: player.loopModeStream,
                          initialData: player.loopMode,
                          builder: (context, snap) {
                            final mode = snap.data ?? LoopMode.off;
                            return IconButton(
                              onPressed: audio.cycleLoopMode,
                              icon: Icon(
                                mode == LoopMode.one ? Icons.repeat_one_rounded : Icons.repeat_rounded,
                                color: mode == LoopMode.off ? null : cs.primary,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _SeekBar extends StatefulWidget {
  const _SeekBar({required this.player});

  final AudioPlayer player;

  @override
  State<_SeekBar> createState() => _SeekBarState();
}

class _SeekBarState extends State<_SeekBar> {
  double? _drag;

  @override
  Widget build(BuildContext context) {
    final player = widget.player;
    return StreamBuilder<Duration?>(
      stream: player.durationStream,
      initialData: player.duration,
      builder: (context, durationSnap) {
        final duration = durationSnap.data ?? Duration.zero;
        final maxMs = duration.inMilliseconds.toDouble();
        return StreamBuilder<Duration>(
          stream: player.positionStream,
          initialData: player.position,
          builder: (context, posSnap) {
            final posMs = (posSnap.data ?? Duration.zero).inMilliseconds.toDouble();
            final shown = (_drag ?? posMs).clamp(0.0, maxMs > 0 ? maxMs : 1.0).toDouble();
            return Column(
              children: [
                Slider(
                  value: shown,
                  min: 0,
                  max: maxMs > 0 ? maxMs : 1.0,
                  onChanged: maxMs > 0 ? (v) => setState(() => _drag = v) : null,
                  onChangeEnd: (v) {
                    player.seek(Duration(milliseconds: v.round()));
                    setState(() => _drag = null);
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(formatDuration(Duration(milliseconds: shown.round()))),
                      Text(formatDuration(duration)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
