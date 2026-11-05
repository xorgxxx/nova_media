import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../application/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/routes.dart';
import 'now_playing_page.dart';

/// Compact player shown above the navigation bar while a track is loaded.
class MiniPlayer extends ConsumerWidget {
  const MiniPlayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(currentMediaItemProvider).valueOrNull;
    final state = ref.watch(playerStateProvider).valueOrNull;
    final audio = ref.read(audioControllerProvider);

    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOutCubic,
      child: item == null
          ? const SizedBox(width: double.infinity)
          : SectionTheme(
              accent: Accents.music,
              child: Builder(builder: (context) {
                final cs = Theme.of(context).colorScheme;
                final playing = state?.playing ?? false;
                final loading = state?.processingState == ProcessingState.loading ||
                    state?.processingState == ProcessingState.buffering;
                return Material(
                  color: Color.alphaBlend(cs.primary.withAlpha(40), cs.surface),
                  child: InkWell(
                    onTap: () => Navigator.of(context).push(slideUpRoute<void>(const NowPlayingPage())),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: Row(
                        children: [
                          Hero(
                            tag: 'now-playing-art',
                            child: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(colors: [cs.primary, cs.primary.withAlpha(120)]),
                              ),
                              child: Icon(Icons.music_note_rounded, color: cs.onPrimary),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis,
                                    style: Theme.of(context).textTheme.titleSmall),
                                if (item.artist != null)
                                  Text(item.artist!, maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: Theme.of(context).textTheme.bodySmall),
                              ],
                            ),
                          ),
                          if (loading)
                            const Padding(
                              padding: EdgeInsets.all(12),
                              child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5)),
                            )
                          else
                            IconButton(
                              onPressed: audio.togglePlay,
                              icon: Icon(playing ? Icons.pause_rounded : Icons.play_arrow_rounded),
                            ),
                          IconButton(
                            onPressed: audio.next,
                            icon: const Icon(Icons.skip_next_rounded),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
    );
  }
}
