import 'package:flutter_test/flutter_test.dart';
import 'package:nova_media/core/utils/media_sort.dart';
import 'package:nova_media/data/models/app_settings.dart';
import 'package:nova_media/data/models/media_kind.dart';
import 'package:photo_manager/photo_manager.dart';

AssetEntity _asset(
  String id, {
  String? title,
  int? created,
  int duration = 0,
  AssetType type = AssetType.image,
}) {
  return AssetEntity(
    id: id,
    typeInt: type.index,
    width: 1920,
    height: 1080,
    title: title,
    createDateSecond: created,
    duration: duration,
  );
}

void main() {
  group('SortField.supports', () {
    test('name/size/date apply to every media kind', () {
      for (final field in [SortField.name, SortField.size, SortField.date]) {
        for (final kind in MediaKind.values) {
          expect(field.supports(kind), isTrue, reason: '$field / $kind');
        }
      }
    });

    test('duration only applies to video and audio', () {
      expect(SortField.duration.supports(MediaKind.video), isTrue);
      expect(SortField.duration.supports(MediaKind.audio), isTrue);
      expect(SortField.duration.supports(MediaKind.image), isFalse);
    });
  });

  group('parse helpers', () {
    test('round-trip every enum value', () {
      for (final field in SortField.values) {
        expect(parseSortField(field.name, SortField.date), field);
      }
      for (final order in SortOrder.values) {
        expect(parseSortOrder(order.name, SortOrder.ascending), order);
      }
      for (final mode in AppThemeMode.values) {
        expect(parseThemeMode(mode.name, AppThemeMode.system), mode);
      }
    });

    test('unknown values fall back', () {
      expect(parseSortField('nope', SortField.size), SortField.size);
      expect(parseSortOrder('nope', SortOrder.descending), SortOrder.descending);
      expect(parseThemeMode('nope', AppThemeMode.dark), AppThemeMode.dark);
    });
  });

  group('sortAssets', () {
    final assets = [
      _asset('b', title: 'Beta.mp4', created: 200, duration: 90),
      _asset('a', title: 'alpha.mp4', created: 100, duration: 30),
      _asset('c', title: 'Gamma.mp4', created: 300, duration: 60),
    ];

    test('name ascending is case-insensitive', () async {
      final result = await sortAssets(
        assets,
        kind: MediaKind.video,
        field: SortField.name,
        order: SortOrder.ascending,
      );
      expect(result.map((a) => a.id), ['a', 'b', 'c']);
    });

    test('name descending', () async {
      final result = await sortAssets(
        assets,
        kind: MediaKind.video,
        field: SortField.name,
        order: SortOrder.descending,
      );
      expect(result.map((a) => a.id), ['c', 'b', 'a']);
    });

    test('date ascending and descending', () async {
      final asc = await sortAssets(
        assets,
        kind: MediaKind.video,
        field: SortField.date,
        order: SortOrder.ascending,
      );
      expect(asc.map((a) => a.id), ['a', 'b', 'c']);

      final desc = await sortAssets(
        assets,
        kind: MediaKind.video,
        field: SortField.date,
        order: SortOrder.descending,
      );
      expect(desc.map((a) => a.id), ['c', 'b', 'a']);
    });

    test('duration ascending and descending', () async {
      final asc = await sortAssets(
        assets,
        kind: MediaKind.video,
        field: SortField.duration,
        order: SortOrder.ascending,
      );
      expect(asc.map((a) => a.id), ['a', 'c', 'b']);

      final desc = await sortAssets(
        assets,
        kind: MediaKind.video,
        field: SortField.duration,
        order: SortOrder.descending,
      );
      expect(desc.map((a) => a.id), ['b', 'c', 'a']);
    });

    test('size uses the async resolver', () async {
      final sizes = {'a': 500, 'b': 100, 'c': 900};
      final result = await sortAssets(
        assets,
        kind: MediaKind.video,
        field: SortField.size,
        order: SortOrder.ascending,
        sizeResolver: (list) async => {
          for (final asset in list) asset.id: sizes[asset.id]!,
        },
      );
      expect(result.map((a) => a.id), ['b', 'a', 'c']);
    });

    test('duration falls back to date for images', () async {
      final images = [
        _asset('old', title: 'old.jpg', created: 10),
        _asset('new', title: 'new.jpg', created: 20),
      ];
      final result = await sortAssets(
        images,
        kind: MediaKind.image,
        field: SortField.duration,
        order: SortOrder.ascending,
      );
      expect(result.map((a) => a.id), ['old', 'new']);
    });

    test('does not mutate the input list', () async {
      final input = List<AssetEntity>.of(assets);
      await sortAssets(
        input,
        kind: MediaKind.video,
        field: SortField.name,
        order: SortOrder.ascending,
      );
      expect(input.map((a) => a.id), ['b', 'a', 'c']);
    });
  });
}
