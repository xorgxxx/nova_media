import 'media_kind.dart';

class Playlist {
  const Playlist({
    required this.id,
    required this.kind,
    required this.name,
    required this.itemCount,
  });

  final int id;
  final MediaKind kind;
  final String name;
  final int itemCount;
}
