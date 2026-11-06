import 'package:photo_manager/photo_manager.dart';

import '../../core/utils/media_sort.dart';
import '../models/app_settings.dart';
import '../models/media_kind.dart';
import '../repositories/user_data_repository.dart';

/// Applies the persisted sort options to a list of MediaStore assets.
///
/// Byte sizes are resolved through [UserDataRepository.cachedAssetSizes] so a
/// library of thousands of files only pays the MediaStore query once; later
/// sorts are served entirely from the local cache.
class MediaSortService {
  MediaSortService(this._userData);

  final UserDataRepository _userData;

  /// How many `fileSize` platform calls may run at the same time. Kept modest
  /// so the MediaStore content resolver is not flooded on low-end devices.
  static const _sizeConcurrency = 12;

  Future<List<AssetEntity>> sort(
    List<AssetEntity> assets, {
    required MediaKind kind,
    required SortField field,
    required SortOrder order,
  }) {
    return sortAssets(
      assets,
      kind: kind,
      field: field,
      order: order,
      sizeResolver: _resolveSizes,
    );
  }

  Future<Map<String, int>> _resolveSizes(List<AssetEntity> assets) async {
    if (assets.isEmpty) return const <String, int>{};

    final modified = <String, int>{
      for (final asset in assets)
        asset.id: asset.modifiedDateSecond ?? asset.createDateSecond ?? 0,
    };

    final sizes = <String, int>{};
    try {
      sizes.addAll(await _userData.cachedAssetSizes(modified));
    } catch (_) {
      // A cache failure must never break sorting; fetch everything instead.
    }

    final missing = [
      for (final asset in assets)
        if (!sizes.containsKey(asset.id)) asset,
    ];
    if (missing.isEmpty) return sizes;

    final fetched = <String, ({int size, int modifiedAt})>{};
    for (var start = 0; start < missing.length; start += _sizeConcurrency) {
      final end = (start + _sizeConcurrency < missing.length)
          ? start + _sizeConcurrency
          : missing.length;
      final chunk = missing.sublist(start, end);
      final results = await Future.wait(
        chunk.map((asset) async {
          try {
            return MapEntry(asset.id, await asset.fileSize);
          } catch (_) {
            return MapEntry(asset.id, 0);
          }
        }),
      );
      for (final entry in results) {
        sizes[entry.key] = entry.value;
        fetched[entry.key] = (
          size: entry.value,
          modifiedAt: modified[entry.key] ?? 0,
        );
      }
    }

    if (fetched.isNotEmpty) {
      try {
        await _userData.saveAssetSizes(fetched);
      } catch (_) {
        // Non-fatal: sorting already has the values in memory.
      }
    }
    return sizes;
  }
}
