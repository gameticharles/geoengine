part of 'astronomy.dart';

bool verifyBoolean(bool b) {
  if (b != true && b != false) {
    throw Exception('Value is not boolean: $b');
  }
  return b;
}

double verifyNumber(double x) {
  if (!x.isFinite) {
    throw Exception('Value is not a finite number: $x');
  }
  return x;
}

num frac(num x) {
  return x - x.floorToDouble();
}

/// @brief Calculates the angle in degrees between two vectors.
///
/// Given a pair of vectors, this function returns the angle in degrees
/// between the two vectors in 3D space.
/// The angle is measured in the plane that contains both vectors.
///
/// @param {Vector} a
///      The first of a pair of vectors between which to measure an angle.
///
/// @param {Vector} b
///      The second of a pair of vectors between which to measure an angle.
///
/// @returns {number}
///      The angle between the two vectors expressed in degrees.
///      The value is in the range [0, 180].
double angleBetween(AstroVector a, AstroVector b) {
  final double aa = (a.x * a.x + a.y * a.y + a.z * a.z);
  if (aa.abs() < 1.0e-8) {
    throw Exception('AngleBetween: first vector is too short.');
  }

  final double bb = (b.x * b.x + b.y * b.y + b.z * b.z);
  if (bb.abs() < 1.0e-8) {
    throw Exception('AngleBetween: second vector is too short.');
  }

  final double dot = (a.x * b.x + a.y * b.y + a.z * b.z) / sqrt(aa * bb);

  if (dot <= -1.0) {
    return 180.0;
  }

  if (dot >= 1.0) {
    return 0.0;
  }

  return RAD2DEG * acos(dot);
}

/// @brief Returns the mean orbital period of a planet in days.
///
/// @param {Body} body
///      One of: Mercury, Venus, Earth, Mars, Jupiter, Saturn, Uranus, Neptune, or Pluto.
///
/// @returns {number}
///      The approximate average time it takes for the planet to travel once around the Sun.
///      The value is expressed in days.
double planetOrbitalPeriod(Body body) {
  if (planetTable.containsKey(body.toString().split('.').last)) {
    return planetTable[body.toString().split('.').last]!.orbitalPeriod;
  }

  throw "Unknown orbital period for: $body";
}

double deltaT_EspenakMeeus(double ut) {
  double u, u2, u3, u4, u5, u6, u7;
  /*
        Fred Espenak writes about Delta-T generically here:
        https://eclipse.gsfc.nasa.gov/SEhelp/deltaT.html
        https://eclipse.gsfc.nasa.gov/SEhelp/deltat2004.html

        He provides polynomial approximations for distant years here:
        https://eclipse.gsfc.nasa.gov/SEhelp/deltatpoly2004.html

        They start with a year value 'y' such that y=2000 corresponds
        to the UTC Date 15-January-2000. Convert difference in days
        to mean tropical years.
    */
  final double y = 2000 + ((ut - 14) / DAYS_PER_TROPICAL_YEAR);

  if (y < -500) {
    u = (y - 1820) / 100;
    return -20 + (32 * u * u);
  }
  if (y < 500) {
    u = y / 100;
    u2 = u * u;
    u3 = u2 * u;
    u4 = u3 * u;
    u5 = u4 * u;
    u6 = u5 * u;
    return 10583.6 -
        1014.41 * u +
        33.78311 * u2 -
        5.952053 * u3 -
        0.1798452 * u4 +
        0.022174192 * u5 +
        0.0090316521 * u6;
  }
  if (y < 1600) {
    u = (y - 1000) / 100;
    u2 = u * u;
    u3 = u2 * u;
    u4 = u3 * u;
    u5 = u4 * u;
    u6 = u5 * u;
    return 1574.2 -
        556.01 * u +
        71.23472 * u2 +
        0.319781 * u3 -
        0.8503463 * u4 -
        0.005050998 * u5 +
        0.0083572073 * u6;
  }
  if (y < 1700) {
    u = y - 1600;
    u2 = u * u;
    u3 = u2 * u;
    return 120 - 0.9808 * u - 0.01532 * u2 + u3 / 7129.0;
  }
  if (y < 1800) {
    u = y - 1700;
    u2 = u * u;
    u3 = u2 * u;
    u4 = u3 * u;
    return 8.83 + 0.1603 * u - 0.0059285 * u2 + 0.00013336 * u3 - u4 / 1174000;
  }
  if (y < 1860) {
    u = y - 1800;
    u2 = u * u;
    u3 = u2 * u;
    u4 = u3 * u;
    u5 = u4 * u;
    u6 = u5 * u;
    u7 = u6 * u;
    return 13.72 -
        0.332447 * u +
        0.0068612 * u2 +
        0.0041116 * u3 -
        0.00037436 * u4 +
        0.0000121272 * u5 -
        0.0000001699 * u6 +
        0.000000000875 * u7;
  }
  if (y < 1900) {
    u = y - 1860;
    u2 = u * u;
    u3 = u2 * u;
    u4 = u3 * u;
    u5 = u4 * u;
    return 7.62 +
        0.5737 * u -
        0.251754 * u2 +
        0.01680668 * u3 -
        0.0004473624 * u4 +
        u5 / 233174;
  }
  if (y < 1920) {
    u = y - 1900;
    u2 = u * u;
    u3 = u2 * u;
    u4 = u3 * u;
    return -2.79 +
        1.494119 * u -
        0.0598939 * u2 +
        0.0061966 * u3 -
        0.000197 * u4;
  }
  if (y < 1941) {
    u = y - 1920;
    u2 = u * u;
    u3 = u2 * u;
    return 21.20 + 0.84493 * u - 0.076100 * u2 + 0.0020936 * u3;
  }
  if (y < 1961) {
    u = y - 1950;
    u2 = u * u;
    u3 = u2 * u;
    return 29.07 + 0.407 * u - u2 / 233 + u3 / 2547;
  }
  if (y < 1986) {
    u = y - 1975;
    u2 = u * u;
    u3 = u2 * u;
    return 45.45 + 1.067 * u - u2 / 260 - u3 / 718;
  }
  if (y < 2005) {
    u = y - 2000;
    u2 = u * u;
    u3 = u2 * u;
    u4 = u3 * u;
    u5 = u4 * u;
    return 63.86 +
        0.3345 * u -
        0.060374 * u2 +
        0.0017275 * u3 +
        0.000651814 * u4 +
        0.00002373599 * u5;
  }
  if (y < 2050) {
    u = y - 2000;
    return 62.92 + 0.32217 * u + 0.005589 * u * u;
  }
  if (y < 2150) {
    u = (y - 1820) / 100;
    return -20 + 32 * u * u - 0.5628 * (2150 - y);
  }

  // all years after 2150
  u = (y - 1820) / 100;
  return -20 + (32 * u * u);
}

