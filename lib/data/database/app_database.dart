import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Opens (and migrates) the local SQLite database.
///
/// Schema history:
///   v1 - favorites, playlists, playlist_items, progress.
///   v2 - settings (theme, sort, grid) and asset_sizes (file-size cache used
///        by the "Sort by size" option, so MediaStore is not re-queried for
///        every item on every sort).
class AppDatabase {
  static const _name = 'nova_media.db';
  static const _version = 2;

  static Future<Database> open() async {
    final dir = await getDatabasesPath();
    return openDatabase(
      p.join(dir, _name),
      version: _version,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (db, version) async {
        await _createV1(db);
        await _createV2(db);
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) await _createV2(db);
      },
    );
  }

  static Future<void> _createV1(Database db) async {
    await db.execute('''
CREATE TABLE favorites(
  kind TEXT NOT NULL,
  asset_id TEXT NOT NULL,
  added_at INTEGER NOT NULL,
  PRIMARY KEY(kind, asset_id)
)''');
    await db.execute('''
CREATE TABLE playlists(
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  kind TEXT NOT NULL,
  name TEXT NOT NULL,
  created_at INTEGER NOT NULL
)''');
    await db.execute('''
CREATE TABLE playlist_items(
  playlist_id INTEGER NOT NULL,
  asset_id TEXT NOT NULL,
  position INTEGER NOT NULL,
  PRIMARY KEY(playlist_id, asset_id),
  FOREIGN KEY(playlist_id) REFERENCES playlists(id) ON DELETE CASCADE
)''');
    await db.execute('''
CREATE TABLE progress(
  asset_id TEXT PRIMARY KEY,
  position_ms INTEGER NOT NULL,
  duration_ms INTEGER NOT NULL,
  updated_at INTEGER NOT NULL
)''');
  }

  static Future<void> _createV2(Database db) async {
    await db.execute('''
CREATE TABLE IF NOT EXISTS settings(
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL
)''');
    await db.execute('''
CREATE TABLE IF NOT EXISTS asset_sizes(
  asset_id TEXT PRIMARY KEY,
  size_bytes INTEGER NOT NULL,
  modified_at INTEGER NOT NULL
)''');
  }
}
