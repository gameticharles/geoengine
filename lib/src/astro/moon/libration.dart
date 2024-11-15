// ignore_for_file: non_constant_identifier_names

part of '../astronomy.dart';

int calcMoonCount = 0;

double LongitudeOffset(double diff) {
  double offset = diff;
  while (offset <= -180) offset += 360;
  while (offset > 180) offset -= 360;
  return offset;
}

double NormalizeLongitude(double lon) {
  while (lon < 0) lon += 360;
  while (lon >= 360) lon -= 360;
  return lon;
}

/// @brief Lunar libration angles, returned by {@link Libration}.
///
/// @property {number} elat
///      Sub-Earth libration ecliptic latitude angle, in degrees.
/// @property {number} elon
///      Sub-Earth libration ecliptic longitude angle, in degrees.
/// @property {number} mlat
///      Moon's geocentric ecliptic latitude, in degrees.
/// @property {number} mlon
///      Moon's geocentric ecliptic longitude, in degrees.
/// @property {number} dist_km
///      Distance between the centers of the Earth and Moon in kilometers.
/// @property {number} diam_deg
///      The apparent angular diameter of the Moon, in degrees, as seen from the center of the Earth.
class LibrationInfo {
  final double elat;
  final double elon;
  final double mlat;
  final double mlon;
  final double dist_km;
  final double diam_deg;

  LibrationInfo({
    required this.elat,
    required this.elon,
    required this.mlat,
    required this.mlon,
    required this.dist_km,
    required this.diam_deg,
  });
}

