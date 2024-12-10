part of '../astronomy.dart';

/// @brief Holds spherical coordinates: latitude, longitude, distance.
///
/// Spherical coordinates represent the location of
/// a point using two angles and a distance.
///
/// @property {number} lat       The latitude angle: -90..+90 degrees.
/// @property {number} lon       The longitude angle: 0..360 degrees.
/// @property {number} dist      Distance in AU.
class Spherical {
  double lat;
  double lon;
  double dist;

  Spherical(double lat, double lon, double dist)
      : lat = verifyNumber(lat),
        lon = verifyNumber(lon),
        dist = verifyNumber(dist);

  /// @brief Converts Cartesian coordinates to spherical coordinates.
  ///
  /// Given a Cartesian vector, returns latitude, longitude, and distance.
  ///
  /// @param {Vector} vector
  ///      Cartesian vector to be converted to spherical coordinates.
  ///
  /// @returns {Spherical}
  ///      Spherical coordinates that are equivalent to the given vector.
  static Spherical fromVector(AstroVector vector, String refraction1) {
    // Convert vector to spherical coordinates
    Spherical sphere = sphereFromVector(vector);

    // Toggle azimuth direction
    sphere.lon = toggleAzimuthDirection(sphere.lon);

    // Adjust latitude for refraction
    sphere.lat += refraction(refraction1, sphere.lat);

    return sphere;
  }

  /// @brief Converts Cartesian coordinates to spherical coordinates.
  ///
  /// Given a Cartesian vector, returns latitude, longitude, and distance.
  ///
  /// @param {Vector} vector
  ///      Cartesian vector to be converted to spherical coordinates.
  ///
  /// @returns {Spherical}
  ///      Spherical coordinates that are equivalent to the given vector.
  static Spherical sphereFromVector(AstroVector vector) {
    final xyproj = vector.x * vector.x + vector.y * vector.y;
    final dist = sqrt(xyproj + vector.z * vector.z);
    double lat, lon;

    if (xyproj == 0.0) {
      if (vector.z == 0.0) {
        throw 'Zero-length vector not allowed.';
      }
      lon = 0.0;
      lat = (vector.z < 0.0) ? -90.0 : 90.0;
    } else {
      lon = RAD2DEG * atan2(vector.y, vector.x);
      if (lon < 0.0) {
        lon += 360.0;
      }
      lat = RAD2DEG * atan2(vector.z, sqrt(xyproj));
    }

    return Spherical(lat, lon, dist);
  }
}

/// @brief Holds right ascension, declination, and distance of a celestial object.
///
/// @property {number} ra
///      Right ascension in sidereal hours: [0, 24).
///
/// @property {number} dec
///      Declination in degrees: [-90, +90].
///
/// @property {number} dist
///      Distance to the celestial object expressed in
///      <a href="https://en.wikipedia.org/wiki/Astronomical_unit">astronomical units</a> (AU).
///
/// @property {Vector} vec
///      The equatorial coordinates in cartesian form, using AU distance units.
///      x = direction of the March equinox,
///      y = direction of the June solstice,
///      z = north.
class EquatorialCoordinates {
  late double ra;
  late double dec;
  late double dist;
  late AstroVector vec;

  EquatorialCoordinates(double ra, double dec, double dist, this.vec) {
    this.ra = verifyNumber(ra);
    this.dec = verifyNumber(dec);
    this.dist = verifyNumber(dist);
  }

  /// @brief Given an equatorial vector, calculates equatorial angular coordinates.
  ///
  /// @param {Vector} vec
  ///      A vector in an equatorial coordinate system.
  ///
  /// @returns {EquatorialCoordinates}
  ///      Angular coordinates expressed in the same equatorial system as `vec`.
  static EquatorialCoordinates fromVector(AstroVector vec) {
    final sphere = Spherical.sphereFromVector(vec);
    return EquatorialCoordinates(
      sphere.lon / 15,
      sphere.lat,
      sphere.dist,
      vec,
    );
  }
}

