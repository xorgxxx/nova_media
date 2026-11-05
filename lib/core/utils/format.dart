String _two(int n) => n.toString().padLeft(2, '0');

/// 65s -> "01:05", 3725s -> "1:02:05".
String formatDuration(Duration d) {
  final total = d.inSeconds < 0 ? 0 : d.inSeconds;
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  return h > 0 ? '$h:${_two(m)}:${_two(s)}' : '${_two(m)}:${_two(s)}';
}

String formatSeconds(int seconds) => formatDuration(Duration(seconds: seconds));

/// Removes a trailing file extension (".mp3") and handles null/empty names.
String cleanTitle(String? raw) {
  if (raw == null || raw.trim().isEmpty) return 'Untitled';
  final i = raw.lastIndexOf('.');
  return (i > 0 && raw.length - i <= 6) ? raw.substring(0, i) : raw;
}

String formatDate(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';
