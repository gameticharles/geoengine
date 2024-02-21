part of '../leveling.dart';

/// An abstract class representing a base surveying measurement with common properties.
abstract class Measurement {
  /// The model of the instrument used for the measurement, if available.
  String? instrumentModel;

  /// The serial number of the instrument used for the measurement, if available.
  String? instrumentSerialNumber;

  /// The name of the operator who performed the measurement, if available.
  String? operatorName;

  /// Any additional comments or notes related to the measurement, if available.
  String? comments;

  /// An error message associated with the measurement, if applicable.
  String? errorMessage;

  /// The accuracy of the measurement, if available (0 to 1).
  double? accuracy;

  /// The timestamp of the measurement, if available.
  DateTime? timestamp;

  /// A map containing additional metadata related to the measurement, or null if not available.
  Map<String, dynamic>? metadata;
}

/// A class representing a levelling survey measurement.
class LevellingMeasurement extends Measurement {
  /// The station or reference point ID for the measurement.
  String? station;

  /// The backward sight (BS) distance, if available.
  final double? bs;

  /// The intersecting (IS) distance, if available.
  final double? is_;

  /// The forward sight (FS) distance, if available.
  final double? fs;

  /// The latitude coordinate of the measurement location, if available.
  final double? y;

  /// The longitude coordinate of the measurement location, if available.
  final double? x;

  /// The distance to the next station in meters or feet, calculated from the measurement, or null if not available.
  final double? distance;

  /// Creates a new Measurement instance with all properties set.
  LevellingMeasurement({
    this.bs,
    this.is_,
    this.fs,
    this.station,
    this.distance,
    this.y,
    this.x,
    timestamp,
    instrumentModel,
    instrumentSerialNumber,
    operatorName,
    comments,
    errorMessage,
    accuracy,
    metadata,
  });

  /// Checks if the measurement is valid based on certain conditions (e.g., at least one distance reading should be present).
  bool isValid() {
    // At least one of the readings should be present
    var l = (bs == null && is_ == null && fs == null);

    if (l) return false;

    // If accuracy is provided, it should be within a specific range (0 to 1 for this example)
    if (accuracy != null && (accuracy! < 0 || accuracy! > 1)) return false;

    // There shouldn't be any error message associated with the measurement
    if (errorMessage != null && errorMessage!.isNotEmpty) return false;

    // If other conditions are met, the measurement is considered valid
    return true;
  }
}

/// A class representing a Traversing survey measurement.
class TraversingMeasurement extends Measurement {
  /// The station or reference point ID for the measurement.
  String? station;

  /// The distance to the next station in meters or feet, calculated from the measurement, or null if not available.
  final double? distance;

  /// The y-coordinate of the measurement location, if available.
  final double? y;

  /// The  x-coordinate of the measurement location, if available.
  final double? x;

  /// The measured horizontal circle angle in degrees (range: 0 to 360), or null if not available.
  final double? horizontalAngle;

  /// The measured vertical circle angle in degrees (range: 0 to 180), or null if not available.
  final double? verticalAngle;

  /// The bearing or azimuth in degrees (range: 0 to 360), calculated from the measurement, or null if not available.
  final double? bearing;

  /// Creates a new Measurement instance with all properties set.
  TraversingMeasurement({
    this.station,
    this.horizontalAngle,
    this.verticalAngle,
    this.distance,
    this.y,
    this.x,
    this.bearing,
    timestamp,
    instrumentModel,
    instrumentSerialNumber,
    operatorName,
    comments,
    errorMessage,
    accuracy,
    metadata,
  });

  /// Checks if the measurement is valid based on certain conditions (e.g., at least one distance reading should be present).
  bool isValid() {
    // At least one of the readings should be present

    var h = (horizontalAngle == null && bearing == null && distance == null);
    if (h) return false;

    // If accuracy is provided, it should be within a specific range (0 to 1 for this example)
    if (accuracy != null && (accuracy! < 0 || accuracy! > 1)) return false;

    // There shouldn't be any error message associated with the measurement
    if (errorMessage != null && errorMessage!.isNotEmpty) return false;

    // If other conditions are met, the measurement is considered valid
    return true;
  }
}
