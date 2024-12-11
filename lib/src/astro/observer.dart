part of 'astronomy.dart';

/// @brief Calculates the gravitational acceleration experienced by an observer on the Earth.
///
/// This function implements the WGS 84 Ellipsoidal Gravity Formula.
/// The result is a combination of inward gravitational acceleration
/// with outward centrifugal acceleration, as experienced by an observer
/// in the Earth's rotating frame of reference.
/// The resulting value increases toward the Earth's poles and decreases
/// toward the equator, consistent with changes of the weight measured
/// by a spring scale of a fixed mass moved to different latitudes and heights
/// on the Earth.
///
/// @param {number} latitude
///      The latitude of the observer in degrees north or south of the equator.
///      By formula symmetry, positive latitudes give the same answer as negative
///      latitudes, so the sign does not matter.
///
/// @param {number} height
///      The height above the sea level geoid in meters.
///      No range checking is done; however, accuracy is only valid in the
///      range 0 to 100000 meters.
///
/// @returns {number}
///      The effective gravitational acceleration expressed in meters per second squared [m/s^2].
double observerGravity(double latitude, double height) {
  final double s = sin(latitude * DEG2RAD);
  final double s2 = s * s;
  final double g0 = 9.7803253359 *
      (1.0 + 0.00193185265241 * s2) /
      sqrt(1.0 - 0.00669437999013 * s2);
  return g0 *
      (1.0 -
          (3.15704e-07 - 2.10269e-09 * s2) * height +
          7.37452e-14 * height * height);
}

/// @brief Represents the geographic location of an observer on the surface of the Earth.
///
/// @property {number} latitude
///      The observer's geographic latitude in degrees north of the Earth's equator.
///      The value is negative for observers south of the equator.
///      Must be in the range -90 to +90.
///
/// @property {number} longitude
///      The observer's geographic longitude in degrees east of the prime meridian
///      passing through Greenwich, England.
///      The value is negative for observers west of the prime meridian.
///      The value should be kept in the range -180 to +180 to minimize floating point errors.
///
/// @property {number} height
///      The observer's elevation above mean sea level, expressed in meters.
class Observer {
  final double latitude;
  final double longitude;
  final double height;

  Observer(this.latitude, this.longitude, this.height) {
    verifyObserver(this);
  }
}

void verifyObserver(Observer observer) {
  verifyNumber(observer.latitude);
  verifyNumber(observer.longitude);
  verifyNumber(observer.height);
  if (observer.latitude < -90 || observer.latitude > 90) {
    throw ArgumentError(
        'Latitude ${observer.latitude} is out of range. Must be -90..+90.');
  }
}

List<double> geoPos(AstroTime time, Observer observer) {
  final gast = siderealTime(time);
  final pos = terra(observer, gast).pos;
  return gyration(pos, time, PrecessDirection.Into2000);
}

