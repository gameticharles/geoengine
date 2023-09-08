part of geoengine;

class LatLng extends PointX {
  final double latitude;
  final double longitude;
  final double? height;

  static const double R = 6371000; // Earth radius in meters

  /// Default constructor
  LatLng(this.latitude, this.longitude, [this.height])
      : assert(latitude >= -90 && latitude <= 90),
        assert(longitude >= -180 && longitude <= 180),
        super(
            y: latitude,
            x: longitude,
            z: height,
            type: CoordinateType.geodetic);

  /// Named constructor that creates a LatLng from a Map
  LatLng.fromMap(Map<String, double> map)
      : latitude = map['latitude']!,
        longitude = map['longitude']!,
        height = map['height']!,
        super(
            y: map['latitude']!,
            x: map['longitude']!,
            z: map['height']!,
            type: CoordinateType.geodetic);

  /// Named constructor that creates a LatLng from a List
  LatLng.fromList(List<double> list)
      : assert(list.length >= 2),
        latitude = list[0],
        longitude = list[1],
        height = list.length == 3 ? list[2] : null,
        super(
          y: list[0],
          x: list[1],
          z: list.length == 3 ? list[2] : null,
          type: CoordinateType.geodetic,
        );

  /// Named constructor that creates a LatLng from a string (e.g., "40.7128,-74.0060")
  LatLng.fromString(String latLngAsString)
      : assert(latLngAsString.split(',').length >= 2),
        latitude = double.parse(latLngAsString.split(',')[0]),
        longitude = double.parse(latLngAsString.split(',')[1]),
        height = latLngAsString.split(',').length == 3
            ? double.parse(latLngAsString.split(',')[2])
            : null,
        super(
          y: double.parse(latLngAsString.split(',')[0]),
          x: double.parse(latLngAsString.split(',')[1]),
          z: latLngAsString.split(',').length == 3
              ? double.parse(latLngAsString.split(',')[2])
              : null,
          type: CoordinateType.geodetic,
        );

  /// Converts sexagesimal string into a lat/long value
  ///
  ///     final LatLng p1 = new LatLng.fromSexagesimal('''51° 31' 10.11" N, 19° 22' 32.00" W''');
  ///     print("${p1.latitude}, ${p1.longitude}");
  ///     // Shows:
  ///     51.519475, -19.37555556
  ///
  factory LatLng.fromSexagesimal(String sexagesimal) {
    double latitude = 0.0;
    double longitude = 0.0;

    // try format '''47° 09' 53.57" N, 8° 32' 09.04" E'''
    var splits = sexagesimal.split(',');
    if (splits.length != 2) {
      // try format '''N 47°08'52.57" E 8°32'09.04"'''
      splits = sexagesimal.split('E');
      if (splits.length != 2) {
        // try format '''N 47°08'52.57" W 8°32'09.04"'''
        splits = sexagesimal.split('W');
        if (splits.length != 2) {
          throw 'Unsupported sexagesimal format: $sexagesimal';
        }
      }
    }

    latitude = _sexagesimalToDecimal(splits[0]);
    longitude = _sexagesimalToDecimal(splits[1]);

    return LatLng(latitude, longitude);
  }

