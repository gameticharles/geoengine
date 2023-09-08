part of geoengine;

/// An enum that represents the confidence level with their z-score values
enum ConfidenceLevel {
  /// 10% confidence level
  p10(0.126),

  /// 20% confidence level
  p20(0.253),

  /// 30% confidence level
  p30(0.385),

  /// 40% confidence level
  p40(0.524),

  /// 50% confidence level
  p50(0.674),

  /// 60% confidence level
  p60(0.842),

  /// 70% confidence level
  p70(1.036),

  /// 75% confidence level
  p75(1.150),

  /// 80% confidence level
  p80(1.282),

  /// 85% confidence level
  p85(1.440),

  /// 90% confidence level
  p90(1.645),

  /// 92% confidence level
  p92(1.751),

  /// 95% confidence level
  p95(1.96),

  /// 96% confidence level
  p96(2.054),

  /// 97% confidence level
  p97(2.170),

  /// 98% confidence level
  p98(2.326),

  /// 99% confidence level
  p99(2.576),

  /// 99.5% confidence level
  p99_5(2.807),

  /// 99.9% confidence level
  p99_9(3.291),

  /// 99.99% confidence level
  p99_99(3.891),

  /// 99.999% confidence level
  p99_999(4.417);

  const ConfidenceLevel(this.value);
  final double value;

  @override
  String toString() {
    return '${name.substring(1).replaceAll(RegExp(r'_'), '.')}%';
  }
}
