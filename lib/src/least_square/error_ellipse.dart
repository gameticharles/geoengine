part of '../../geoengine.dart';

/// Represents an error ellipse calculated from covariance matrix components.
/// This class provides methods to compute properties of the ellipse such as
/// semi-major and semi-minor axes, orientation, area, and more.
class ErrorEllipse {
  // Fields
  /// Variance along the X axis.
  double sigmaX2;

  /// Variance along the Y axis.
  double sigmaY2;

  /// Covariance between X and Y.
  double sigmaXY;

  /// Scale factor for the ellipse (default is 1.0).
  double sigmaO;

  /// Semi-major axis length of the ellipse.
  double _a;

  /// Semi-minor axis length of the ellipse.
  double _b;

  /// Orientation angle of the ellipse in degrees.
  double _theta;

  /// Bearing angle derived from the orientation.
  double _bearing;

  /// Distance along the X axis.
  double _sx;

  /// Distance along the Y axis.
  double _sy;

  /// Area of the ellipse.
  double _area;

  /// Confidence level for the ellipse.
  double _confidenceLevel;

  /// Eccentricity of the ellipse.
  double _eccentricity;

  /// Aspect ratio of the ellipse.
  double _aspectRatio;

  /// Precomputed constant for degrees to radians conversion.
  static const double degreesToRadians = pi / 180;

  /// Constructor for creating an ErrorEllipse instance.
  ///
  /// [sigmaX2]: Variance along the X axis.
  /// [sigmaY2]: Variance along the Y axis.
  /// [sigmaXY]: Covariance between X and Y.
  /// [sigmaO]: Scale factor for the ellipse (default is 1.0).
  /// [confidenceLevel]: Confidence level for the ellipse (default is 0.95).
  ErrorEllipse({
    required this.sigmaX2,
    required this.sigmaY2,
    required this.sigmaXY,
    this.sigmaO = 1.0,
    double confidenceLevel = 0.95,
  })  : _confidenceLevel = confidenceLevel,
        _a = 0.0,
        _b = 0.0,
        _theta = 0.0,
        _bearing = 0.0,
        _sx = 0.0,
        _sy = 0.0,
        _area = 0.0,
        _eccentricity = 0.0,
        _aspectRatio = 0.0 {
    validateInputs();
    computeEllipseParameters();
  }

  /// Validates the input parameters for the ellipse.
  void validateInputs() {
    if (sigmaX2 < 0 || sigmaY2 < 0) {
      throw ArgumentError('Variances must be non-negative.');
    }
    if (_confidenceLevel <= 0 || _confidenceLevel > 1) {
      throw ArgumentError('Confidence level must be between 0 and 1.');
    }
  }

  /// Computes the parameters of the error ellipse including semi-major and semi-minor axes,
  /// orientation, area, eccentricity, and aspect ratio.
  void computeEllipseParameters() {
    double delta = _computeDelta();
    double lambda1 = 0.5 * (sigmaX2 + sigmaY2 + delta);
    double lambda2 = 0.5 * (sigmaX2 + sigmaY2 - delta);

    _a = sigmaO * sqrt(lambda1);
    _b = sigmaO * sqrt(lambda2);

    _theta = 0.5 * atan2(2 * sigmaXY, sigmaX2 - sigmaY2) * (180 / pi);
    _bearing = (90 - _theta) % 360;

    _sx = sigmaO * sqrt(sigmaX2);
    _sy = sigmaO * sqrt(sigmaY2);

    _area = pi * _a * _b;

    _eccentricity = sqrt(1 - pow(_b / _a, 2));

    _aspectRatio = _a / _b;
  }

  /// Computes delta (a helper method for eigenvalue calculations).
  double _computeDelta() {
    return sqrt(pow((sigmaX2 - sigmaY2), 2) + 4 * pow(sigmaXY, 2));
  }

