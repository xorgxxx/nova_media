import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../application/providers.dart';
import '../../core/widgets/routes.dart';
import 'video_player_page.dart';

/// Opens the player and refreshes resume points when it closes.
Future<void> openVideoPlayer(BuildContext context, List<AssetEntity> queue, int index) async {
  final container = ProviderScope.containerOf(context);
  await Navigator.of(context).push(
    fadeSlideRoute<void>(VideoPlayerPage(queue: queue, startIndex: index)),
  );
  container.invalidate(videoProgressProvider);
}
