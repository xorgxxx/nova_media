import 'package:flutter/material.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:photo_manager_image_provider/photo_manager_image_provider.dart';

import '../theme/app_theme.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(36, 24, 36, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    cs.primary.withAlpha(46),
                    cs.primary.withAlpha(14),
                  ],
                ),
                border: Border.all(color: cs.primary.withAlpha(40)),
              ),
              child: Icon(icon, size: 38, color: cs.primary),
            ),
            const SizedBox(height: 22),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge,
            ),
            if (message != null) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.45,
                ),
              ),
            ],
            if (actionLabel != null) ...[
              const SizedBox(height: 22),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Standard scaffold for a tab: brand bar, large title, optional header,
/// pull-to-refresh and an optional multi-select top bar.
class SectionPage extends StatelessWidget {
  const SectionPage({
    super.key,
    required this.title,
    required this.slivers,
    this.subtitle,
    this.header,
    this.onRefresh,
    this.onOpenSettings,
    this.onOpenSort,
    this.selectionCount = 0,
    this.allSelected = false,
    this.onExitSelection,
    this.onSelectAll,
    this.onDeleteSelected,
  });

  final String title;
  final String? subtitle;
  final Widget? header;
  final List<Widget> slivers;
  final Future<void> Function()? onRefresh;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onOpenSort;

  final int selectionCount;
  final bool allSelected;
  final VoidCallback? onExitSelection;
  final VoidCallback? onSelectAll;
  final VoidCallback? onDeleteSelected;

  bool get _selecting => selectionCount > 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return RefreshIndicator(
      onRefresh: onRefresh ?? () async {},
      color: cs.primary,
      backgroundColor: cs.surfaceContainerHighest,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (_selecting)
            SliverAppBar(
              pinned: true,
              toolbarHeight: 62,
              backgroundColor: cs.surface,
              surfaceTintColor: Colors.transparent,
              leading: IconButton(
                tooltip: 'Cancel selection',
                icon: const Icon(Icons.close_rounded),
                onPressed: onExitSelection,
              ),
              title: Text(
                '$selectionCount selected',
                style: theme.textTheme.titleMedium,
              ),
              actions: [
                IconButton(
                  tooltip: allSelected ? 'Clear selection' : 'Select all',
                  icon: Icon(
                    allSelected
                        ? Icons.deselect_rounded
                        : Icons.select_all_rounded,
                  ),
                  onPressed: onSelectAll,
                ),
                IconButton(
                  tooltip: 'Delete',
                  icon: const Icon(Icons.delete_outline_rounded),
                  color: cs.error,
                  onPressed: onDeleteSelected,
                ),
                const SizedBox(width: 6),
              ],
            )
          else
            SliverAppBar(
              pinned: true,
              toolbarHeight: 58,
              backgroundColor: cs.surface,
              surfaceTintColor: Colors.transparent,
              titleSpacing: 20,
              title: const _BrandWordmark(),
              actions: [
                if (onOpenSort != null)
                  IconButton(
                    tooltip: 'Sort',
                    icon: const Icon(Icons.swap_vert_rounded),
                    onPressed: onOpenSort,
                  ),
                if (onOpenSettings != null)
                  IconButton(
                    tooltip: 'Settings',
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: onOpenSettings,
                  ),
                const SizedBox(width: 6),
              ],
            ),
          if (!_selecting)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 6, 20, 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.displaySmall?.copyWith(fontSize: 36),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          if (header != null) SliverToBoxAdapter(child: header),
          ...slivers,
          const SliverToBoxAdapter(child: SizedBox(height: 28)),
        ],
      ),
    );
  }
}

class _BrandWordmark extends StatelessWidget {
  const _BrandWordmark();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(7),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFE0525F), Accents.brand, Color(0xFF5A0F19)],
            ),
          ),
          child: const Icon(Icons.water_drop_rounded, size: 13, color: Colors.white),
        ),
        const SizedBox(width: 10),
        Text(
          'AS VAULT',
          style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 2.6,
            color: theme.colorScheme.onSurface.withAlpha(200),
          ),
        ),
      ],
    );
  }
}

Widget loadingSliver({String? label}) => SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(
              width: 30,
              height: 30,
              child: CircularProgressIndicator(strokeWidth: 2.4),
            ),
            if (label != null) ...[
              const SizedBox(height: 16),
              Builder(
                builder: (context) => Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

Widget emptySliver({required IconData icon, required String title, String? message}) {
  return SliverFillRemaining(
    hasScrollBody: false,
    child: EmptyState(icon: icon, title: title, message: message),
  );
}

/// Cached MediaStore thumbnail.
class AssetThumb extends StatelessWidget {
  const AssetThumb({
    super.key,
    required this.asset,
    this.size = 320,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  final AssetEntity asset;
  final int size;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final image = AssetEntityImage(
      asset,
      isOriginal: false,
      thumbnailSize: ThumbnailSize.square(size),
      fit: fit,
      errorBuilder: (context, error, stack) => ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Center(
          child: Icon(
            Icons.broken_image_outlined,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}

/// Selection indicator used by grids and list tiles.
class SelectionBadge extends StatelessWidget {
  const SelectionBadge({super.key, required this.selected, this.size = 24});

  final bool selected;
  final double size;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: selected ? cs.primary : Colors.black.withAlpha(70),
        border: Border.all(
          color: selected ? cs.primary : Colors.white.withAlpha(220),
          width: 1.7,
        ),
      ),
      child: selected
          ? Icon(Icons.check_rounded, size: size * 0.62, color: cs.onPrimary)
          : null,
    );
  }
}

/// Asks for a text value (playlist name).
Future<String?> promptForName(BuildContext context, {required String title, String initial = ''}) {
  return showDialog<String>(
    context: context,
    builder: (ctx) => _NameDialog(title: title, initial: initial),
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.initial});
  final String title;
  final String initial;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller = TextEditingController(text: widget.initial);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _submit() {
    final value = _controller.text.trim();
    if (value.isNotEmpty) Navigator.of(context).pop(value);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _submit(),
        decoration: const InputDecoration(hintText: 'Name'),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
        FilledButton(onPressed: _submit, child: const Text('Save')),
      ],
    );
  }
}
