part of '../../geoengine.dart';

/// Calculates geodetic distance between two [LatLng] points using
/// various algorithms.
class Distance extends Length {
  /// The radius of Earth in meters.
  static double R = 6371000; // Earth radius in meters

  /// Calculates the distance between two points using the Haversine formula.
  ///
  /// This is the simplest formula and less accurate than Vincenty formula.
  ///
  /// [point1] The first point.
  /// [point2] The second point.
  ///
  /// Returns the [Length] between points.
  static Length haversine(LatLng point1, LatLng point2) {
    double lat1 = point1.latitude.radians;
    double lon1 = point1.longitude.radians;
    double lat2 = point2.latitude.radians;
    double lon2 = point2.longitude.radians;

    double dlat = lat2 - lat1;
    double dlon = lon2 - lon1;

    double a =
        pow(sin(dlat / 2), 2) + cos(lat1) * cos(lat2) * pow(sin(dlon / 2), 2);
    num c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return Length(m: R * c);
  }

  /// Calculates the great circle distance between two points using spherical
  /// law of cosines formula.
  ///
  /// This method is less accurate than Vincenty formula.
  ///
  /// [point1] The first point.
  /// [point2] The second point.
  ///
  /// Returns the [Length] between points.
  static Length greatCircle(LatLng point1, LatLng point2) {
    double lat1 = point1.latitude.radians;
    double lon1 = point1.longitude.radians;
    double lat2 = point2.latitude.radians;
    double lon2 = point2.longitude.radians;

    return Length(
        m: acos(sin(lat1) * sin(lat2) +
                cos(lat1) * cos(lat2) * cos(lon2 - lon1)) *
            R);
  }

  /// Calculates the shortest distance between two points using
  /// Vincenty inverse formula.
  ///
  /// This is the most accurate distance calculation.
  ///
  /// [point1] The first point.
  /// [point2] The second point.
  ///
  /// Returns the [Length] between points.
  static Length? shortestPath(LatLng point1, LatLng point2) {
    return vincenty(point1, point2); // Assuming Vincenty is the most accurate
  }

  /// Calculates the geodesic distance between two points using
  /// Vincenty inverse formula.
  ///
  /// [point1] The first point.
  /// [point2] The second point.
  /// [ellipsoid] The ellipsoid model to use. Defaults to WGS84.
  ///
  /// Returns the [Length] between points.
  static Length? vincenty(LatLng point1, LatLng point2,
      {Ellipsoid? ellipsoid}) {
    ellipsoid ??= Ellipsoid.wgs84;
    double a = ellipsoid.a, b = ellipsoid.b, f = ellipsoid.f;

    double lat1 = point1.latitude.radians;
    double lon1 = point1.longitude.radians;
    double lat2 = point2.latitude.radians;
    double lon2 = point2.longitude.radians;

    double u1 = atan((1 - f) * tan(lat1));
    double u2 = atan((1 - f) * tan(lat2));

    double sinU1 = sin(u1), cosU1 = cos(u1);
    double sinU2 = sin(u2), cosU2 = cos(u2);

    double lambda = lon2 - lon1, lambdaP, sinLambda, cosLambda;
    double sinSigma, cosSigma, sigma, sinAlpha, cos2Alpha, cos2SigmaM, C;

    int iterLimit = 100;
    do {
      sinLambda = sin(lambda);
      cosLambda = cos(lambda);
      sinSigma = sqrt((cosU2 * sinLambda) * (cosU2 * sinLambda) +
          (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda) *
              (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda));
      cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
      sigma = atan2(sinSigma, cosSigma);
      sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
      cos2Alpha = 1 - sinAlpha * sinAlpha;
      cos2SigmaM = cosSigma - 2 * sinU1 * sinU2 / cos2Alpha;
      C = f / 16 * cos2Alpha * (4 + f * (4 - 3 * cos2Alpha));
      lambdaP = lambda;
      lambda = lon2 -
          lon1 +
          (1 - C) *
              f *
              sinAlpha *
              (sigma +
                  C *
                      sinSigma *
                      (cos2SigmaM +
                          C * cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM)));
    } while ((lambda - lambdaP).abs() > 1e-12 && --iterLimit > 0);

    if (iterLimit == 0) return null; // formula failed to converge