/// @brief Represents the location of an object seen by an observer on the Earth.
///
/// Holds azimuth (compass direction) and altitude (angle above/below the horizon)
/// of a celestial object as seen by an observer at a particular location on the Earth's surface.
/// Also holds right ascension and declination of the same object.
/// All of these coordinates are optionally adjusted for atmospheric refraction;
/// therefore the right ascension and declination values may not exactly match
/// those found inside a corresponding {@link EquatorialCoordinates} object.
///
/// @property {number} azimuth
///      A horizontal compass direction angle in degrees measured starting at north
///      and increasing positively toward the east.
///      The value is in the range [0, 360).
///      North = 0, east = 90, south = 180, west = 270.
///
/// @property {number} altitude
///      A vertical angle in degrees above (positive) or below (negative) the horizon.
///      The value is in the range [-90, +90].
///      The altitude angle is optionally adjusted upward due to atmospheric refraction.
///
/// @property {number} ra
///      The right ascension of the celestial body in sidereal hours.
///      The value is in the reange [0, 24).
///      If `altitude` was adjusted for atmospheric reaction, `ra`
///      is likewise adjusted.
///
/// @property {number} dec
///      The declination of of the celestial body in degrees.
///      The value in the range [-90, +90].
///      If `altitude` was adjusted for atmospheric reaction, `dec`
///      is likewise adjusted.
class HorizontalCoordinates {
  late double azimuth;
  late double altitude;
  late double ra;
  late double dec;

  HorizontalCoordinates(this.azimuth, this.altitude, this.ra, this.dec) {
    azimuth = verifyNumber(azimuth);
    altitude = verifyNumber(altitude);
    ra = verifyNumber(ra);
    dec = verifyNumber(dec);
  }

  /// @brief Converts equatorial coordinates to horizontal coordinates.
  ///
  /// Given a date and time, a geographic location of an observer on the Earth, and
  /// equatorial coordinates (right ascension and declination) of a celestial body,
  /// returns horizontal coordinates (azimuth and altitude angles) for that body
  /// as seen by that observer. Allows optional correction for atmospheric refraction.
  ///
  /// @param {FlexibleDateTime} date
  ///      The date and time for which to find horizontal coordinates.
  ///
  /// @param {Observer} observer
  ///      The location of the observer for which to find horizontal coordinates.
  ///
  /// @param {number} ra
  ///      Right ascension in sidereal hours of the celestial object,
  ///      referred to the mean equinox of date for the J2000 epoch.
  ///
  /// @param {number} dec
  ///      Declination in degrees of the celestial object,
  ///      referred to the mean equator of date for the J2000 epoch.
  ///      Positive values are north of the celestial equator and negative values are south.
  ///
  /// @param {string} refraction
  ///      If omitted or has a false-like value (false, null, undefined, etc.)
  ///      the calculations are performed without any correction for atmospheric
  ///      refraction. If the value is the string `"normal"`,
  ///      uses the recommended refraction correction based on Meeus "Astronomical Algorithms"
  ///      with a linear taper more than 1 degree below the horizon. The linear
  ///      taper causes the refraction to linearly approach 0 as the altitude of the
  ///      body approaches the nadir (-90 degrees).
  ///      If the value is the string `"jplhor"`, uses a JPL Horizons
  ///      compatible formula. This is the same algorithm as `"normal"`,
  ///      only without linear tapering; this can result in physically impossible
  ///      altitudes of less than -90 degrees, which may cause problems for some applications.
  ///      (The `"jplhor"` option was created for unit testing against data
  ///      generated by JPL Horizons, and is otherwise not recommended for use.)
  ///
  /// @returns {HorizontalCoordinates}
  static HorizontalCoordinates horizon(
      dynamic date, Observer observer, double ra, double dec,
      [String? refractionType]) {
    final time = AstroTime(date);

    final double sinlat = sin(observer.latitude * DEG2RAD);
    final double coslat = cos(observer.latitude * DEG2RAD);
    final double sinlon = sin(observer.longitude * DEG2RAD);
    final double coslon = cos(observer.longitude * DEG2RAD);
    final double sindc = sin(dec * DEG2RAD);
    final double cosdc = cos(dec * DEG2RAD);
    final double sinra = sin(ra * HOUR2RAD);
    final double cosra = cos(ra * HOUR2RAD);

    List<double> uze = [coslat * coslon, coslat * sinlon, sinlat];
    List<double> une = [-sinlat * coslon, -sinlat * sinlon, coslat];
    List<double> uwe = [sinlon, -coslon, 0];

    final double spinAngle = -15 * siderealTime(time);
    List<double> uz = spin(spinAngle, uze);
    List<double> un = spin(spinAngle, une);
    List<double> uw = spin(spinAngle, uwe);

    List<double> p = [cosdc * cosra, cosdc * sinra, sindc];

    final double pz = p[0] * uz[0] + p[1] * uz[1] + p[2] * uz[2];
    final double pn = p[0] * un[0] + p[1] * un[1] + p[2] * un[2];
    final double pw = p[0] * uw[0] + p[1] * uw[1] + p[2] * uw[2];

    var proj = hypot(pn, pw);

    double az;
    if (proj > 0) {
      az = -RAD2DEG * atan2(pw, pn);
      if (az < 0) az += 360;
    } else {
      az = 0;
    }

    double zd = RAD2DEG * atan2(proj, pz);
    double outRa = ra;
    double outDec = dec;

    if (refractionType != null) {
      final double zd0 = zd;
      final double refr = refraction(refractionType, 90 - zd);
      zd -= refr;
      if (refr > 0.0 && zd > 3.0e-4) {
        final double sinzd = sin(zd * DEG2RAD);
        final double coszd = cos(zd * DEG2RAD);
        final double sinzd0 = sin(zd0 * DEG2RAD);
        final double coszd0 = cos(zd0 * DEG2RAD);
        final List<double> pr = [];
        for (int j = 0; j < 3; ++j) {
          pr.add(((p[j] - coszd0 * uz[j]) / sinzd0) * sinzd + uz[j] * coszd);
        }
        proj = hypot(pr[0], pr[1]);
        if (proj > 0) {
          outRa = RAD2HOUR * atan2(pr[1], pr[0]);
          if (outRa < 0) {
            outRa += 24;
          }
        } else {
          outRa = 0;
        }
        outDec = RAD2DEG * atan2(pr[2], proj);
      }
    }

    return HorizontalCoordinates(az, 90 - zd, outRa, outDec);
  }
}

