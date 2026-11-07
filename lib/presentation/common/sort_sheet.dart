import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/theme/app_theme.dart';
import '../../data/models/app_settings.dart';
import '../../data/models/media_kind.dart';

Future<void> showSortSheet(
  BuildContext context,
  WidgetRef ref,
  MediaKind kind,
) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _SortSheet(kind: kind),
  );
}

class _SortSheet extends ConsumerWidget {
  const _SortSheet({required this.kind});

  final MediaKind kind;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final settings =
        ref.watch(settingsProvider).valueOrNull ?? AppSettings.defaults();
    final field = settings.fieldFor(kind);
    final order = settings.orderFor(kind);
    final accent = switch (kind) {
      MediaKind.video => Accents.video,
      MediaKind.image => Accents.photo,
      MediaKind.audio => Accents.music,
    };

    void apply({SortField? by, SortOrder? direction}) {
      ref.read(settingsProvider.notifier).setSort(
            kind,
            by ?? field,
            direction ?? order,
          );
    }

    return SectionTheme(
      accent: accent,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sort ${kind.label}', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'Your choice is remembered for this section.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
              const SizedBox(height: 24),
              const _SectionLabel('SORT BY'),
              const SizedBox(height: 10),
              _OptionsCard(
                children: [
                  for (final option in SortField.values)
                    if (option.supports(kind))
                      _ChoiceRow(
                        icon: _iconFor(option),
                        label: option.label,
                        selected: option == field,
                        onTap: () => apply(by: option),
                      ),
                ],
              ),
              const SizedBox(height: 22),
              const _SectionLabel('SORT ORDER'),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final option in SortOrder.values) ...[
                    Expanded(
                      child: _OrderCard(
                        label: option.label,
                        hint: option.hint(field),
                        selected: option == order,
                        onTap: () => apply(direction: option),
                      ),
                    ),
                    if (option != SortOrder.values.last)
                      const SizedBox(width: 10),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconFor(SortField field) {
    switch (field) {
      case SortField.name:
        return Icons.sort_by_alpha_rounded;
      case SortField.size:
        return Icons.data_usage_rounded;
      case SortField.date:
        return Icons.schedule_rounded;
      case SortField.duration:
        return Icons.timer_outlined;
    }
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            letterSpacing: 1.8,
            fontSize: 10,
          ),
    );
  }
}

class _OptionsCard extends StatelessWidget {
  const _OptionsCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: cs.outlineVariant),
      ),
      child: Column(children: children),
    );
  }
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(icon, size: 20,
                color: selected ? cs.primary : cs.onSurfaceVariant),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.titleSmall?.copyWith(
                  color: selected ? cs.primary : cs.onSurface,
                ),
              ),
            ),
            AnimatedOpacity(
              duration: const Duration(milliseconds: 140),
              opacity: selected ? 1 : 0,
              child: Icon(Icons.check_rounded, size: 20, color: cs.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.label,
    required this.hint,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String hint;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected
              ? Color.alphaBlend(cs.primary.withAlpha(34), cs.surface)
              : cs.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? cs.primary : cs.outlineVariant,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              label == 'Ascending'
                  ? Icons.arrow_upward_rounded
                  : Icons.arrow_downward_rounded,
              size: 20,
              color: selected ? cs.primary : cs.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: theme.textTheme.titleSmall?.copyWith(
                color: selected ? cs.primary : cs.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              hint,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
