part of leveling;

class Measurement {
  final String station;
  final double? bs;
  final double? is_;
  final double? fs;
  final DateTime? timestamp;
  final double? latitude;
  final double? longitude;
  final String? instrumentModel;
  final String? instrumentSerialNumber;
  final String? operatorName;
  final String? comments;
  final String? errorMessage;
  final Map<String, dynamic>? metadata;
  final double? accuracy;

  final double? rise;
  final double? fall;
  final double? horizontalAngle; // Measured horizontal angle
  final double? bearing; // Bearing or azimuth
  final double? distance; // Distance to the next station

  bool isValid() {
    // At least one of the readings should be present
    var l = (bs == null && is_ == null && fs == null);
    var h = (horizontalAngle == null && bearing == null && distance == null);
    if (l && h) return false;

    // If accuracy is provided, it should be within a specific range (0 to 1 for this example)
    if (accuracy != null && (accuracy! < 0 || accuracy! > 1)) return false;

    // There shouldn't be any error message associated with the measurement
    if (errorMessage != null && errorMessage!.isNotEmpty) return false;

    // If other conditions are met, the measurement is considered valid
    return true;
  }

  Measurement({
    required this.station,
    this.bs,
    this.is_,
    this.fs,
    this.rise,
    this.fall,
    this.horizontalAngle,
    this.bearing,
    this.distance,
    this.timestamp,
    this.latitude,
    this.longitude,
    this.instrumentModel,
    this.instrumentSerialNumber,
    this.operatorName,
    this.comments,
    this.errorMessage,
    this.accuracy,
    this.metadata,
  });
}
