part of geoengine;

class UTM extends PointX {
  final String zoneLetter;
  final int zoneNumber;
  int? accuracy;

  LatLng? _latLng;
  Projection? _utmProjection;
  UTM(
      {required this.zoneNumber,
      required this.zoneLetter,
      required double easting,
      required double northing,
      double? height,
      this.accuracy})
      : super(x: easting, y: northing, z: height);

  /// Create a UTM coordinate system from Latitude and longitude
  ///
  /// [latLng] - Latitude and longitude coordinates
  ///
  /// Returns a UTM coordinate system
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
  String get latitudeZone => UTMZones().getLatZone(latLng.latitude);

  /// Get the UTM zone identifier based on the point.
  String get zone => UTMZones()
      .getZone(latitude: latLng.latitude, longitude: latLng.longitude);

  /// Returns the UTM coordinate system of the current coordinate.
  Projection get utmProjection => _utmProjection ??=
      CoordinateConversion().getUTM84ProjectionFromZone(zoneNumber, zoneLetter);

  /// Convert the UTM coordinate system to Latitude and Longitude
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

      return LatLng((llTR.latitude + ll.latitude) / 2,
          (llTR.longitude + ll.longitude) / 2);
    } else {
      return ll;
    }

    // var l = mgrs_dart.Mgrs.toPoint(toMGRS());
    // return LatLng(l[1], l[0], height);
  }

  /// Convert MGRS to UTM coordinates
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
