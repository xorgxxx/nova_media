import 'dart:ffi' show Abi;

import 'package:flutter/services.dart';

class StorageSnapshot {
  const StorageSnapshot({
    required this.totalBytes,
    required this.freeBytes,
    required this.cacheBytes,
  });

  final int totalBytes;
  final int freeBytes;
  final int cacheBytes;

  int get usedBytes => (totalBytes - freeBytes).clamp(0, totalBytes).toInt();
}

/// Thin bridge to the native storage statistics exposed by MainActivity.
class DeviceStorage {
  static const MethodChannel _channel = MethodChannel('as_vault/system');

  static Future<StorageSnapshot?> read() async {
    try {
      final map = await _channel.invokeMapMethod<String, dynamic>('storageStats');
      if (map == null) return null;
      return StorageSnapshot(
        totalBytes: (map['totalBytes'] as num?)?.toInt() ?? 0,
        freeBytes: (map['freeBytes'] as num?)?.toInt() ?? 0,
        cacheBytes: (map['cacheBytes'] as num?)?.toInt() ?? 0,
      );
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<int> clearAppCache() async {
    try {
      return await _channel.invokeMethod<int>('clearAppCache') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// The ABI this build is actually running on. AS Vault ships arm64-v8a only,
  /// so on a phone this reads "ARM64 (arm64-v8a)".
  static String get architecture {
    final abi = Abi.current();
    if (abi == Abi.androidArm64) return 'ARM64 (arm64-v8a)';
    if (abi == Abi.androidArm) return 'ARM 32-bit (armeabi-v7a)';
    if (abi == Abi.androidX64) return 'x86_64 (emulator)';
    if (abi == Abi.androidIA32) return 'x86 (emulator)';
    return abi.toString();
  }
}

String formatBytes(int bytes) {
  if (bytes <= 0) return '0 B';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final digits = value >= 100 || unit == 0 ? 0 : 1;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}