  /// Updates ellipse parameters dynamically by changing input variances or covariance.
  void updateParameters(
      {double? newSigmaX2, double? newSigmaY2, double? newSigmaXY}) {
    if (newSigmaX2 != null) sigmaX2 = newSigmaX2;
    if (newSigmaY2 != null) sigmaY2 = newSigmaY2;
    if (newSigmaXY != null) sigmaXY = newSigmaXY;
    validateInputs();
    computeEllipseParameters();
  }

  /// Getter for the semi-major axis length of the ellipse.
  double get semiMajorAxis => _a;

  /// Getter for the semi-minor axis length of the ellipse.
  double get semiMinorAxis => _b;

  /// Getter for the orientation angle of the ellipse in degrees.
  double get orientationAngle => _theta;

  /// Getter for the bearing angle derived from the orientation.
  double get bearing => _bearing;

  /// Getter for the distance along the X axis.
  double get sx => _sx;

  /// Getter for the distance along the Y axis.
  double get sy => _sy;

  /// Getter for the area of the ellipse.
  double get area => _area;

  /// Getter for the eccentricity of the ellipse.
  double get eccentricity => _eccentricity;

  /// Getter for the aspect ratio of the ellipse.
  double get aspectRatio => _aspectRatio;

  /// Serializes the ellipse data into a JSON-compatible map.
  Map<String, dynamic> toJson() => {
        'sigmaX2': sigmaX2,
        'sigmaY2': sigmaY2,
        'sigmaXY': sigmaXY,
        'sigmaO': sigmaO,
        'confidenceLevel': _confidenceLevel,
        'a': _a,
        'b': _b,
        'theta': _theta,
        'bearing': _bearing,
        'sx': _sx,
        'sy': _sy,
        'area': _area,
        'eccentricity': _eccentricity,
        'aspectRatio': _aspectRatio,
      };

  /// Deserializes JSON-compatible map into an ErrorEllipse instance.
  factory ErrorEllipse.fromJson(Map<String, dynamic> json) => ErrorEllipse(
        sigmaX2: json['sigmaX2'],
        sigmaY2: json['sigmaY2'],
        sigmaXY: json['sigmaXY'],
        sigmaO: json['sigmaO'],
        confidenceLevel: json['confidenceLevel'],
      );

  /// Generates points representing the ellipse for plotting purposes.
  List<Map<String, double>> generateEllipsePoints(int numPoints,
      {double centerX = 0.0, double centerY = 0.0}) {
    List<Map<String, double>> points = [];
    for (int i = 0; i < numPoints; i++) {
      double angle = (2 * pi * i) / numPoints;
      double x = centerX +
          (_a * cos(angle) * cos(_theta * degreesToRadians) -
              _b * sin(angle) * sin(_theta * degreesToRadians));
      double y = centerY +
          (_a * cos(angle) * sin(_theta * degreesToRadians) +
              _b * sin(angle) * cos(_theta * degreesToRadians));
      points.add({'x': x, 'y': y});
    }
    return points;
  }

  /// Returns a string representation of the error ellipse, including all computed properties.
  @override
  String toString() {
    return '''ErrorEllipse:
  Semi-major axis: $_a
  Semi-minor axis: $_b
  Orientation angle: $_theta°
  Bearing: $_bearing°
  Sx (distance along x-axis): $_sx
  Sy (distance along y-axis): $_sy
  Area: $_area
  Confidence level: ${_confidenceLevel * 100}%
  Eccentricity: $_eccentricity
  Aspect ratio: $_aspectRatio''';
  }
}

void main() {
  /// Example usage of the ErrorEllipse class.
  var ellipse = ErrorEllipse(
    sigmaX2: 3.036546e-04,
    sigmaY2: 2.723551e-04,
    sigmaXY: -1.173078e-04,
  );

  print(ellipse.generateEllipsePoints(100, centerX: 100.0, centerY: 100.0));

  print(ellipse);
}
