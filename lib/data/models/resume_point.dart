class ResumePoint {
  const ResumePoint({
    required this.assetId,
    required this.positionMs,
    required this.durationMs,
    required this.updatedAt,
  });

  final String assetId;
  final int positionMs;
  final int durationMs;
  final int updatedAt;

  double get fraction =>
      durationMs <= 0 ? 0.0 : (positionMs / durationMs).clamp(0.0, 1.0).toDouble();

  /// Worth offering "resume": watched more than 5s and not almost finished.
  bool get isResumable => positionMs > 5000 && positionMs < durationMs - 10000;
}