    double uSquared = cos2Alpha * (a * a - b * b) / (b * b);
    double A = 1 +
        uSquared /
            16384 *
            (4096 + uSquared * (-768 + uSquared * (320 - 175 * uSquared)));
    double B = uSquared /
        1024 *
        (256 + uSquared * (-128 + uSquared * (74 - 47 * uSquared)));
    double deltaSigma = B *
        sinSigma *
        (cos2SigmaM +
            B /
                4 *
                (cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM) -
                    B /
                        6 *
                        cos2SigmaM *
                        (-3 + 4 * sinSigma * sinSigma) *
                        (-3 + 4 * cos2SigmaM * cos2SigmaM)));

    double s = b * A * (sigma - deltaSigma);

    return Length(m: s); // return distance in meters
  }

  /// Calculates the destination point given a start point, distance
  /// and initial bearing using Vincenty direct formula.
  ///
  /// [point] The start point.
  /// [distance] The distance to travel.
  /// [initialBearing] The initial bearing angle.
  /// [ellipsoid] The ellipsoid model to use. Defaults to WGS84.
  ///
  /// Returns the calculated [LatLng] destination point.
  LatLng vincentyDirect(LatLng point, double distance, double initialBearing,
      {Ellipsoid? ellipsoid}) {
    ellipsoid ??= Ellipsoid.wgs84;
    double a = ellipsoid.a, b = ellipsoid.b, f = ellipsoid.f;
    double s = distance;
    double alpha1 = toRadians(initialBearing);
    double sinAlpha1 = sin(alpha1);
    double cosAlpha1 = cos(alpha1);

    double tanU1 = (1 - f) * tan(point.latitude.radians);
    double cosU1 = 1 / sqrt((1 + tanU1 * tanU1));
    double sinU1 = tanU1 * cosU1;
    double sigma1 = atan2(tanU1, cosAlpha1);
    double sinAlpha = cosU1 * sinAlpha1;
    double cos2Alpha = 1 - sinAlpha * sinAlpha;
    double u2 = cos2Alpha * (a * a - b * b) / (b * b);
    double A = 1 + u2 / 16384 * (4096 + u2 * (-768 + u2 * (320 - 175 * u2)));
    double B = u2 / 1024 * (256 + u2 * (-128 + u2 * (74 - 47 * u2)));

    double sigma = s / (b * A), sigmaP = 2 * pi;
    double cos2SigmaM, sinSigma, cosSigma, deltaSigma;

    do {
      cos2SigmaM = cos(2 * sigma1 + sigma);
      sinSigma = sin(sigma);
      cosSigma = cos(sigma);
      deltaSigma = B *
          sinSigma *
          (cos2SigmaM +
              B /
                  4 *
                  (cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM) -
                      B /
                          6 *
                          cos2SigmaM *
                          (-3 + 4 * sinSigma * sinSigma) *
                          (-3 + 4 * cos2SigmaM * cos2SigmaM)));
      sigmaP = sigma;
      sigma = s / (b * A) + deltaSigma;
    } while ((sigma - sigmaP).abs() > 1e-12);

    double x = sinU1 * sinSigma - cosU1 * cosSigma * cosAlpha1;
    double phi2 = atan2(sinU1 * cosSigma + cosU1 * sinSigma * cosAlpha1,
        (1 - f) * sqrt(sinAlpha * sinAlpha + x * x));
    double lambda = atan2(
        sinSigma * sinAlpha1, cosU1 * cosSigma - sinU1 * sinSigma * cosAlpha1);
    double C = f / 16 * cos2Alpha * (4 + f * (4 - 3 * cos2Alpha));
    double L = lambda -
        (1 - C) *
            f *
            sinAlpha *
            (sigma +
                C *
                    sinSigma *
                    (cos2SigmaM +
                        C * cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM)));
    double lambda2 = point.longitude.radians + L;

    double finalBearing = atan2(sinAlpha, -x);
    finalBearing = (toDegrees(finalBearing) + 360) % 360;

    return LatLng(toDegrees(phi2), toDegrees(lambda2), finalBearing);
  }

  /// Calculates the inverse geodetic problem between two points using the Vincenty formula.
  ///
  /// Returns the distance between the two points and the forward and reverse azimuths.
  ///
  /// [point1] The start point.
  /// [point2] The end point.
  /// [ellipsoid] The ellipsoid to use for the calculation. Defaults to WGS84.
  ///
  /// Returns a list containing the distance, forward azimuth, and reverse azimuth,
  /// or null if the calculation fails to converge.
  List<double>? vincentyInverse(LatLng point1, LatLng point2,
      {Ellipsoid? ellipsoid}) {
    ellipsoid ??= Ellipsoid.wgs84;
    double a = ellipsoid.a, b = ellipsoid.b, f = ellipsoid.f;
    double phi1 = point1.latitude.radians;
    double lambda1 = point1.longitude.radians;
    double phi2 = point2.latitude.radians;
    double lambda2 = point2.longitude.radians;

    double u1 = atan((1 - f) * tan(phi1));
    double u2 = atan((1 - f) * tan(phi2));
    double sinU1 = sin(u1), cosU1 = cos(u1);
    double sinU2 = sin(u2), cosU2 = cos(u2);

    double lambda = lambda2 - lambda1;
    double L = lambda;
    double sinLambda, cosLambda;
    double sinSigma, cosSigma, sigma, sinAlpha, cos2Alpha, cos2SigmaM;
    double C, lambdaP; //sigmaP

    int iterLimit = 100;
    do {
      sinLambda = sin(lambda);
      cosLambda = cos(lambda);
      sinSigma = sqrt(cosU2 * sinLambda * cosU2 * sinLambda +
          (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda) *
              (cosU1 * sinU2 - sinU1 * cosU2 * cosLambda));
      cosSigma = sinU1 * sinU2 + cosU1 * cosU2 * cosLambda;
      sigma = atan2(sinSigma, cosSigma);
      sinAlpha = cosU1 * cosU2 * sinLambda / sinSigma;
      cos2Alpha = 1 - sinAlpha * sinAlpha;
      cos2SigmaM = cosSigma - 2 * sinU1 * sinU2 / cos2Alpha;
      C = f / 16 * cos2Alpha * (4 + f * (4 - 3 * cos2Alpha));
      lambdaP = lambda;
      lambda = L +
          (1 - C) *
              f *
              sinAlpha *
              (sigma +
                  C *
                      sinSigma *
                      (cos2SigmaM +
                          C * cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM)));
    } while ((lambda - lambdaP).abs() > 1e-12 && --iterLimit > 0);

    if (iterLimit == 0) return null;

    double uu2 = cos2Alpha * (a * a - b * b) / (b * b);
    double A =
        1 + uu2 / 16384 * (4096 + uu2 * (-768 + uu2 * (320 - 175 * uu2)));
    double B = uu2 / 1024 * (256 + uu2 * (-128 + uu2 * (74 - 47 * uu2)));
    double deltaSigma = B *
        sinSigma *
        (cos2SigmaM +
            B /
                4 *
                (cosSigma * (-1 + 2 * cos2SigmaM * cos2SigmaM) -
                    B /
                        6 *
                        cos2SigmaM *
                        (-3 + 4 * sinSigma * sinSigma) *
                        (-3 + 4 * cos2SigmaM * cos2SigmaM)));
    double s = b * A * (sigma - deltaSigma);

    double fwdAz = toDegrees(
        atan2(cosU2 * sinLambda, cosU1 * sinU2 - sinU1 * cosU2 * cosLambda));
    double revAz = toDegrees(
        atan2(cosU1 * sinLambda, -sinU1 * cosU2 + cosU1 * sinU2 * cosLambda));

    fwdAz = (fwdAz + 360) % 360;
    revAz = (revAz + 360) % 360;

    return [s, fwdAz, revAz];
  }

  /// Calculate the cross-track distance to the great-circle path between point1 and point2
  Length crossTrackDistanceTo(LatLng point1, LatLng point2, LatLng point3) {
    var delta13 =
        Distance.shortestPath(point1, point3)! / R; // angular distance
    var theta13 = Bearing.initialBearing(point1, point3)
        .rad; // initial bearing from point1 to third point

    var theta12 = Bearing.initialBearing(point1, point2)
        .rad; // initial bearing from point1 to point2

    double dXt = asin(sin(delta13) * sin(theta13 - theta12)) * R;
    return Length(m: dXt);
  }

  /// Calculate the along-track distance to the point closest to the third point on the great-circle path between point1 and point2
  Length alongTrackDistanceTo(LatLng point1, LatLng point2, LatLng point3) {
    var delta13 =
        Distance.shortestPath(point1, point3)! / R; // angular distance
    var dXt = crossTrackDistanceTo(point1, point2, point3);
    var deltaXt = dXt / R; // angular cross-track distance

    double dAt = acos(cos(delta13) / cos(deltaXt)) * R;
    return Length(m: dAt);
  }
}
