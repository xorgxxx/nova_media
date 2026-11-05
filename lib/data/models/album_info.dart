import 'package:photo_manager/photo_manager.dart';

import 'media_kind.dart';

class AlbumRef {
  const AlbumRef({required this.id, required this.name, required this.kind});

  final String id;
  final String name;
  final MediaKind kind;

  @override
  bool operator ==(Object other) =>
      other is AlbumRef && other.id == id && other.kind == kind;

  @override
  int get hashCode => Object.hash(id, kind);
}

class AlbumInfo {
  const AlbumInfo({required this.ref, required this.count, this.cover});

  final AlbumRef ref;
  final int count;
  final AssetEntity? cover;
}
