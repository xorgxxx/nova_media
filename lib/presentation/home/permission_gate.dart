import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
// Brings the PermissionState extension (hasAccess) into scope.
import 'package:photo_manager/photo_manager.dart';

import '../../application/providers.dart';
import '../../core/theme/app_theme.dart';

/// Shows [child] only once media access has been granted.
class PermissionGate extends ConsumerStatefulWidget {
  const PermissionGate({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<PermissionGate> createState() => _PermissionGateState();
}

class _PermissionGateState extends ConsumerState<PermissionGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      ref.read(permissionProvider.notifier).refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final permission = ref.watch(permissionProvider);
    return permission.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => const _PermissionView(),
      data: (state) => state.hasAccess ? widget.child : const _PermissionView(),
    );
  }
}

class _PermissionView extends ConsumerWidget {
  const _PermissionView();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Accents.video.withAlpha(60),
              theme.colorScheme.surface,
              Accents.music.withAlpha(60),
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.play_circle_fill_rounded, size: 40, color: Accents.video),
                    SizedBox(width: 8),
                    Icon(Icons.photo_library_rounded, size: 40, color: Accents.photo),
                    SizedBox(width: 8),
                    Icon(Icons.library_music_rounded, size: 40, color: Accents.music),
                  ],
                ),
                const SizedBox(height: 24),
                Text('Nova Media', style: theme.textTheme.displaySmall),
                const SizedBox(height: 12),
                Text(
                  'Your videos, photos and music in one place. '
                  'Allow access to your media so Nova can find and play them. '
                  'Nothing leaves your device.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => ref.read(permissionProvider.notifier).request(),
                    child: const Text('Allow access'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => ref.read(libraryRepositoryProvider).openSettings(),
                    child: const Text('Open app settings'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
