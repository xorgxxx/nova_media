import 'package:photo_manager/photo_manager.dart';

enum MediaKind { video, image, audio }

extension MediaKindX on MediaKind {
  RequestType get requestType {
    switch (this) {
      case MediaKind.video:
        return RequestType.video;
      case MediaKind.image:
        return RequestType.image;
      case MediaKind.audio:
        return RequestType.audio;
    }
  }
}
