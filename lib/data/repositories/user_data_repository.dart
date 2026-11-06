import 'package:sqflite/sqflite.dart';

import '../database/app_database.dart';
import '../models/media_kind.dart';
import '../models/playlist.dart';
import '../models/resume_point.dart';

/// All user-generated data: favorites, playlists and resume points.
class UserDataRepository {
  UserDataRepository(this._db);

  final Database _db;

  static Future<UserDataRepository> open() async =>
      UserDataRepository(await AppDatabase.open());

  int get _now => DateTime.now().millisecondsSinceEpoch;

  // ---- Favorites -------------------------------------------------------

  Future<Set<String>> favoriteIds(MediaKind kind) async {
    final rows = await _db.query('favorites',
        columns: ['asset_id'], where: 'kind = ?', whereArgs: [kind.name]);
    return rows.map((r) => r['asset_id']! as String).toSet();
  }

  Future<void> setFavorite(MediaKind kind, String assetId, bool value) async {
    if (value) {
      await _db.insert(
        'favorites',
        {'kind': kind.name, 'asset_id': assetId, 'added_at': _now},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } else {
      await _db.delete('favorites',
          where: 'kind = ? AND asset_id = ?', whereArgs: [kind.name, assetId]);
    }
  }

  // ---- Playlists -------------------------------------------------------

  Future<List<Playlist>> playlists(MediaKind kind) async {
    final rows = await _db.rawQuery('''
SELECT p.id AS id, p.name AS name, COUNT(i.asset_id) AS item_count
FROM playlists p
LEFT JOIN playlist_items i ON i.playlist_id = p.id
WHERE p.kind = ?
GROUP BY p.id
ORDER BY p.created_at DESC''', [kind.name]);
    return rows
        .map((r) => Playlist(
              id: r['id']! as int,
              kind: kind,
              name: r['name']! as String,
              itemCount: (r['item_count'] as int?) ?? 0,
            ))
        .toList();
  }

  Future<int> createPlaylist(MediaKind kind, String name) {
    return _db.insert('playlists', {'kind': kind.name, 'name': name, 'created_at': _now});
  }

  Future<void> renamePlaylist(int id, String name) async {
    await _db.update('playlists', {'name': name}, where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deletePlaylist(int id) async {
    await _db.delete('playlists', where: 'id = ?', whereArgs: [id]);
  }

  Future<List<String>> playlistItemIds(int playlistId) async {
    final rows = await _db.query('playlist_items',
        columns: ['asset_id'],
        where: 'playlist_id = ?',
        whereArgs: [playlistId],
        orderBy: 'position ASC');
    return rows.map((r) => r['asset_id']! as String).toList();
  }

  Future<void> addToPlaylist(int playlistId, String assetId) async {
    final res = await _db.rawQuery(
      'SELECT COALESCE(MAX(position), -1) + 1 AS next FROM playlist_items WHERE playlist_id = ?',
      [playlistId],
    );
    final next = (res.first['next'] as int?) ?? 0;
    await _db.insert(
      'playlist_items',
      {'playlist_id': playlistId, 'asset_id': assetId, 'position': next},
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeFromPlaylist(int playlistId, String assetId) async {
    await _db.delete('playlist_items',
        where: 'playlist_id = ? AND asset_id = ?', whereArgs: [playlistId, assetId]);
  }

  // ---- Settings --------------------------------------------------------

  Future<Map<String, String>> settings() async {
    final rows = await _db.query('settings');
    return {
      for (final row in rows) row['key']! as String: row['value']! as String,
    };
  }

  Future<void> setSetting(String key, String value) async {
    await _db.insert(
      'settings',
      {'key': key, 'value': value},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ---- File-size cache -------------------------------------------------

  /// Returns cached byte sizes for the assets whose modification time still
  /// matches [modifiedAt]. Anything stale (or unknown) is simply omitted, so
  /// the caller knows it has to fetch just those items again.
  Future<Map<String, int>> cachedAssetSizes(Map<String, int> modifiedAt) async {
    if (modifiedAt.isEmpty) return <String, int>{};
    final rows = await _db.query('asset_sizes');
    final result = <String, int>{};
    for (final row in rows) {
      final id = row['asset_id']! as String;
      final expected = modifiedAt[id];
      if (expected == null) continue;
      if ((row['modified_at']! as int) == expected) {
        result[id] = row['size_bytes']! as int;
      }
    }
    return result;
  }

  Future<void> saveAssetSizes(
    Map<String, ({int size, int modifiedAt})> values,
  ) async {
    if (values.isEmpty) return;
    final batch = _db.batch();
    values.forEach((id, value) {
      batch.insert(
        'asset_sizes',
        {
          'asset_id': id,
          'size_bytes': value.size,
          'modified_at': value.modifiedAt,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    });
    await batch.commit(noResult: true);
  }

  // ---- Media removal ---------------------------------------------------

  /// Drops every piece of user data that points at assets deleted from the
  /// device (favorites, playlist entries, resume points and cached sizes).
  Future<void> removeAssets(Iterable<String> assetIds) async {
    final ids = assetIds.toList(growable: false);
    if (ids.isEmpty) return;
    await _db.transaction((txn) async {
      for (var start = 0; start < ids.length; start += 400) {
        final end = (start + 400 < ids.length) ? start + 400 : ids.length;
        final chunk = ids.sublist(start, end);
        final placeholders = List.filled(chunk.length, '?').join(',');
        await txn.delete('favorites', where: 'asset_id IN ($placeholders)', whereArgs: chunk);
        await txn.delete('playlist_items',
            where: 'asset_id IN ($placeholders)', whereArgs: chunk);
        await txn.delete('progress', where: 'asset_id IN ($placeholders)', whereArgs: chunk);
        await txn.delete('asset_sizes', where: 'asset_id IN ($placeholders)', whereArgs: chunk);
      }
    });
  }

  // ---- Resume points ---------------------------------------------------

  Future<ResumePoint?> getProgress(String assetId) async {
    final rows = await _db.query('progress', where: 'asset_id = ?', whereArgs: [assetId]);
    return rows.isEmpty ? null : _toResume(rows.first);
  }

  Future<Map<String, ResumePoint>> allProgress() async {
    final rows = await _db.query('progress', orderBy: 'updated_at DESC');
    return {for (final r in rows) r['asset_id']! as String: _toResume(r)};
  }

  Future<void> saveProgress(String assetId, int positionMs, int durationMs) async {
    await _db.insert(
      'progress',
      {
        'asset_id': assetId,
        'position_ms': positionMs,
        'duration_ms': durationMs,
        'updated_at': _now,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> clearProgress(String assetId) async {
    await _db.delete('progress', where: 'asset_id = ?', whereArgs: [assetId]);
  }

  ResumePoint _toResume(Map<String, Object?> r) => ResumePoint(
        assetId: r['asset_id']! as String,
        positionMs: r['position_ms']! as int,
        durationMs: r['duration_ms']! as int,
        updatedAt: r['updated_at']! as int,
      );
}
