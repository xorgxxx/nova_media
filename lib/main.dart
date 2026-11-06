import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app.dart';
import 'application/providers.dart';
import 'data/repositories/user_data_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Bounded image cache: big enough to keep a smooth grid, small enough that a
  // large photo library cannot exhaust memory on mid-range phones.
  final imageCache = PaintingBinding.instance.imageCache;
  imageCache.maximumSize = 600;
  imageCache.maximumSizeBytes = 160 << 20; // 160 MB

  // Must run before any AudioPlayer is created.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.novamedia.nova_media.playback',
    androidNotificationChannelName: 'AS Vault playback',
    androidNotificationOngoing: true,
  );

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final userData = await UserDataRepository.open();

  runApp(ProviderScope(
    overrides: [userDataRepositoryProvider.overrideWithValue(userData)],
    child: const AsVaultApp(),
  ));
}