Observer inverseTerra(List<double> ovec, double st) {
  // Convert from AU to kilometers
  final double x = ovec[0] * KM_PER_AU;
  final double y = ovec[1] * KM_PER_AU;
  final double z = ovec[2] * KM_PER_AU;
  final double p = sqrt(x * x + y * y);

  double lonDeg, latDeg, heightKm;

  if (p < 1.0e-6) {
    // Special case: within 1 millimeter of a pole!
    // Use arbitrary longitude, and latitude determined by polarity of z.
    lonDeg = 0;
    latDeg = (z > 0.0) ? 90 : -90;
    // Elevation is calculated directly from z.
    heightKm = z.abs() - EARTH_POLAR_RADIUS_KM;
  } else {
    final double stlocl = atan2(y, x);
    // Calculate exact longitude.
    lonDeg = (RAD2DEG * stlocl) - (15.0 * st);
    // Normalize longitude to the range (-180, +180].
    while (lonDeg <= -180) {
      lonDeg += 360;
    }
    while (lonDeg > 180) {
      lonDeg -= 360;
    }

    // Numerically solve for exact latitude, using Newton's Method.
    // Start with initial latitude estimate, based on a spherical Earth.
    double lat = atan2(z, p);
    double cosLat, sinLat, denom;
    int count = 0;

    while (true) {
      if (++count > 10) throw 'inverseTerra failed to converge.';

      // Calculate the error function W(lat).
      // We try to find the root of W, meaning where the error is 0.
      cosLat = cos(lat);
      sinLat = sin(lat);
      final double factor =
          (EARTH_FLATTENING_SQUARED - 1) * EARTH_EQUATORIAL_RADIUS_KM;
      final double cos2 = cosLat * cosLat;
      final double sin2 = sinLat * sinLat;
      final double radicand = cos2 + EARTH_FLATTENING_SQUARED * sin2;
      denom = sqrt(radicand);
      final double W =
          (factor * sinLat * cosLat) / denom - z * cosLat + p * sinLat;

      if (W.abs() < 1.0e-8) break; // The error is now negligible

      // Error is still too large. Find the next estimate.
      // Calculate D = the derivative of W with respect to lat.
      final double D = factor *
              ((cos2 - sin2) / denom -
                  sin2 *
                      cos2 *
                      (EARTH_FLATTENING_SQUARED - 1) /
                      (factor * radicand)) +
          z * sinLat +
          p * cosLat;
      lat -= W / D;
    }

    // We now have a solution for the latitude in radians.
    latDeg = RAD2DEG * lat;

    // Solve for exact height in meters.
    // There are two formulas I can use. Use whichever has the less risky denominator.
    final double adjust = EARTH_EQUATORIAL_RADIUS_KM / denom;
    if (sinLat.abs() > cosLat.abs()) {
      heightKm = z / sinLat - EARTH_FLATTENING_SQUARED * adjust;
    } else {
      heightKm = p / cosLat - adjust;
    }
  }

  return Observer(latDeg, lonDeg, 1000 * heightKm);
}

/// @brief Calculates geocentric equatorial coordinates of an observer on the surface of the Earth.
///
/// This function calculates a vector from the center of the Earth to
/// a point on or near the surface of the Earth, expressed in equatorial
/// coordinates. It takes into account the rotation of the Earth at the given
/// time, along with the given latitude, longitude, and elevation of the observer.
///
/// The caller may pass `ofdate` as `true` to return coordinates relative to the Earth's
/// equator at the specified time, or `false` to use the J2000 equator.
///
/// The returned vector has components expressed in astronomical units (AU).
/// To convert to kilometers, multiply the `x`, `y`, and `z` values by
/// the constant value {@link KM_PER_AU}.
///
/// The inverse of this function is also available: {@link VectorObserver}.
///
/// @param {FlexibleDateTime} date
///      The date and time for which to calculate the observer's position vector.
///
/// @param {Observer} observer
///      The geographic location of a point on or near the surface of the Earth.
///
/// @param {boolean} ofdate
///      Selects the date of the Earth's equator in which to express the equatorial coordinates.
///      The caller may pass `false` to use the orientation of the Earth's equator
///      at noon UTC on January 1, 2000, in which case this function corrects for precession
///      and nutation of the Earth as it was at the moment specified by the `time` parameter.
///      Or the caller may pass `true` to use the Earth's equator at `time`
///      as the orientation.
///
/// @returns {Vector}
///      An equatorial vector from the center of the Earth to the specified location
///      on (or near) the Earth's surface.
AstroVector observerVector(dynamic date, Observer observer, bool ofdate) {
  final time = AstroTime(date);
  final gast = siderealTime(time);
  var ovec = terra(observer, gast).pos;
  if (!ofdate) {
    ovec = gyration(ovec, time, PrecessDirection.Into2000);
  }
  return AstroVector.fromArray(ovec, time);
}

