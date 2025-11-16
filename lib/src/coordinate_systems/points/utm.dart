part of 'points.dart';

/// Represents a point in the Universal Transverse Mercator (UTM) coordinate system.
///
/// This class extends PointX and is specifically designed for UTM coordinates,
/// with additional properties for zone information and conversion methods
/// to and from geodetic coordinates (latitude and longitude).
class UTM extends PointX {
  /// The UTM zone letter.
  final String zoneLetter;

  /// The UTM zone number.
  final int zoneNumber;

  /// The accuracy of the UTM coordinates, in meters.
  int? accuracy;

  LatLng? _latLng;
  Projection? _utmProjection;

  /// Constructs a UTM instance with specified zone information and coordinates.
  ///
  /// [zoneNumber]: The UTM zone number.
  /// [zoneLetter]: The UTM zone letter.
  /// [easting]: The easting component of the UTM coordinate.
  /// [northing]: The northing component of the UTM coordinate.
  /// [height]: The elevation component of the UTM coordinate (optional).
  /// [accuracy]: The accuracy of the UTM coordinate in meters (optional).
  UTM(
      {required this.zoneNumber,
      required this.zoneLetter,
      required double easting,
      required double northing,
      double? height,
      this.accuracy})
      : super(
          x: easting,
          y: northing,
          z: height,
          type: CoordinateType.projected,
        );

  /// Creates a UTM instance from latitude and longitude coordinates.
  ///
  /// [latLng]: The latitude and longitude coordinates.
  /// Returns a UTM instance representing the same location.
  factory UTM.fromLatLng(LatLng latLng) {
    return latLng.toUTM();
  }

  /// The easting component of the coordinate
  double get easting => x;

  /// The northing component of the coordinate
  double get northing => y;

  /// The height component of the coordinate
  double? get height => z;

  /// Get the geodetic representation of the UTM latitude and longitude
  LatLng get latLng => _latLng ??= toLatLng();

  /// Get the latitude zone letter based on the given latitude.
  String get latitudeZone => UTMZones().getLatZone(latLng.latitude.degrees);

  /// Get the UTM zone identifier based on the point.
  String get zone => UTMZones().getZone(
      latitude: latLng.latitude.degrees, longitude: latLng.longitude.degrees);

  /// Returns the UTM coordinate system of the current coordinate.
  Projection get utmProjection => _utmProjection ??=
      CoordinateConversion().getUTM84ProjectionFromZone(zoneNumber, zoneLetter);

  /// Converts the UTM coordinate to a LatLng (latitude and longitude) coordinate.
  ///
  /// This method performs a coordinate conversion from UTM to geodetic.
  /// Returns a LatLng instance representing the geodetic coordinates.
  LatLng toLatLng() {
    var ll = CoordinateConversion()
        .convert(
          point: this,
          projSrc: utmProjection,
          projDst: Projection.WGS84,
          conversion: ConversionType.projectedToGeodetic,
        )
        .asLatLng();

    if (accuracy != null) {
      var llTR = UTM(
        easting: easting + accuracy!,
        northing: northing + accuracy!,
        zoneLetter: zoneLetter,
        zoneNumber: zoneNumber,
        accuracy: null,
      ).toLatLng();

      return LatLng((llTR.latitude.degrees + ll.latitude.degrees) / 2,
          (llTR.longitude.degrees + ll.longitude.degrees) / 2);
    } else {
      return ll;
    }

    // var l = mgrs_dart.Mgrs.toPoint(toMGRS());
    // return LatLng(l[1], l[0], height);
  }

  /// Creates a UTM instance from an MGRS (Military Grid Reference System) string.
  ///
  /// Example
  ///```dart
  ///   var utm = UTM.fromMGRS('31U DQ 48251 11932');
  ///   print(utm); // 31 N 448251.0 5411932.0
  ///```
  /// [mgrsString]: UPPERCASE coordinate string is expected in MGRS
  /// Return an object literal with easting, northing, zoneLetter, zoneNumber and accuracy (in meters) properties
  factory UTM.fromMGRS(String mgrsString) {
    return MGRS.parse(mgrsString).toUTM();
  }

  /// UTM location as MGRS string.
  ///
  /// [accuracy] Accuracy in digits (0-5). Accuracy in digits (5 for 1 m, 4 for 10 m, 3 for
  ///  100 m, 2 for 1 km, 1 for 10 km or 0 for 100 km). Optional, default is 5.
  ///
  /// Return MGRS string for the given.
  @override
  String toMGRS([int accuracy = 5]) {
    return MGRS
        .parse(
          mgrs_dart.Mgrs.encode(
              mgrs_dart.UTM(
                  easting: easting,
                  northing: northing,
                  zoneLetter: zoneLetter,
                  zoneNumber: zoneNumber,
                  accuracy: accuracy),
              accuracy),
        )
        .toString();
  }

  /// Calculates the distance to another point using a specified method.
  ///
  /// [point]: The point to which the distance is calculated.
  /// Returns the calculated distance as a Length object.
  Length? distanceTo(UTM point) {
    return Length(
        m: sqrt(
      pow(easting - point.easting, 2) + pow(northing - point.northing, 2),
    ));
  }

  /// Returns a string representation of an UTM Coordinate.
  ///
  /// To distinguish from MGRS coordinate representations, space is included within the
  /// zone and the hemisphere.
  ///
  /// Example:
  /// ```
  /// var utm = UTM(31, 'N', 448000, 5411000).toString()
  /// // 31 N 448000 5411000
  /// ```
  @override
  String toString() {
    return '$zoneNumber $zoneLetter $x $y${z != null ? ' $z' : ''}';
  }
}
