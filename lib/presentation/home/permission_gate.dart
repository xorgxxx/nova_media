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
    final cs = theme.colorScheme;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.alphaBlend(cs.primary.withAlpha(38), cs.surface),
              cs.surface,
              cs.surface,
            ],
            stops: const [0, 0.45, 1],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(flex: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(26),
                  child: Image.asset(
                    'assets/icon/app_icon.png',
                    width: 92,
                    height: 92,
                    errorBuilder: (context, error, stack) => Container(
                      width: 92,
                      height: 92,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Accents.brand, Color(0xFF4A0B13)],
                        ),
                      ),
                      child: const Icon(Icons.water_drop_rounded,
                          color: Colors.white, size: 40),
                    ),
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'AS VAULT',
                  style: theme.textTheme.labelSmall?.copyWith(
                    letterSpacing: 3.2,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your private\nmedia vault.',
                  style: theme.textTheme.displaySmall?.copyWith(fontSize: 42),
                ),
                const SizedBox(height: 16),
                Text(
                  'Videos, photos and music — beautifully organised, entirely on this device. '
                  'Grant access so AS Vault can find your files. Nothing is uploaded, ever.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.55,
                  ),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => ref.read(permissionProvider.notifier).request(),
                    child: const Text('Allow access'),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => ref.read(libraryRepositoryProvider).openSettings(),
                    child: const Text('Open app settings'),
                  ),
                ),
                const SizedBox(height: 16),
                Center(
                  child: Text(
                    'Android 13+ asks only for Photos, Videos and Audio access.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
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
