import 'package:photo_manager/photo_manager.dart';

import '../../core/utils/format.dart';
import '../models/album_info.dart';
import '../models/media_kind.dart';

/// Thin wrapper over photo_manager (Android MediaStore).
class LibraryRepository {
  PermissionRequestOption get _option => PermissionRequestOption(
        androidPermission: AndroidPermission(
          type: RequestType.all,
          mediaLocation: false,
        ),
      );

  Future<PermissionState> permissionState() =>
      PhotoManager.getPermissionState(requestOption: _option);

  Future<PermissionState> requestPermission() =>
      PhotoManager.requestPermissionExtend(requestOption: _option);

  Future<void> openSettings() => PhotoManager.openSetting();

  /// All assets of a kind. Videos/photos: newest first. Audio: alphabetical,
  /// ignoring very short clips (ringtones, notification sounds).
  Future<List<AssetEntity>> loadAll(MediaKind kind) async {
    final paths = await PhotoManager.getAssetPathList(
      type: kind.requestType,
      onlyAll: true,
    );
    if (paths.isEmpty) return <AssetEntity>[];
    final all = paths.first;
    final count = await all.assetCountAsync;
    if (count == 0) return <AssetEntity>[];
    var list = await all.getAssetListRange(start: 0, end: count);
    if (kind == MediaKind.audio) {
      list = list.where((a) => a.duration >= 10).toList()
        ..sort((a, b) =>
            cleanTitle(a.title).toLowerCase().compareTo(cleanTitle(b.title).toLowerCase()));
    }
    return list;
  }

  Future<List<AlbumInfo>> loadAlbums(MediaKind kind) async {
    final paths = await PhotoManager.getAssetPathList(
      type: kind.requestType,
      hasAll: false,
    );
    final result = <AlbumInfo>[];
    for (final path in paths) {
      final count = await path.assetCountAsync;
      if (count == 0) continue;
      final first = await path.getAssetListRange(start: 0, end: 1);
      result.add(AlbumInfo(
        ref: AlbumRef(id: path.id, name: path.name, kind: kind),
        count: count,
        cover: first.isEmpty ? null : first.first,
      ));
    }
    result.sort((a, b) => b.count.compareTo(a.count));
    return result;
  }

  Future<List<AssetEntity>> loadAlbumAssets(AlbumRef ref) async {
    final path = await AssetPathEntity.fromId(ref.id, type: ref.kind.requestType);
    final count = await path.assetCountAsync;
    if (count == 0) return <AssetEntity>[];
    return path.getAssetListRange(start: 0, end: count);
  }
}
