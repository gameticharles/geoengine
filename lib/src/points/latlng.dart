part of '../../geoengine.dart';

/// Represents a geographical location using latitude and longitude coordinates.
///
/// This class extends `PointX` to provide additional functionalities specific
/// to geographical coordinates, including methods to work with different
/// coordinate formats and geospatial calculations.
class LatLng extends PointX implements lat_lng.LatLng {
  /// The elevation (in meters) of the point.
  final double? elevation;

  /// The longitude of the point. This is always in decimal degrees
  final double lat;

  /// The longitude of the point. This is always in decimal degrees.
  final double lng;

  static const double R = 6371000; // Earth radius in meters

  @override
  lat_lng.Angle get latitude => lat_lng.Angle.degree(lat);

  @override
  lat_lng.Angle get longitude => lat_lng.Angle.degree(lng);

  /// Creates a LatLng instance with specified latitude, longitude, and optional elevation.
  ///
  /// [latitude]: The latitude of the point in decimal degrees.
  /// [longitude]: The longitude of the point in decimal degrees.
  /// [elevation]: (Optional) The elevation of the point in meters.
  LatLng(this.lat, this.lng, [this.elevation])
      : assert(lat >= -90 && lat <= 90),
        assert(lng >= -180 && lng <= 180),
        super(y: lat, x: lng, z: elevation, type: CoordinateType.geodetic);

  /// Creates a LatLng instance from a Map containing latitude, longitude, and optional elevation.
  ///
  /// [map]: A Map containing 'latitude', 'longitude', and optionally 'elevation' keys.
  LatLng.fromMap(Map<dynamic, dynamic> map)
      : lat = map['latitude']!,
        lng = map['longitude']!,
        elevation = map['elevation'],
        super(
            y: map['latitude']!,
            x: map['longitude']!,
            z: map['elevation'],
            type: CoordinateType.geodetic);

  /// Creates a LatLng instance from a List containing latitude, longitude, and optional elevation.
  ///
  /// [list]: A List containing latitude and longitude as the first two elements,
  ///         and optionally elevation as the third element.
  LatLng.fromList(List<double> list)
      : assert(list.length >= 2),
        lat = list[0],
        lng = list[1],
        elevation = list.length == 3 ? list[2] : null,
        super(
          y: list[0],
          x: list[1],
          z: list.length == 3 ? list[2] : null,
          type: CoordinateType.geodetic,
        );

