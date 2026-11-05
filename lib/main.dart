import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio_background/just_audio_background.dart';

import 'app.dart';
import 'application/providers.dart';
import 'data/repositories/user_data_repository.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Must run before any AudioPlayer is created.
  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.novamedia.nova_media.playback',
    androidNotificationChannelName: 'Nova Media playback',
    androidNotificationOngoing: true,
  );

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final userData = await UserDataRepository.open();

  runApp(ProviderScope(
    overrides: [userDataRepositoryProvider.overrideWithValue(userData)],
    child: const NovaMediaApp(),
  ));
}
