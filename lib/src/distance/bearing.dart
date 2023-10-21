part of geoengine;

/// Represents the bearing (direction) between two points, measured in degrees from the North.
///
/// This class extends the `Angle` class and provides functionality
/// for computing the forward and backward bearings between two geographical points
/// or simple 2D/3D points.
///
/// Bearing can be calculated using multiple methods:
/// - Initial Bearing: the direction you initially need to travel from the start point to the end point.
/// - Final Bearing: the direction you'd be traveling if you started at the end point and moved to the start point.
///
/// Example 1:
/// ```dart
/// var bear = Bearing(120);
/// var backBearing = bear.backwardBearing();
/// var trueBearing = bear.trueBearing();
/// var magBearing = bear.magneticBearing();
/// ```
///
/// Example 2:
/// ```dart
/// var point1 = LatLng(34.0, -118.0);
/// var point2 = LatLng(36.0, -116.0);
/// var bearing = Bearing.forwardBearing(point1, point2);
///
/// print(bearing);  // e.g. Bearing: 55.0°
///
/// var fb = bearing.forwardBearing;  // forward bearing is essentially the initial bearing
/// var bb = bearing.backBearing;
///
/// ```
class Bearing extends Angle {
  final double _degrees;
  final Point? point1;
  final Point? point2;

  /// Example magnetic declination. In a real-world scenario, this would be fetched
  /// dynamically based on the location and the current date.
  static const double magneticDeclination = 10.0; // example value in degrees

  /// Create a new instance of [Bearing].
  ///
  /// Takes the bearing value in degrees.
  Bearing(this._degrees)
      : point1 = null,
        point2 = null,
        super(deg: _degrees);

  Bearing.fromPoints(Point p1, Point p2)
      : point1 = p1,
        point2 = p2,
        _degrees = initialBearing(p1, p2)._degrees,
        super(deg: initialBearing(p1, p2)._degrees);

  /// Compute the forward (initial) bearing.
  double get forwardBearing => _degrees;

  /// Compute the backward (final) bearing.
  double get backBearing => (_degrees + 180) % 360;

  /// Converts the forward bearing from true north to magnetic north.
  double get magneticBearing => (_degrees + magneticDeclination + 360) % 360;

  /// Converts the forward bearing from magnetic north to true north.
  double get trueBearing => (_degrees - magneticDeclination + 360) % 360;

  Point? get firstPoint => point1;
  Point? get secondPoint => point2;

  /// Validate the LatLng value
  static void _validatePoint(Point point) {
    if (point is LatLng) {
      if (point.latitude < -90 || point.latitude > 90) {
        throw ArgumentError('Latitude must be between -90 and 90 degrees.');
      }
      if (point.longitude < -180 || point.longitude > 180) {
        throw ArgumentError('Longitude must be between -180 and 180 degrees.');
      }
    }
  }

  /// Computes the initial bearing between two points.
  ///
  /// This method takes into consideration whether the points are geographical
  /// (represented as `LatLng`) or simple 2D/3D points (represented as `Point`).
  ///
  /// - Parameters:
  ///   - [point1]: The starting point.
  ///   - [point2]: The destination point.
  ///
  /// @return The initial bearing value.
  static Bearing initialBearing(Point point1, Point point2) {
    double x, y;

    _validatePoint(point1);
    _validatePoint(point2);

    if (point1 is LatLng && point2 is LatLng) {
      double lat1 = toRadians(point1.latitude);
      double lon1 = toRadians(point1.longitude);
      double lat2 = toRadians(point2.latitude);
      double lon2 = toRadians(point2.longitude);

      double dLon = lon2 - lon1;

      x = cos(lat2) * sin(dLon);
      y = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(dLon);
    } else {
      x = point2.x - point1.x;
      y = point2.y - point1.y;
    }

    double initialBearing = atan2(x, y);
    initialBearing = (toDegrees(initialBearing) + 360) % 360;

    return Bearing(initialBearing);
  }

  /// Computes the final bearing between two points.
  ///
  /// The final bearing is simply the initial bearing from the destination point
  /// back to the start point reversed by 180 degrees.
  ///
  /// - Parameters:
  ///   - [point1]: The starting point.
  ///   - [point2]: The destination point.
  ///
  /// @return The final bearing value.
  static Bearing finalBearing(Point point1, Point point2) {
    // Final bearing is simply the initial bearing from point2 to point1 reversed by 180 degrees
    var initial = initialBearing(point2, point1);
    return Bearing((initial.deg + 180) % 360);
  }

  @override
  String toString() {
    return super.toString().replaceAll('Angle: ', 'Bearing: ');
  }
}
