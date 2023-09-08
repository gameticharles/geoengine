part of geoengine;

class UTM extends PointX {
  final String zoneLetter;
  final int zoneNumber;
  int? accuracy;

  LatLng? _latLng;
  Projection? _utmProjection;
  UTM(this.zoneNumber, this.zoneLetter, double easting, double northing,
      [double? height, this.accuracy])
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

  /// Returns the Projected coordinate system of the current coordinate.
  Projection get utmProjection => _utmProjection ??=
      CoordinateConversion().getUTMProjection(latLng.longitude);

  /// Convert the UTM coordinate system to Latitude and Longitude
  LatLng toLatLng() {
    // return LatLng(res.y, res.x, res.z);
    var ll = mgrs_dart.Mgrs.UTMtoLL(mgrs_dart.UTM(
        easting: easting,
        northing: northing,
        zoneLetter: zoneLetter,
        zoneNumber: zoneNumber));
    return LatLng(ll.lat, ll.lon);
  }

  /// Convert MGRS to UTM coordinates
  ///
  /// [mgrsString]: UPPERCASE coordinate string is expected in MGRS
  /// Return an object literal with easting, northing, zoneLetter, zoneNumber and accuracy (in meters) properties
  factory UTM.fromMGRS(String mgrsString) {
    var utm = mgrs_dart.Mgrs.decode(mgrsString);
    return UTM(
      utm.zoneNumber,
      utm.zoneLetter,
      utm.easting,
      utm.northing,
      0,
      utm.accuracy,
    );
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