typedef DeltaTimeFunction = double Function(double ut);

double deltaT_JplHorizons(double ut) {
  const double daysPerTropicalYear = 365.242190;
  return deltaT_EspenakMeeus(
      ut < 17.0 * daysPerTropicalYear ? ut : 17.0 * daysPerTropicalYear);
}

DeltaTimeFunction deltaT = deltaT_EspenakMeeus;

void setDeltaTFunction(DeltaTimeFunction func) {
  deltaT = func;
}

/// @ignore
///
/// @brief Calculates Terrestrial Time (TT) from Universal Time (UT).
///
/// @param {number} ut
///      The Universal Time expressed as a floating point number of days since the 2000.0 epoch.
///
/// @returns {number}
///      A Terrestrial Time expressed as a floating point number of days since the 2000.0 epoch.
double terrestrialTime(double ut) {
  return ut + deltaT(ut) / 86400;
}

List<double> rotate(RotationMatrix rot, List<double> vec) {
  return [
    rot.rot[0][0] * vec[0] + rot.rot[1][0] * vec[1] + rot.rot[2][0] * vec[2],
    rot.rot[0][1] * vec[0] + rot.rot[1][1] * vec[1] + rot.rot[2][1] * vec[2],
    rot.rot[0][2] * vec[0] + rot.rot[1][2] * vec[1] + rot.rot[2][2] * vec[2]
  ];
}

/// Earth Rotation Angle
double era(AstroTime time) {
  final double thet1 = 0.7790572732640 + 0.00273781191135448 * time.ut;
  final double thet3 = time.ut % 1;
  double theta = 360 * ((thet1 + thet3) % 1);
  if (theta < 0) {
    theta += 360;
  }
  return theta;
}

List<double> precession(
    List<double> pos, AstroTime time, PrecessDirection dir) {
  final r = RotationMatrix.precessionRot(time, dir);
  return rotate(r, pos);
}

List<double> nutation(List<double> pos, AstroTime time, PrecessDirection dir) {
  final r = RotationMatrix.nutationRot(time, dir);
  return rotate(r, pos);
}

List<double> gyration(List<double> pos, AstroTime time, PrecessDirection dir) {
  // Combine nutation and precession into a single operation I call "gyration".
  // The order they are composed depends on the direction,
  // because both directions are mutual inverse functions.
  if (dir == PrecessDirection.Into2000) {
    return precession(nutation(pos, time, dir), time, dir);
  } else {
    return nutation(precession(pos, time, dir), time, dir);
  }
}


/// Toggles the azimuth direction by subtracting it from 360 degrees.
double toggleAzimuthDirection(double az) {
  az = 360.0 - az;
  if (az >= 360.0) {
    az -= 360.0;
  } else if (az < 0.0) {
    az += 360.0;
  }
  return az;
}
