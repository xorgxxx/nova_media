import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../music/mini_player.dart';
import '../music/music_tab.dart';
import '../photos/photos_tab.dart';
import '../video/video_tab.dart';
import 'permission_gate.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  static const _accents = [Accents.video, Accents.photo, Accents.music];
  int _index = 0;

  Widget _tab(int i) {
    switch (i) {
      case 0:
        return const VideoTab();
      case 1:
        return const PhotosTab();
      default:
        return const MusicTab();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PermissionGate(
      child: Scaffold(
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
          child: KeyedSubtree(key: ValueKey(_index), child: _tab(_index)),
        ),
        bottomNavigationBar: SectionTheme(
          accent: _accents[_index],
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const MiniPlayer(),
              NavigationBar(
                selectedIndex: _index,
                onDestinationSelected: (i) => setState(() => _index = i),
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.play_circle_outline_rounded),
                    selectedIcon: Icon(Icons.play_circle_rounded),
                    label: 'Videos',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.photo_library_outlined),
                    selectedIcon: Icon(Icons.photo_library_rounded),
                    label: 'Photos',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.library_music_outlined),
                    selectedIcon: Icon(Icons.library_music_rounded),
                    label: 'Music',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