/// @brief Calculates geocentric equatorial position and velocity of an observer on the surface of the Earth.
///
/// This function calculates position and velocity vectors of an observer
/// on or near the surface of the Earth, expressed in equatorial
/// coordinates. It takes into account the rotation of the Earth at the given
/// time, along with the given latitude, longitude, and elevation of the observer.
///
/// The caller may pass `ofdate` as `true` to return coordinates relative to the Earth's
/// equator at the specified time, or `false` to use the J2000 equator.
///
/// The returned position vector has components expressed in astronomical units (AU).
/// To convert to kilometers, multiply the `x`, `y`, and `z` values by
/// the constant value {@link KM_PER_AU}.
/// The returned velocity vector has components expressed in AU/day.
///
/// @param {FlexibleDateTime} date
///      The date and time for which to calculate the observer's position and velocity vectors.
///
/// @param {Observer} observer
///      The geographic location of a point on or near the surface of the Earth.
///
/// @param {boolean} ofdate
///      Selects the date of the Earth's equator in which to express the equatorial coordinates.
///      The caller may pass `false` to use the orientation of the Earth's equator
///      at noon UTC on January 1, 2000, in which case this function corrects for precession
///      and nutation of the Earth as it was at the moment specified by the `time` parameter.
///      Or the caller may pass `true` to use the Earth's equator at `time`
///      as the orientation.
///
/// @returns {StateVector}
StateVector observerState(dynamic date, Observer observer, bool ofdate) {
  final time = AstroTime(date);
  final gast = siderealTime(time);
  final svec = terra(observer, gast);
  final state = StateVector(
    svec.pos[0],
    svec.pos[1],
    svec.pos[2],
    svec.vel[0],
    svec.vel[1],
    svec.vel[2],
    time,
  );

  if (!ofdate) {
    return StateVector.gyrationPosVel(state, time, PrecessDirection.Into2000);
  }

  return state;
}

/// @brief Calculates the geographic location corresponding to an equatorial vector.
///
/// This is the inverse function of {@link ObserverVector}.
/// Given a geocentric equatorial vector, it returns the geographic
/// latitude, longitude, and elevation for that vector.
///
/// @param {Vector} vector
///      The geocentric equatorial position vector for which to find geographic coordinates.
///      The components are expressed in Astronomical Units (AU).
///      You can calculate AU by dividing kilometers by the constant {@link KM_PER_AU}.
///      The time `vector.t` determines the Earth's rotation.
///
/// @param {boolean} ofdate
///      Selects the date of the Earth's equator in which `vector` is expressed.
///      The caller may select `false` to use the orientation of the Earth's equator
///      at noon UTC on January 1, 2000, in which case this function corrects for precession
///      and nutation of the Earth as it was at the moment specified by `vector.t`.
///      Or the caller may select `true` to use the Earth's equator at `vector.t`
///      as the orientation.
///
/// @returns {Observer}
///      The geographic latitude, longitude, and elevation above sea level
///      that corresponds to the given equatorial vector.
Observer vectorObserver(AstroVector vector, bool ofdate) {
  final gast = siderealTime(vector.time);
  var ovec = [vector.x, vector.y, vector.z];
  if (!ofdate) {
    ovec = precession(ovec, vector.time, PrecessDirection.From2000);
    ovec = nutation(ovec, vector.time, PrecessDirection.From2000);
  }
  return inverseTerra(ovec, gast);
}

class TerraInfo {
  final List<double> pos;
  final List<double> vel;

  TerraInfo(this.pos, this.vel);
}

TerraInfo terra(Observer observer, double st) {
  final phi = observer.latitude * DEG2RAD;
  final sinphi = sin(phi);
  final cosphi = cos(phi);
  final c =
      1 / sqrt(cosphi * cosphi + EARTH_FLATTENING_SQUARED * sinphi * sinphi);
  final s = EARTH_FLATTENING_SQUARED * c;
  final htKm = observer.height / 1000;
  final ach = EARTH_EQUATORIAL_RADIUS_KM * c + htKm;
  final ash = EARTH_EQUATORIAL_RADIUS_KM * s + htKm;
  final stlocl = (15 * st + observer.longitude) * DEG2RAD;
  final sinst = sin(stlocl);
  final cosst = cos(stlocl);

  return TerraInfo(
    [
      ach * cosphi * cosst / KM_PER_AU,
      ach * cosphi * sinst / KM_PER_AU,
      ash * sinphi / KM_PER_AU
    ],
    [
      -ANGVEL * ach * cosphi * sinst * 86400 / KM_PER_AU,
      ANGVEL * ach * cosphi * cosst * 86400 / KM_PER_AU,
      0
    ],
  );
}
