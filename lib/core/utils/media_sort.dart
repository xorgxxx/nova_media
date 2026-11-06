import 'package:photo_manager/photo_manager.dart';

import '../../data/models/app_settings.dart';
import '../../data/models/media_kind.dart';
import 'format.dart';

/// Supplies byte sizes for [assets], keyed by asset id.
typedef AssetSizeResolver = Future<Map<String, int>> Function(
  List<AssetEntity> assets,
);

/// Sorts [assets] using the user's "Sort by" + "Sort order" choice.
///
/// This is a pure, in-memory operation unless [field] is [SortField.size]:
/// sizes are not part of the metadata returned by MediaStore, so an async
/// resolver is used for that case only. Results are deterministic: ties fall
/// back to the creation date and then the asset id.
Future<List<AssetEntity>> sortAssets(
  List<AssetEntity> assets, {
  required MediaKind kind,
  required SortField field,
  required SortOrder order,
  AssetSizeResolver? sizeResolver,
}) async {
  final list = List<AssetEntity>.of(assets);

  // "Duration" has no meaning for still images.
  final effectiveField = field.supports(kind) ? field : SortField.date;

  Map<String, int> sizes = const <String, int>{};
  if (effectiveField == SortField.size && sizeResolver != null) {
    sizes = await sizeResolver(list);
  }

  int compare(AssetEntity a, AssetEntity b) {
    switch (effectiveField) {
      case SortField.name:
        return cleanTitle(a.title)
            .toLowerCase()
            .compareTo(cleanTitle(b.title).toLowerCase());
      case SortField.size:
        return (sizes[a.id] ?? 0).compareTo(sizes[b.id] ?? 0);
      case SortField.date:
        return (a.createDateSecond ?? 0).compareTo(b.createDateSecond ?? 0);
      case SortField.duration:
        return a.duration.compareTo(b.duration);
    }
  }

  list.sort((a, b) {
    final primary = compare(a, b);
    if (primary != 0) return primary;
    final date = (a.createDateSecond ?? 0).compareTo(b.createDateSecond ?? 0);
    if (date != 0) return date;
    return a.id.compareTo(b.id);
  });

  if (order == SortOrder.descending) {
    return list.reversed.toList(growable: false);
  }
  return list;
}
