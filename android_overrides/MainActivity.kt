package com.novamedia.nova_media

import android.os.Environment
import android.os.StatFs
import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

/**
 * Host activity for AS Vault.
 *
 * Besides the audio_service wiring required by just_audio_background, this
 * activity exposes a tiny "as_vault/system" channel used by the Settings page
 * for real device storage statistics and cache clearing.
 */
class MainActivity : AudioServiceActivity() {
    private val channelName = "as_vault/system"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "storageStats" -> result.success(storageStats())
                    "clearAppCache" -> result.success(clearAppCache())
                    else -> result.notImplemented()
                }
            }
    }

    private fun storageStats(): Map<String, Long> {
        var total = 0L
        var free = 0L
        try {
            val stat = StatFs(Environment.getDataDirectory().absolutePath)
            total = stat.totalBytes
            free = stat.availableBytes
        } catch (_: Exception) {
            // Leave zeroes; the Dart side renders "Unavailable".
        }
        return mapOf(
            "totalBytes" to total,
            "freeBytes" to free,
            "cacheBytes" to directorySize(cacheDirs()),
        )
    }

    private fun clearAppCache(): Long {
        var freed = 0L
        for (dir in cacheDirs()) {
            freed += deleteContents(dir)
        }
        return freed
    }

    private fun cacheDirs(): List<File> {
        val dirs = mutableListOf<File>()
        cacheDir?.let { dirs.add(it) }
        externalCacheDir?.let { dirs.add(it) }
        return dirs
    }

    private fun directorySize(dirs: List<File>): Long {
        var size = 0L
        for (dir in dirs) {
            val files = dir.listFiles() ?: continue
            for (file in files) {
                size += if (file.isDirectory) directorySize(listOf(file)) else file.length()
            }
        }
        return size
    }

    private fun deleteContents(dir: File): Long {
        var freed = 0L
        val files = dir.listFiles() ?: return 0L
        for (file in files) {
            freed += if (file.isDirectory) {
                val inner = deleteContents(file)
                file.delete()
                inner
            } else {
                val length = file.length()
                if (file.delete()) length else 0L
            }
        }
        return freed
    }
}