  /// Creates a LatLng instance from a string representation of coordinates (e.g.: "40.7128,-74.0060").
  ///
  /// [latLngAsString]: A string representing the coordinates in the format "latitude,longitude".
  LatLng.fromString(String latLngAsString)
      : assert(latLngAsString.split(',').length >= 2),
        lat = double.parse(latLngAsString.split(',')[0]),
        lng = double.parse(latLngAsString.split(',')[1]),
        elevation = latLngAsString.split(',').length == 3
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
  ///  ```dart
  /// final LatLng p1 = new LatLng.fromSexagesimal('''51° 31' 10.11" N, 19° 22' 32.00" W''');
  /// print("${p1.latitude}, ${p1.longitude}");
  /// // Shows:
  /// 51.519475, -19.37555556
  ///```
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
      latitude.degrees,
      isLat: true,
      isLatLon: true,
      decPlace: 3,
    )}, ${degree2DMSString(
      longitude.degrees,
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
        degrees2Seconds(longitude.degrees) / 15; // seconds before/behind GMT

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

  /// Calculates the midpoint between this point and another point.
  ///
  /// [point]: The other point to which the midpoint is calculated.
  /// Returns a new LatLng instance representing the midpoint.
  LatLng midPointTo(LatLng point) {
    double phi1 = latitude.radians, lon1 = longitude.radians;
    double phi2 = point.latitude.radians;
    double dLon = (point.longitude.degrees - longitude.degrees) * pi / 180;

    double bX = cos(phi2) * cos(dLon);
    double bY = cos(phi2) * sin(dLon);

    double phi3 = atan2(sin(phi1) + sin(phi2),
        sqrt((cos(phi1) + bX) * (cos(phi1) + bX) + bY * bY));
    double lon3 = lon1 + atan2(bY, cos(phi1) + bX);

    double lat3 = phi3 * 180 / pi;
    lon3 = lon3 * 180 / pi;

    return LatLng(lat3, lon3);
  }

  /// Finds the intersection point of two paths defined by a point and a bearing.
  ///
  /// [point1]: The first point.
  /// [bearing1]: The bearing from the first point.
  /// [point2]: The second point.
  /// [bearing1]: The bearing from the second point.
  /// Returns a LatLng representing the intersection point, or null if no unique intersection is found.
  static LatLng? intersectionPoint(
      LatLng point1, double bearing1, LatLng point2, double bearing2) {
    double lat1 = point1.latitude.radians;
    double lon1 = point1.longitude.radians;
    double lat2 = point2.latitude.radians;
    double lon2 = point2.longitude.radians;
    double theta13 = toRadians(bearing1);
    double theta23 = toRadians(bearing2);

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

    lat3 = toDegrees(lat3);
    lon3 = toDegrees(lon3);

    return LatLng(lat3, lon3);
  }

  /// Calculates the distance to another point using a specified method.
  ///
  /// [point]: The point to which the distance is calculated.
  /// [method]: The method used for distance calculation, defaulting to Haversine.
  /// Returns the calculated distance as a Length object.
  Length? distanceTo(LatLng point,
      {DistanceMethod method = DistanceMethod.haversine}) {
    switch (method) {
      case DistanceMethod.haversine:
        return Distance.haversine(this, point);
      case DistanceMethod.greatCircle:
        return Distance.greatCircle(this, point);
      case DistanceMethod.vincenty:
        return Distance.vincenty(this, point);
    }
  }

  /// Calculates the initial bearing from this point to another point.
  ///
  /// [point]: The point to which the bearing is calculated.
  /// Returns the initial bearing as a Bearing object.
  Bearing initialBearingTo(LatLng point) {
    return Bearing.initialBearing(this, point);
  }

  /// Calculates the final bearing from this point to another point.
  ///
  /// [point]: The point from which the final bearing is calculated.
  /// Returns the final bearing as a Bearing object.
  Bearing finalBearingTo(LatLng point) {
    return Bearing.finalBearing(this, point);
  }

  /// Calculates the destination point given a distance and bearing from this point.
  ///
  /// [distance]: The distance to the destination point.
  /// [bearing]: The bearing to the destination point.
  /// Returns a new LatLng instance representing the destination point.
  LatLng destinationPoint(double distance, double bearing) {
    double phi1 = latitude.radians;
    double lambda1 = longitude.radians;
    double theta = toRadians(bearing);
    double delta = distance / R;

    double phi2 =
        asin(sin(phi1) * cos(delta) + cos(phi1) * sin(delta) * cos(theta));
    double lambda2 = lambda1 +
        atan2(sin(theta) * sin(delta) * cos(phi1),
            cos(delta) - sin(phi1) * sin(phi2));

    return LatLng(toDegrees(phi2), toDegrees(lambda2));
  }

  /// Calculates the destination point using rhumb line navigation given a distance and bearing from this point.
  ///
  /// [distance]: The distance to the destination point.
  /// [bearing]: The bearing to the destination point.
  /// Returns a new LatLng instance representing the destination point.
  LatLng rhumbDestinationPoint(double distance, double bearing) {
    double phi1 = latitude.radians;
    double lambda1 = longitude.radians;
    double theta = toRadians(bearing);

    double delta = distance / R;
    double deltaPhi = delta * cos(theta);
    double phi2 = phi1 + deltaPhi;

    double deltaPsi = log(tan(pi / 4 + phi2 / 2) / tan(pi / 4 + phi1 / 2));
    double q = (deltaPsi.abs() > 1e-12) ? deltaPhi / deltaPsi : cos(phi1);

    double deltaLambda = delta * sin(theta) / q;
    double lambda2 = lambda1 + deltaLambda;

    return LatLng(toDegrees(phi2), toDegrees(lambda2));
  }

  /// Calculates the rhumb line distance to another point.
  ///
  /// Rhumb lines are straight lines on a Mercator projection map, making this
  /// method useful for navigation purposes.
  ///
  /// [point]: The other point to which the rhumb line distance is calculated.
  /// Returns the distance as a Length object.
  Length rhumbLineDistance(LatLng point) {
    double phi1 = latitude.radians;
    double phi2 = point.latitude.radians;
    double deltaPhi = phi2 - phi1;
    double lambda1 = longitude.radians;
    double lambda2 = point.longitude.radians;
    double deltaLambda = lambda2 - lambda1;

    double deltaPsi = log(tan(pi / 4 + phi2 / 2) / tan(pi / 4 + phi1 / 2));
    double q = (deltaPsi.abs() > 1e-12) ? deltaPhi / deltaPsi : cos(phi1);

    double d =
        sqrt(deltaPhi * deltaPhi + q * q * deltaLambda * deltaLambda) * R;
    return Length(m: d);
  }

  /// Calculates the rhumb line bearing to another point.
  ///
  /// This bearing is constant between any two points along the rhumb line.
  ///
  /// [point]: The other point to which the rhumb line bearing is calculated.
  /// Returns the bearing as a Bearing object.
  Bearing rhumbLineBearing(LatLng point) {
    double phi1 = latitude.radians;
    double phi2 = point.latitude.radians;
    double lambda1 = longitude.radians;
    double lambda2 = point.longitude.radians;
    double deltaLambda = lambda2 - lambda1;

    double deltaPsi = log(tan(pi / 4 + phi2 / 2) / tan(pi / 4 + phi1 / 2));
    double theta = atan2(deltaLambda, deltaPsi) * 180 / pi;

    return Bearing((theta + 360) % 360);
  }

  /// Calculates the midpoint along a rhumb line between this point and another point.
  ///
  /// [point]: The other point to which the midpoint is calculated.
  /// Returns a new LatLng instance representing the midpoint.
  LatLng rhumbMidpoint(LatLng point) {
    double phi1 = latitude.radians;
    double phi2 = point.latitude.radians;
    double lambda1 = longitude.radians;
    double lambda2 = point.longitude.radians;

    double phiM = (phi1 + phi2) / 2;
    double f1 = tan(pi / 4 + phi1 / 2);
    double f2 = tan(pi / 4 + phi2 / 2);
    double fM = tan(pi / 4 + phiM / 2);

    double lambdaM = ((lambda2 - lambda1) * log(fM) +
            lambda1 * log(f2) -
            lambda2 * log(f1)) /
        log(f2 / f1);

    return LatLng(toDegrees(phiM), toDegrees(lambdaM));
  }

  /// Calculates the cross-track distance to the great-circle path between two points.
  ///
  /// This is the shortest distance between a point and a great-circle path.
  ///
  /// [point1]: The start point of the great-circle path.
  /// [point2]: The end point of the great-circle path.
  /// Returns the cross-track distance as a Length object.
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

  /// Calculates the along-track distance to the closest point on the great-circle path between two points.
  ///
  /// This is the distance along the great-circle path to the closest point from the third point.
  ///
  /// [point1]: The start point of the great-circle path.
  /// [point2]: The end point of the great-circle path.
  /// Returns the along-track distance as a Length object.
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

  /// Converts the LatLng instance to a Wpt (Waypoint) object.
  ///
  /// Transfers the geographical coordinates and descriptive information to a Wpt instance.
  /// Returns the Wpt object with the properties of this LatLng instance.
  Wpt toWPT() {
    var wpt = Wpt();
    wpt.desc = desc;
    wpt.name = name;
    wpt.lat = latitude.degrees;
    wpt.lon = longitude.degrees;
    wpt.ele = elevation;

    //wpt.src = crs!.projName;

    return wpt;
  }

  /// Convert MGRS to lat/lon.
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
          mgrs_dart.Mgrs.forward(
              [longitude.degrees, latitude.degrees], accuracy),
        )
        .toString();
  }

  /// Return the Latitude and Longitude to UTM coordinates
  UTM toUTM() {
    var utm = mgrs_dart.Mgrs.LLtoUTM(latitude.degrees, longitude.degrees);

    return UTM(
      zoneNumber: utm.zoneNumber,
      zoneLetter: utm.zoneLetter,
      easting: utm.easting,
      northing: utm.northing,
      height: 0,
      accuracy: utm.accuracy,
    );
  }

  @override
  String toString() {
    return toSexagesimal() +
        (elevation != null ? ', ${elevation!.toStringAsFixed(3)}' : "");
  }
}