/// @brief Calculates the Moon's libration angles at a given moment in time.
///
/// Libration is an observed back-and-forth wobble of the portion of the
/// Moon visible from the Earth. It is caused by the imperfect tidal locking
/// of the Moon's fixed rotation rate, compared to its variable angular speed
/// of orbit around the Earth.
///
/// This function calculates a pair of perpendicular libration angles,
/// one representing rotation of the Moon in ecliptic longitude `elon`, the other
/// in ecliptic latitude `elat`, both relative to the Moon's mean Earth-facing position.
///
/// This function also returns the geocentric position of the Moon
/// expressed in ecliptic longitude `mlon`, ecliptic latitude `mlat`, the
/// distance `dist_km` between the centers of the Earth and Moon expressed in kilometers,
/// and the apparent angular diameter of the Moon `diam_deg`.
///
/// @param {dynamic} date
///      A Date object, a number of UTC days since the J2000 epoch (noon on January 1, 2000),
///      or an AstroTime object.
///
/// @returns {LibrationInfo}
LibrationInfo Libration(dynamic date) {
  final time = AstroTime(date);
  final t = time.tt / 36525.0;
  final t2 = t * t;
  final t3 = t2 * t;
  final t4 = t2 * t2;
  final moon = Moon(time);
  print(moon);
  final mlon = moon.geo_eclip_lon;
  final mlat = moon.geo_eclip_lat;
  final distKm = moon.distance_au * KM_PER_AU;

  // Inclination angle
  final I = DEG2RAD * 1.543;

  // Moon's argument of latitude in radians.
  final f = DEG2RAD *
      NormalizeLongitude(93.2720950 +
          483202.0175233 * t -
          0.0036539 * t2 -
          t3 / 3526000 +
          t4 / 863310000);

  // Moon's ascending node's mean longitude in radians.
  final omega = DEG2RAD *
      NormalizeLongitude(125.0445479 -
          1934.1362891 * t +
          0.0020754 * t2 +
          t3 / 467441 -
          t4 / 60616000);

  // Sun's mean anomaly.
  final m = DEG2RAD *
      NormalizeLongitude(
          357.5291092 + 35999.0502909 * t - 0.0001536 * t2 + t3 / 24490000);

  // Moon's mean anomaly.
  final mdash = DEG2RAD *
      NormalizeLongitude(134.9633964 +
          477198.8675055 * t +
          0.0087414 * t2 +
          t3 / 69699 -
          t4 / 14712000);

  // Moon's mean elongation.
  final d = DEG2RAD *
      NormalizeLongitude(297.8501921 +
          445267.1114034 * t -
          0.0018819 * t2 +
          t3 / 545868 -
          t4 / 113065000);

  // Eccentricity of the Earth's orbit.
  final e = 1.0 - 0.002516 * t - 0.0000074 * t2;

  // Optical librations
  final w = mlon - omega;
  final a = atan2(
      sin(w) * cos(mlat) * cos(I) - sin(mlat) * sin(I), cos(w) * cos(mlat));
  final ldash = LongitudeOffset(RAD2DEG * (a - f));
  final bdash = asin(-sin(w) * cos(mlat) * sin(I) - sin(mlat) * cos(I));

  // Physical librations
  final k1 = DEG2RAD * (119.75 + 131.849 * t);
  final k2 = DEG2RAD * (72.56 + 20.186 * t);

  final rho = (-0.02752 * cos(mdash) +
      -0.02245 * sin(f) +
      0.00684 * cos(mdash - 2 * f) +
      -0.00293 * cos(2 * f) +
      -0.00085 * cos(2 * f - 2 * d) +
      -0.00054 * cos(mdash - 2 * d) +
      -0.00020 * sin(mdash + f) +
      -0.00020 * cos(mdash + 2 * f) +
      -0.00020 * cos(mdash - f) +
      0.00014 * cos(mdash + 2 * f - 2 * d));

  final sigma = (-0.02816 * sin(mdash) +
      0.02244 * cos(f) +
      -0.00682 * sin(mdash - 2 * f) +
      -0.00279 * sin(2 * f) +
      -0.00083 * sin(2 * f - 2 * d) +
      0.00069 * sin(mdash - 2 * d) +
      0.00040 * cos(mdash + f) +
      -0.00025 * sin(2 * mdash) +
      -0.00023 * sin(mdash + 2 * f) +
      0.00020 * cos(mdash - f) +
      0.00019 * sin(mdash - f) +
      0.00013 * sin(mdash + 2 * f - 2 * d) +
      -0.00010 * cos(mdash - 3 * f));

  final tau = (0.02520 * e * sin(m) +
      0.00473 * sin(2 * mdash - 2 * f) +
      -0.00467 * sin(mdash) +
      0.00396 * sin(k1) +
      0.00276 * sin(2 * mdash - 2 * d) +
      0.00196 * sin(omega) +
      -0.00183 * cos(mdash - f) +
      0.00115 * sin(mdash - 2 * d) +
      -0.00096 * sin(mdash - d) +
      0.00046 * sin(2 * f - 2 * d) +
      -0.00039 * sin(mdash - f) +
      -0.00032 * sin(mdash - m - d) +
      0.00027 * sin(2 * mdash - m - 2 * d) +
      0.00023 * sin(k2) +
      -0.00014 * sin(2 * d) +
      0.00014 * cos(2 * mdash - 2 * f) +
      -0.00012 * sin(mdash - 2 * f) +
      -0.00012 * sin(2 * mdash) +
      0.00011 * sin(2 * mdash - 2 * m - 2 * d));

  final ldash2 = -tau + (rho * cos(a) + sigma * sin(a)) * tan(bdash);
  final bdash2 = sigma * cos(a) - rho * sin(a);
  final diamDeg = 2.0 *
      RAD2DEG *
      atan(MOON_MEAN_RADIUS_KM /
          sqrt(distKm * distKm - MOON_MEAN_RADIUS_KM * MOON_MEAN_RADIUS_KM));

  return LibrationInfo(
      elat: RAD2DEG * bdash + bdash2,
      elon: ldash + ldash2,
      mlat: RAD2DEG * mlat,
      mlon: RAD2DEG * mlon,
      dist_km: distKm,
      diam_deg: diamDeg);
}