/// @brief Ecliptic coordinates of a celestial body.
///
/// The origin and date of the coordinate system may vary depending on the caller's usage.
/// In general, ecliptic coordinates are measured with respect to the mean plane of the Earth's
/// orbit around the Sun.
/// Includes Cartesian coordinates `(ex, ey, ez)` measured in
/// <a href="https://en.wikipedia.org/wiki/Astronomical_unit">astronomical units</a> (AU)
/// and spherical coordinates `(elon, elat)` measured in degrees.
///
/// @property {Vector} vec
///      Ecliptic cartesian vector with components measured in astronomical units (AU).
///      The x-axis is within the ecliptic plane and is oriented in the direction of the
///      <a href="https://en.wikipedia.org/wiki/Equinox_(celestial_coordinates)">equinox</a>.
///      The y-axis is within the ecliptic plane and is oriented 90 degrees
///      counterclockwise from the equinox, as seen from above the Sun's north pole.
///      The z-axis is oriented perpendicular to the ecliptic plane,
///      along the direction of the Sun's north pole.
///
/// @property {number} elat
///      The ecliptic latitude of the body in degrees.
///      This is the angle north or south of the ecliptic plane.
///      The value is in the range [-90, +90].
///      Positive values are north and negative values are south.
///
/// @property {number} elon
///      The ecliptic longitude of the body in degrees.
///      This is the angle measured counterclockwise around the ecliptic plane,
///      as seen from above the Sun's north pole.
///      This is the same direction that the Earth orbits around the Sun.
///      The angle is measured starting at 0 from the equinox and increases
///      up to 360 degrees.
class EclipticCoordinates {
  late AstroVector vec;
  late double eLat;
  late double eLon;

  EclipticCoordinates(this.vec, this.eLat, this.eLon) {
    vec = vec;
    eLat = verifyNumber(eLat);
    eLon = verifyNumber(eLon);
  }

  static EclipticCoordinates rotateEquatorialToEcliptic(
      AstroVector equ, double cosOb, double sinOb) {
    // Rotate equatorial vector to obtain ecliptic vector.
    final ex = equ.x;
    final ey = equ.y * cosOb + equ.z * sinOb;
    final ez = -equ.y * sinOb + equ.z * cosOb;

    final xyproj = sqrt(ex * ex + ey * ey);
    double elon = 0;
    if (xyproj > 0) {
      elon = RAD2DEG * atan2(ey, ex);
      if (elon < 0) elon += 360;
    }
    final elat = RAD2DEG * atan2(ez, xyproj);
    final ecl = AstroVector(ex, ey, ez, equ.time);
    return EclipticCoordinates(ecl, elat, elon);
  }
}
