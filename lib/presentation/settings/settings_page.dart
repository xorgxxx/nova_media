import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../application/providers.dart';
import '../../core/system/device_storage.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/media_kind.dart';
import '../common/sort_sheet.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  StorageSnapshot? _storage;
  PackageInfo? _package;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _loadStorage();
    _loadPackage();
  }

  Future<void> _loadStorage() async {
    final snapshot = await DeviceStorage.read();
    if (mounted) setState(() => _storage = snapshot);
  }

  Future<void> _loadPackage() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted) setState(() => _package = info);
    } catch (_) {
      // Fall back to the build-time constants shown below.
    }
  }

  Future<void> _clearCache() async {
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.of(context);
    var freed = 0;
    try {
      await PhotoManager.clearFileCache();
      PaintingBinding.instance.imageCache
        ..clear()
        ..clearLiveImages();
      freed = await DeviceStorage.clearAppCache();
    } catch (_) {
      // Reported below; the UI simply refreshes its numbers.
    }
    await _loadStorage();
    if (!mounted) return;
    setState(() => _busy = false);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          freed > 0
              ? 'Thumbnail cache cleared · ${formatBytes(freed)} freed'
              : 'Thumbnail cache cleared',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? AppSettings.defaults();

    return SectionTheme(
      accent: Accents.brand,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              toolbarHeight: 58,
              backgroundColor: cs.surface,
              surfaceTintColor: Colors.transparent,
              titleSpacing: 20,
              title: Text('AS VAULT',
                  style: theme.textTheme.labelSmall?.copyWith(letterSpacing: 2.6)),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
                child: Text(
                  'Settings',
                  style: theme.textTheme.displaySmall?.copyWith(fontSize: 36),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: _IdentityCard(
                  version: _package?.version ?? '1.1.0',
                  buildNumber: _package?.buildNumber ?? '2',
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: _SettingsSection(
                label: 'SORTING',
                children: [
                  for (final kind in MediaKind.values)
                    _SettingsRow(
                      icon: _iconFor(kind),
                      title: kind.label,
                      value:
                          '${settings.fieldFor(kind).label} · ${settings.orderFor(kind).label}',
                      onTap: () => showSortSheet(context, ref, kind),
                    ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: _SettingsSection(
                label: 'APPEARANCE',
                children: [
                  _SegmentedRow<AppThemeMode>(
                    icon: Icons.dark_mode_outlined,
                    title: 'Theme',
                    values: AppThemeMode.values,
                    selected: settings.themeMode,
                    label: (mode) => mode.label,
                    onChanged: (mode) =>
                        ref.read(settingsProvider.notifier).setThemeMode(mode),
                  ),
                  _SegmentedRow<int>(
                    icon: Icons.grid_view_rounded,
                    title: 'Photo grid',
                    values: const [2, 3, 4, 5],
                    selected: settings.gridColumns.clamp(2, 5).toInt(),
                    label: (columns) => '$columns',
                    onChanged: (columns) =>
                        ref.read(settingsProvider.notifier).setGridColumns(columns),
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: _SettingsSection(
                label: 'STORAGE',
                children: [
                  _StorageRow(snapshot: _storage),
                  _SettingsRow(
                    icon: Icons.cleaning_services_outlined,
                    title: 'Thumbnail cache',
                    value: _storage == null
                        ? '—'
                        : formatBytes(_storage!.cacheBytes),
                    trailing: _busy
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : null,
                    onTap: _busy ? null : _clearCache,
                  ),
                  _SettingsRow(
                    icon: Icons.refresh_rounded,
                    title: 'Refresh storage info',
                    onTap: _loadStorage,
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: _SettingsSection(
                label: 'ABOUT',
                children: [
                  _SettingsRow(
                    icon: Icons.phone_android_rounded,
                    title: 'Architecture',
                    value: DeviceStorage.architecture,
                  ),
                  _SettingsRow(
                    icon: Icons.inventory_2_outlined,
                    title: 'Package',
                    value: _package?.packageName ?? 'com.novamedia.nova_media',
                  ),
                  const _SettingsRow(
                    icon: Icons.cloud_off_rounded,
                    title: 'Privacy',
                    value: '100% on-device',
                  ),
                ],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 36),
                child: Text(
                  'AS Vault · local media manager\nNothing leaves this device.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(MediaKind kind) {
    switch (kind) {
      case MediaKind.video:
        return Icons.play_circle_outline_rounded;
      case MediaKind.image:
        return Icons.photo_library_outlined;
      case MediaKind.audio:
        return Icons.library_music_outlined;
    }
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.version, required this.buildNumber});

  final String version;
  final String buildNumber;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(cs.primary.withAlpha(40), cs.surface),
            cs.surfaceContainerHighest,
          ],
        ),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              'assets/icon/app_icon.png',
              width: 58,
              height: 58,
              errorBuilder: (context, error, stack) => Container(
                width: 58,
                height: 58,
                color: cs.primaryContainer,
                child: Icon(Icons.water_drop_rounded, color: cs.primary),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('AS Vault', style: theme.textTheme.titleLarge),
                const SizedBox(height: 2),
                Text(
                  'Version $version ($buildNumber) · arm64-v8a',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.label, required this.children});

  final String label;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 10),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                letterSpacing: 1.8,
                fontSize: 10,
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i != children.length - 1)
                    Divider(indent: 54, endIndent: 16, color: cs.outlineVariant),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({
    required this.icon,
    required this.title,
    this.value,
    this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String? value;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 21, color: cs.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(
              child: Text(title, style: theme.textTheme.titleSmall),
            ),
            if (value != null)
              Flexible(
                child: Text(
                  value!,
                  textAlign: TextAlign.end,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: cs.onSurfaceVariant),
                ),
              ),
            if (trailing != null) ...[
              const SizedBox(width: 10),
              trailing!,
            ],
            if (onTap != null) ...[
              const SizedBox(width: 6),
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: cs.onSurfaceVariant.withAlpha(160)),
            ],
          ],
        ),
      ),
    );
  }
}

class _SegmentedRow<T> extends StatelessWidget {
  const _SegmentedRow({
    required this.icon,
    required this.title,
    required this.values,
    required this.selected,
    required this.label,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final List<T> values;
  final T selected;
  final String Function(T value) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 21, color: cs.onSurfaceVariant),
              const SizedBox(width: 14),
              Text(title, style: theme.textTheme.titleSmall),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: SegmentedButton<T>(
              showSelectedIcon: false,
              segments: [
                for (final value in values)
                  ButtonSegment(value: value, label: Text(label(value))),
              ],
              selected: {selected},
              onSelectionChanged: (selection) => onChanged(selection.first),
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageRow extends StatelessWidget {
  const _StorageRow({required this.snapshot});

  final StorageSnapshot? snapshot;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final storage = snapshot;
    final fraction = storage == null || storage.totalBytes <= 0
        ? 0.0
        : (storage.usedBytes / storage.totalBytes).clamp(0.0, 1.0).toDouble();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.sd_storage_outlined,
                  size: 21, color: cs.onSurfaceVariant),
              const SizedBox(width: 14),
              Text('Device storage', style: theme.textTheme.titleSmall),
              const Spacer(),
              Text(
                storage == null
                    ? 'Unavailable'
                    : '${formatBytes(storage.freeBytes)} free',
                style:
                    theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: fraction,
              minHeight: 6,
              backgroundColor: cs.outlineVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            storage == null
                ? 'Storage statistics are provided by Android.'
                : '${formatBytes(storage.usedBytes)} used of ${formatBytes(storage.totalBytes)}',
            style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
