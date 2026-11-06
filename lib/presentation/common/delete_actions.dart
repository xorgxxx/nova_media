import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:photo_manager/photo_manager.dart';

import '../../application/providers.dart';
import '../../data/models/album_info.dart';
import '../../data/models/media_kind.dart';

/// Confirms, deletes through the official MediaStore APIs, then removes just
/// the deleted items from the in-memory library (no full MediaStore re-scan).
///
/// Returns the number of items actually deleted (0 when the user cancels the
/// in-app prompt or Android's system confirmation dialog).
Future<int> deleteMediaAssets({
  required BuildContext context,
  required WidgetRef ref,
  required MediaKind kind,
  required Iterable<String> assetIds,
  AlbumRef? album,
}) async {
  final ids = assetIds.toSet().toList(growable: false);
  if (ids.isEmpty) return 0;

  final theme = Theme.of(context);
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      icon: Icon(
        Icons.delete_outline_rounded,
        color: theme.colorScheme.error,
        size: 30,
      ),
      title: Text(ids.length == 1 ? 'Delete this ${kind.singularLabel}?' : 'Delete ${ids.length} items?'),
      content: Text(
        ids.length == 1
            ? 'The file will be removed from this device. Android will ask you to confirm the deletion.'
            : '${ids.length} files will be removed from this device. Android will ask you to confirm the deletion.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: theme.colorScheme.error,
            foregroundColor: theme.colorScheme.onError,
          ),
          onPressed: () => Navigator.pop(ctx, true),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
  if (confirmed != true) return 0;
  if (!context.mounted) return 0;
  final messenger = ScaffoldMessenger.of(context);

  try {
    // photo_manager routes this to MediaStore.createDeleteRequest on Android
    // 11+ (the system confirmation sheet) and to the recoverable-security flow
    // on older versions.
    final deleted = await PhotoManager.editor.deleteWithIds(ids);
    if (deleted.isEmpty) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Deletion cancelled')),
      );
      return 0;
    }

    await ref.read(userDataRepositoryProvider).removeAssets(deleted);
    ref.read(libraryAssetsProvider(kind).notifier).removeIds(deleted);
    ref.invalidate(favoritesProvider(kind));
    ref.invalidate(playlistsProvider(kind));
    ref.invalidate(videoProgressProvider);
    ref.invalidate(albumsProvider(kind));
    if (album != null) ref.invalidate(albumAssetsProvider(album));

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          deleted.length == 1
              ? 'Deleted 1 ${kind.singularLabel}'
              : 'Deleted ${deleted.length} items',
        ),
      ),
    );
    return deleted.length;
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text('Could not delete: $error')),
    );
    return 0;
  }
}