  // Converts latitude and longitude to sexagesimal
  ///
  ///     final LatLng p1 = new LatLng(51.519475, -19.37555556);
  ///
  ///     // Shows: 51° 31' 10.11" N, 19° 22' 32.00" W
  ///     print(p1..toSexagesimal());
  ///
  String toSexagesimal({int decPlaces = 3}) {
    return '${degree2DMSString(
      latitude,
      isLat: true,
      isLatLon: true,
      decPlace: 3,
    )}, ${degree2DMSString(
      longitude,
      isLat: false,
      isLatLon: true,
      decPlace: 3,
    )}';
  }

  /// Convert LatLong to timezone
  ///
  /// Example:
  /// ```
  /// final LatLng pp = LatLng(6.65412, -1.54651);
  /// var timeZone = pp.toTimeZone() // [0, 6, 11.162400000000012] HH,MM,SS
  /// ```
  List<num> toTimeZone() {
    // Converting this all to seconds of longitude gives:

    // Now we find the time zone difference in seconds of time:
    var longInSec =
        degrees2Seconds(longitude) / 15; // seconds before/behind GMT

    // Convert to HH:MM:SS.
    var newTime = degree2DMS(longInSec / 3600);
//'${newTime[0] > 0 ? '+' : '-'}${newTime[0].abs().toString().padLeft(2, '0')}:${newTime[1].toString().padLeft(2, '0')}';
    return newTime;
  }

  @override
  int get hashCode => latitude.hashCode + longitude.hashCode;

  @override
  bool operator ==(final Object other) =>
      other is LatLng &&
      latitude == other.latitude &&
      longitude == other.longitude;

  // Helper function to convert sexagesimal to decimal
  static double _sexagesimalToDecimal(String sexagesimal) {
    final parts = sexagesimal
        .trim()
        .split(RegExp('[°\'"]'))
        .where((part) => part.isNotEmpty)
        .toList();
    double decimal = double.parse(parts[0].trim()) +
        double.parse(parts[1].trim()) / 60 +
        double.parse(parts[2].trim()) / 3600;
    if (sexagesimal.toUpperCase().contains('S') ||
        sexagesimal.toUpperCase().contains('W')) {
      decimal = -decimal;
    }

    return decimal;
  }

  /// Convert MGRS to lat/lon.
  ///
  ///
  /// [mgrsString]: UPPERCASE coordinate string is expected in MGRS
  /// Return an object literal with easting, northing, zoneLetter, zoneNumber and accuracy (in meters) properties
  static fromMGRS(String mgrsString) {
    var ll = mgrs_dart.Mgrs.toPoint(mgrsString);
    return LatLng(ll[1], ll[0]);
  }

  /// Convert lat/lon to MGRS.
  ///
  /// [accuracy] Accuracy in digits (0-5). Accuracy in digits (5 for 1 m, 4 for 10 m, 3 for
  ///  100 m, 2 for 1 km, 1 for 10 km or 0 for 100 km). Optional, default is 5.
  ///
  /// Returns MGRS string for the given location and accuracy
  @override
  String toMGRS([int accuracy = 5]) {
    return MGRS
        .parse(
          mgrs_dart.Mgrs.forward([longitude, latitude], accuracy),
        )
        .toString();
  }

  LatLng midPointTo(LatLng point) {
    double phi1 = latitude * pi / 180, lon1 = longitude * pi / 180;
    double phi2 = point.latitude * pi / 180;
    double dLon = (point.longitude - longitude) * pi / 180;

    double bX = cos(phi2) * cos(dLon);
    double bY = cos(phi2) * sin(dLon);

    double phi3 = atan2(sin(phi1) + sin(phi2),
        sqrt((cos(phi1) + bX) * (cos(phi1) + bX) + bY * bY));
    double lon3 = lon1 + atan2(bY, cos(phi1) + bX);

    double lat3 = phi3 * 180 / pi;
    lon3 = lon3 * 180 / pi;

    return LatLng(lat3, lon3);
  }

  static LatLng? intersectionPoint(
      LatLng point1, double brng1, LatLng point2, double brng2) {
    double lat1 = point1.latitude * pi / 180;
    double lon1 = point1.longitude * pi / 180;
    double lat2 = point2.latitude * pi / 180;
    double lon2 = point2.longitude * pi / 180;
    double theta13 = brng1 * pi / 180;
    double theta23 = brng2 * pi / 180;

    double deltaLat = lat2 - lat1;
    double deltaLon = lon2 - lon1;

    // Angular distance between points
    num delta12 = 2 *
        asin(sqrt(pow(sin(deltaLat / 2), 2) +
            cos(lat1) * cos(lat2) * pow(sin(deltaLon / 2), 2)));

    double thetaA = acos(
        (sin(lat2) - sin(lat1) * cos(delta12)) / (sin(delta12) * cos(lat1)));
    double thetaB = acos(
        (sin(lat1) - sin(lat2) * cos(delta12)) / (sin(delta12) * cos(lat2)));

    double theta12, theta21;

    if (sin(lon2 - lon1) > 0) {
      theta12 = thetaA;
      theta21 = 2 * pi - thetaB;
    } else {
      theta12 = 2 * pi - thetaA;
      theta21 = thetaB;
    }

    double alpha1 = (theta13 - theta12 + pi) % (2 * pi) - pi;
    double alpha2 = (theta21 - theta23 + pi) % (2 * pi) - pi;

    if (alpha1 == 0 && alpha2 == 0) return null; // infinite solutions
    if (sin(alpha1) * sin(alpha2) < 0) return null; // ambiguous solution

    double alpha3 = acos(
        -cos(alpha1) * cos(alpha2) + sin(alpha1) * sin(alpha2) * cos(delta12));
    double delta13 = atan2(sin(delta12) * sin(alpha1) * sin(alpha2),
        cos(alpha2) + cos(alpha1) * cos(alpha3));

    double lat3 = asin(
        sin(lat1) * cos(delta13) + cos(lat1) * sin(delta13) * cos(theta13));
    double deltaLon13 = atan2(sin(theta13) * sin(delta13) * cos(lat1),
        cos(delta13) - sin(lat1) * sin(lat3));
    double lon3 = lon1 + deltaLon13;

    lat3 = lat3 * 180 / pi;
    lon3 = lon3 * 180 / pi;

    return LatLng(lat3, lon3);
  }

  Length? distanceTo(LatLng point,
      {DistanceMethod method = DistanceMethod.haversine}) {
    switch (method) {
      case DistanceMethod.haversine:
        return Distance.haversine(this, point);
      case DistanceMethod.greatCircle:
        return Distance.greatCircle(this, point);
      case DistanceMethod.vincenty:
        return Distance.vincenty(this, point);
      default:
        throw Exception('Unknown distance calculation method: $method');
    }
  }

  Bearing initialBearingTo(LatLng point) {
    return Bearing.initialBearing(this, point);
  }

  Bearing finalBearingTo(LatLng point) {
    return Bearing.finalBearing(this, point);
  }

  // Destination point given distance and bearing from start point
  LatLng destinationPoint(double distance, double bearing) {
    double phi1 = latitude * pi / 180;
    double lambda1 = longitude * pi / 180;
    double theta = bearing * pi / 180;
    double delta = distance / R;

    double phi2 =
        asin(sin(phi1) * cos(delta) + cos(phi1) * sin(delta) * cos(theta));
    double lambda2 = lambda1 +
        atan2(sin(theta) * sin(delta) * cos(phi1),
            cos(delta) - sin(phi1) * sin(phi2));

    return LatLng(phi2 * 180 / pi, lambda2 * 180 / pi);
  }

  // Calculate destination point given distance and bearing
  LatLng rhumbDestinationPoint(double distance, double bearing) {
    double phi1 = latitude * pi / 180;
    double lambda1 = longitude * pi / 180;
    double theta = bearing * pi / 180;

    double delta = distance / R;
    double deltaPhi = delta * cos(theta);
    double phi2 = phi1 + deltaPhi;

    double deltaPsi = log(tan(pi / 4 + phi2 / 2) / tan(pi / 4 + phi1 / 2));
    double q = (deltaPsi.abs() > 1e-12) ? deltaPhi / deltaPsi : cos(phi1);

    double deltaLambda = delta * sin(theta) / q;
    double lambda2 = lambda1 + deltaLambda;

    return LatLng(phi2 * 180 / pi, lambda2 * 180 / pi);
  }

  // Calculate rhumb line distance between two points
  Length rhumbLineDistance(LatLng point) {
    double phi1 = latitude * pi / 180;
    double phi2 = point.latitude * pi / 180;
    double deltaPhi = phi2 - phi1;
    double lambda1 = longitude * pi / 180;
    double lambda2 = point.longitude * pi / 180;
    double deltaLambda = lambda2 - lambda1;

    double deltaPsi = log(tan(pi / 4 + phi2 / 2) / tan(pi / 4 + phi1 / 2));
    double q = (deltaPsi.abs() > 1e-12) ? deltaPhi / deltaPsi : cos(phi1);

    double d =
        sqrt(deltaPhi * deltaPhi + q * q * deltaLambda * deltaLambda) * R;
    return Length(m: d);
  }

  // Calculate rhumb line bearing between two points
  Bearing rhumbLineBearing(LatLng point) {
    double phi1 = latitude * pi / 180;
    double phi2 = point.latitude * pi / 180;
    double lambda1 = longitude * pi / 180;
    double lambda2 = point.longitude * pi / 180;
    double deltaLambda = lambda2 - lambda1;

    double deltaPsi = log(tan(pi / 4 + phi2 / 2) / tan(pi / 4 + phi1 / 2));
    double theta = atan2(deltaLambda, deltaPsi) * 180 / pi;

    return Bearing((theta + 360) % 360);
  }

  // Calculate midpoint between two points along a rhumb line
  LatLng rhumbMidpoint(LatLng point) {
    double phi1 = latitude * pi / 180;
    double phi2 = point.latitude * pi / 180;
    double lambda1 = longitude * pi / 180;
    double lambda2 = point.longitude * pi / 180;

    double phiM = (phi1 + phi2) / 2;
    double f1 = tan(pi / 4 + phi1 / 2);
    double f2 = tan(pi / 4 + phi2 / 2);
    double fM = tan(pi / 4 + phiM / 2);

    double lambdaM = ((lambda2 - lambda1) * log(fM) +
            lambda1 * log(f2) -
            lambda2 * log(f1)) /
        log(f2 / f1);

    return LatLng(phiM * 180 / pi, lambdaM * 180 / pi);
  }

  // Calculate the cross-track distance to the great-circle path between point1 and point2
  Length crossTrackDistanceTo(LatLng point1, LatLng point2) {
    var delta13 =
        Distance.shortestPath(point1, this)!.valueInUnits(LengthUnits.meters) /
            R; // angular distance
    var theta13 = Bearing.initialBearing(point1, this)
        .rad; // initial bearing from point1 to third point
    var theta12 = Bearing.initialBearing(point1, point2)
        .rad; // initial bearing from point1 to point2

    double dXt = asin(sin(delta13.toDouble()) * sin(theta13 - theta12)) * R;
    return Length(m: dXt);
  }

  // Calculate the along-track distance to the point closest to the third point on the great-circle path between point1 and point2
  Length alongTrackDistanceTo(LatLng point1, LatLng point2) {
    var delta13 =
        Distance.shortestPath(point1, this)!.valueInUnits(LengthUnits.meters) /
            R; // angular distance
    var dXt = crossTrackDistanceTo(point1, point2);
    double deltaXt = dXt.valueInUnits(LengthUnits.meters).toDouble() /
        R; // angular cross-track distance

    double dAt = acos(cos(delta13.toDouble()) / cos(deltaXt)) * R;
    return Length(m: dAt);
  }

  Wpt toWPT() {
    var wpt = Wpt();
    wpt.desc = desc;
    wpt.name = name;
    wpt.lat = y;
    wpt.lon = x;
    wpt.ele = z;

    //wpt.src = crs!.projName;

    return wpt;
  }

  /// Return the Latitude and Longitude to UTM coordinates
  UTM toUTM() {
    var utm = mgrs_dart.Mgrs.LLtoUTM(latitude, longitude);

    return UTM(
      utm.zoneNumber,
      utm.zoneLetter,
      utm.easting,
      utm.northing,
      0,
      utm.accuracy,
    );
  }

  @override
  String toString() {
    return toSexagesimal() +
        (height != null ? ', ${height!.toStringAsFixed(3)}' : "");
  }
}
