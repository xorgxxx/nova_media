import 'package:flutter_test/flutter_test.dart';
import 'package:nova_media/core/utils/format.dart';
import 'package:nova_media/data/models/resume_point.dart';

void main() {
  group('formatDuration', () {
    test('minutes and seconds', () => expect(formatDuration(const Duration(seconds: 65)), '01:05'));
    test('hours', () => expect(formatDuration(const Duration(seconds: 3725)), '1:02:05'));
    test('negative clamps to zero', () => expect(formatDuration(const Duration(seconds: -5)), '00:00'));
  });

  group('cleanTitle', () {
    test('strips extension', () => expect(cleanTitle('song.mp3'), 'song'));
    test('null -> Untitled', () => expect(cleanTitle(null), 'Untitled'));
    test('hidden file name kept', () => expect(cleanTitle('.hidden'), '.hidden'));
  });

  group('ResumePoint', () {
    ResumePoint p(int pos, int dur) =>
        ResumePoint(assetId: 'a', positionMs: pos, durationMs: dur, updatedAt: 0);
    test('resumable in the middle', () => expect(p(60000, 600000).isResumable, isTrue));
    test('not resumable at the start', () => expect(p(2000, 600000).isResumable, isFalse));
    test('not resumable near the end', () => expect(p(595000, 600000).isResumable, isFalse));
    test('fraction', () => expect(p(300000, 600000).fraction, 0.5));
  });
}
