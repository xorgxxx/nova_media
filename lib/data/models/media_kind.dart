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

  String get label {
    switch (this) {
      case MediaKind.video:
        return 'Videos';
      case MediaKind.image:
        return 'Photos';
      case MediaKind.audio:
        return 'Music';
    }
  }

  String get singularLabel {
    switch (this) {
      case MediaKind.video:
        return 'video';
      case MediaKind.image:
        return 'photo';
      case MediaKind.audio:
        return 'track';
    }
  }
}
