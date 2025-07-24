part of 'astronomy.dart';

/// Verifies that the given boolean value is either true or false.
///
/// If the value is not a valid boolean, an [Exception] is thrown.
///
/// @param b The boolean value to verify.
/// @returns The verified boolean value.
bool verifyBoolean(bool b) {
  if (b != true && b != false) {
    throw Exception('Value is not boolean: $b');
  }
  return b;
}

/// Verifies that the given number is a finite value.
///
/// If the value is not a finite number, an [Exception] is thrown.
///
/// @param x The number to verify.
/// @returns The verified number.
double verifyNumber(double x) {
  if (!x.isFinite) {
    throw Exception('Value is not a finite number: $x');
  }
  return x;
}

/// Returns the fractional part of the given number.
///
/// This function takes a [num] value and returns the fractional part of that value.
/// The fractional part is the part of the number that is to the right of the decimal point.
///
/// @param x The number to get the fractional part of.
/// @returns The fractional part of the given number.
num frac(num x) {
  return x - x.floorToDouble();
}

/// Calculates the angle in degrees between two vectors.
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
///      The value is in the range `[0, 180]`.
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

/// Returns the mean orbital period of a planet in days.
///
/// @param {Body} body
///      One of: Mercury, Venus, Earth, Mars, Jupiter, Saturn, Uranus, Neptune, or Pluto.
///
/// @returns {number}
///      The approximate average time it takes for the planet to travel once around the Sun.
///      The value is expressed in days.
double planetOrbitalPeriod(Body body) {
  if (planetTable.containsKey(body.name)) {
    return planetTable[body.name]!.orbitalPeriod;
  }

  throw "Unknown orbital period for: $body";
}

double deltaTEspenakMeeus(double ut) {
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

/// A function that calculates the difference between UT and UT1.
typedef DeltaTimeFunction = double Function(double ut);

/// Calculates the difference between Universal Time (UT) and UT1 using the JPL Horizons model.
///
/// This function is a wrapper around [deltaTEspenakMeeus] that limits the input UT to a maximum of 17 tropical years.
/// The JPL Horizons model is only valid for a limited range of UT, so this function ensures the input is within that range.
///
/// @param ut The Universal Time expressed as a floating point number of days since the 2000.0 epoch.
/// @returns The difference between UT and UT1 in days.
double deltaTJplHorizons(double ut) {
  const double daysPerTropicalYear = 365.242190;
  return deltaTEspenakMeeus(
      ut < 17.0 * daysPerTropicalYear ? ut : 17.0 * daysPerTropicalYear);
}

DeltaTimeFunction deltaT = deltaTEspenakMeeus;

/// Sets the function used to calculate the difference between Universal Time (UT) and UT1.
///
/// This function allows the caller to override the default delta time function, [deltaTEspenakMeeus], with a custom implementation.
///
/// @param func The new delta time function to use.
void setDeltaTFunction(DeltaTimeFunction func) {
  deltaT = func;
}

/// @ignore
///
/// Calculates Terrestrial Time (TT) from Universal Time (UT).
///
/// @param {number} ut
///      The Universal Time expressed as a floating point number of days since the 2000.0 epoch.
///
/// @returns {number}
///      A Terrestrial Time expressed as a floating point number of days since the 2000.0 epoch.
double terrestrialTime(double ut) {
  return ut + deltaT(ut) / 86400;
}

/// Rotate a vector by a rotation matrix.
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

/// Applies the precession rotation to the given position vector.
List<double> precession(
    List<double> pos, AstroTime time, PrecessDirection dir) {
  final r = RotationMatrix.precessionRot(time, dir);
  return rotate(r, pos);
}

/// Applies the nutation rotation to the given position vector.
///
/// The nutation rotation is a small adjustment to the precession rotation
/// that accounts for the periodic wobble of the Earth's axis.
///
/// @param pos The position vector to rotate.
/// @param time The time at which to calculate the nutation.
/// @param dir The direction of the nutation rotation (into or out of J2000).
/// @return The rotated position vector.
List<double> nutation(List<double> pos, AstroTime time, PrecessDirection dir) {
  final r = RotationMatrix.nutationRot(time, dir);
  return rotate(r, pos);
}

/// Applies the precession and nutation rotations to the given position vector.
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

List<double> spin(double angle, List<double> pos) {
  final double angr = angle * (pi / 180); // DEG2RAD
  final double c = cos(angr);
  final double s = sin(angr);
  return [c * pos[0] + s * pos[1], c * pos[1] - s * pos[0], pos[2]];
}

/// Calculates the amount of "lift" to an altitude angle caused by atmospheric refraction.
///
/// Given an altitude angle and a refraction option, calculates
/// the amount of "lift" caused by atmospheric refraction.
/// This is the number of degrees higher in the sky an object appears
/// due to the lensing of the Earth's atmosphere.
/// This function works best near sea level.
/// To correct for higher elevations, call {@link Atmosphere} for that
/// elevation and multiply the refraction angle by the resulting relative density.
///
/// @param {string} refraction
///      `"normal"`: correct altitude for atmospheric refraction (recommended).
///      `"jplhor"`: for JPL Horizons compatibility testing only; not recommended for normal use.
///      `null`: no atmospheric refraction correction is performed.
///
/// @param {number} altitude
///      An altitude angle in a horizontal coordinate system. Must be a value between -90 and +90.
///
/// @returns {number}
///      The angular adjustment in degrees to be added to the altitude angle to correct for atmospheric lensing.
double refraction(RefractionType refraction, double altitude) {
  double refr;

  if (altitude < -90.0 || altitude > 90.0) {
    return 0.0; // No attempt to correct an invalid altitude
  }

  if (refraction.name == 'normal' || refraction.name == 'jplhor') {
    double hd = altitude;
    if (hd < -1.0) {
      hd = -1.0;
    }

    refr = (1.02 / tan((hd + 10.3 / (hd + 5.11)) * DEG2RAD)) / 60.0;

    if (refraction.name == 'normal' && altitude < -1.0) {
      refr *= (altitude + 90.0) / 89.0;
    }
  } else if (refraction.name == 'null') {
    refr = 0.0;
  } else {
    throw Exception('Invalid refraction option: $refraction');
  }

  return refr;
}

const double daysPerMillennium = 365250.0;
const int lonIndex = 0;
const int latIndex = 1;
const int radIndex = 2;

double vsopFormula(
    List<List<List<double>>> formula, double t, bool clampAngle) {
  double tPower = 1;
  double coord = 0;

  for (var series in formula) {
    double sum = 0;
    for (var entry in series) {
      double ampl = entry[0];
      double phas = entry[1];
      double freq = entry[2];
      sum += ampl * cos(phas + (t * freq));
    }
    double incr = tPower * sum;
    if (clampAngle) {
      incr %=
          PI2; // improve precision for longitudes: they can be hundreds of radians
    }
    coord += incr;
    tPower *= t;
  }

  return coord;
}

List<double> vsopSphereToRect(double lon, double lat, double radius) {
  // Convert spherical coordinates to ecliptic cartesian coordinates.
  final rCosLat = radius * cos(lat);
  final cosLon = cos(lon);
  final sinLon = sin(lon);
  return [
    rCosLat * cosLon,
    rCosLat * sinLon,
    radius * sin(lat),
  ];
}

TerseVector vsopRotate(List<double> eclip) {
  // Convert ecliptic cartesian coordinates to equatorial cartesian coordinates.
  return TerseVector(
    eclip[0] + 0.000000440360 * eclip[1] - 0.000000190919 * eclip[2],
    -0.000000479966 * eclip[0] +
        0.917482137087 * eclip[1] -
        0.397776982902 * eclip[2],
    0.397776982902 * eclip[1] + 0.917482137087 * eclip[2],
  );
}

AstroVector calcVsop(List<List<List<List<double>>>> model, AstroTime time) {
  double t = time.tt / daysPerMillennium; // millennia since 2000

  double lon = vsopFormula(model[lonIndex], t, true);
  double lat = vsopFormula(model[latIndex], t, false);
  double rad = vsopFormula(model[radIndex], t, false);

  List<double> eclip = vsopSphereToRect(lon, lat, rad);

  return vsopRotate(eclip).toAstroVector(time);
}

double vsopDeriv(dynamic formula, double t) {
  double tpower = 1; // t^s
  double dpower = 0; // t^(s-1)
  double deriv = 0;
  int s = 0;

  for (var series in formula) {
    double sinSum = 0;
    double cosSum = 0;

    for (var term in series) {
      double ampl = term[0];
      double phas = term[1];
      double freq = term[2];
      double angle = phas + (t * freq);

      sinSum += ampl * freq * sin(angle);
      if (s > 0) {
        cosSum += ampl * cos(angle);
      }
    }

    deriv += (s * dpower * cosSum) - (tpower * sinSum);
    dpower = tpower;
    tpower *= t;
    ++s;
  }

  return deriv;
}

BodyState calcVsopPosVel(List<List<List<List<double>>>> model, double tt) {
  final t = tt / daysPerMillennium;

  // Calculate the VSOP "B" trigonometric series to obtain ecliptic spherical coordinates.
  final lon = vsopFormula(model[lonIndex], t, true);
  final lat = vsopFormula(model[latIndex], t, false);
  final rad = vsopFormula(model[radIndex], t, false);

  final dlonDt = vsopDeriv(model[lonIndex], t);
  final dlatDt = vsopDeriv(model[latIndex], t);
  final dradDt = vsopDeriv(model[radIndex], t);

  // Use spherical coords and spherical derivatives to calculate
  // the velocity vector in rectangular coordinates.
  final coslon = cos(lon);
  final sinlon = sin(lon);
  final coslat = cos(lat);
  final sinlat = sin(lat);

  final vx = ((dradDt * coslat * coslon) -
      (rad * sinlat * coslon * dlatDt) -
      (rad * coslat * sinlon * dlonDt));

  final vy = ((dradDt * coslat * sinlon) -
      (rad * sinlat * sinlon * dlatDt) +
      (rad * coslat * coslon * dlonDt));

  final vz = ((dradDt * sinlat) + (rad * coslat * dlatDt));

  final eclipPos = vsopSphereToRect(lon, lat, rad);

  // Convert speed units from [AU/millennium] to [AU/day].
  final List<double> eclipVel = [
    vx / daysPerMillennium,
    vy / daysPerMillennium,
    vz / daysPerMillennium
  ];

  // Rotate the vectors from ecliptic to equatorial coordinates.
  final equPos = vsopRotate(eclipPos);
  final equVel = vsopRotate(eclipVel);

  return BodyState(tt, equPos, equVel);
}

List<List<BodyGravCalc>> plutoCache = [];

int clampIndex(double frac, int nsteps) {
  int index = frac.floor();
  if (index < 0) return 0;
  if (index >= nsteps) return nsteps - 1;
  return index;
}

BodyState bodyStateFromTable(List entry) {
  final tt = entry[0];
  final rx = entry[1][0];
  final ry = entry[1][1];
  final rz = entry[1][2];
  final vx = entry[2][0];
  final vy = entry[2][1];
  final vz = entry[2][2];
  return BodyState(tt, TerseVector(rx, ry, rz), TerseVector(vx, vy, vz));
}

BodyState adjustBarycenterPosVel(
    BodyState ssb, double tt, Body body, double planetGm) {
  final shift = planetGm / (planetGm + SUN_GM);
  final planet = calcVsopPosVel(vsopTable[body.name]!, tt);
  ssb.r.incr(planet.r.mul(shift));
  ssb.v.incr(planet.v.mul(shift));
  return planet;
}

TerseVector accelerationIncrement(
    TerseVector smallPos, double gm, TerseVector majorPos) {
  final delta = majorPos.sub(smallPos);
  final r2 = delta.quadrature();
  return delta.mul(gm / (r2 * sqrt(r2)));
}

GravSimT gravSim(double tt2, BodyGravCalc calc1) {
  final double dt = tt2 - calc1.tt;

  // Calculate where the major bodies (Sun, Jupiter...Neptune) will be at tt2.
  final bary2 = MajorBodies(tt2);

  // Estimate position of small body as if current acceleration applies across the whole time interval.
  final approxPos = TerseVector.updatePosition(dt, calc1.r, calc1.v, calc1.a);

  // Calculate the average acceleration of the endpoints.
  // This becomes our estimate of the mean effective acceleration over the whole interval.
  final meanAcc = bary2.acceleration(approxPos).mean(calc1.a);

  // Refine the estimates of [pos, vel, acc] at tt2 using the mean acceleration.
  final pos = TerseVector.updatePosition(dt, calc1.r, calc1.v, meanAcc);
  final vel = calc1.v.add(meanAcc.mul(dt));
  final acc = bary2.acceleration(pos);
  final grav = BodyGravCalc(tt2, pos, vel, acc);

  return GravSimT(bary2, grav);
}

GravSimT gravFromState(List entry) {
  final state = bodyStateFromTable(entry);
  final bary = MajorBodies(state.tt);
  final r = state.r.add(bary.Sun.r);
  final v = state.v.add(bary.Sun.v);
  final a = bary.acceleration(r);
  final grav = BodyGravCalc(state.tt, r, v, a);
  return GravSimT(bary, grav);
}

/// Solve for light travel time of a vector function.
///
/// When observing a distant object, for example Jupiter as seen from Earth,
/// the amount of time it takes for light to travel from the object to the
/// observer can significantly affect the object's apparent position.
/// This function is a generic solver that figures out how long in the
/// past light must have left the observed object to reach the observer
/// at the specified observation time. It requires passing in `func`
/// to express an arbitrary position vector as a function of time.
///
/// `CorrectLightTravel` repeatedly calls `func`, passing a series of time
/// estimates in the past. Then `func` must return a relative position vector between
/// the observer and the target. `CorrectLightTravel` keeps calling
/// `func` with more and more refined estimates of the time light must have
/// left the target to arrive at the observer.
///
/// For common use cases, it is simpler to use {@link BackdatePosition}
/// for calculating the light travel time correction of one body observing another body.
///
/// For geocentric calculations, {@link GeoVector} also backdates the returned
/// position vector for light travel time, only it returns the observation time in
/// the returned vector's `t` field rather than the backdated time.
///
/// @param {function(AstroTime): number} func
///      An arbitrary position vector as a function of time:
///      function({@link AstroTime}) =&gt; {@link Vector}.
///
/// @param {AstroTime} time
///      The observation time for which to solve for light travel delay.
///
/// @returns {AstroVector}
///      The position vector at the solved backdated time.
///      The `t` field holds the time that light left the observed
///      body to arrive at the observer at the observation time.
AstroVector correctLightTravel(
    AstroVector Function(AstroTime) func, AstroTime time) {
  var ltime = time;
  var dt = 0.0;
  for (var iter = 0; iter < 10; ++iter) {
    var pos = func(ltime);
    var lt = pos.length() / C_AUDAY;

    // This solver does not support more than one light-day of distance,
    // because that would cause convergence problems and inaccurate
    // values for stellar aberration angles.
    if (lt > 1.0) {
      throw Exception('Object is too distant for light-travel solver.');
    }

    var ltime2 = time.addDays(-lt);
    dt = (ltime2.tt - ltime.tt).abs();
    if (dt < 1.0e-9) {
      // 86.4 microseconds
      return pos;
    }
    ltime = ltime2;
  }
  throw Exception('Light-travel time solver did not converge: dt = $dt');
}

/// Converts a J2000 mean equator (EQJ) vector to a true ecliptic of date (ETC) vector and angles.
///
/// Given coordinates relative to the Earth's equator at J2000 (the instant of noon UTC
/// on 1 January 2000), this function converts those coordinates to true ecliptic coordinates
/// that are relative to the plane of the Earth's orbit around the Sun on that date.
///
/// @param {Vector} eqj
///      Equatorial coordinates in the EQJ frame of reference.
///      You can call {@link GeoVector} to obtain suitable equatorial coordinates.
///
/// @returns {EclipticCoordinates}
EclipticCoordinates ecliptic(AstroVector eqj) {
  // Calculate nutation and obliquity for this time.
  final et = eTilt(eqj.time);

  // Convert mean J2000 equator (EQJ) to true equator of date (EQD).
  final eqjPos = [eqj.x, eqj.y, eqj.z];
  final meanPos = precession(eqjPos, eqj.time, PrecessDirection.From2000);
  final nutatedPos = nutation(meanPos, eqj.time, PrecessDirection.From2000);
  final eqd =
      AstroVector(nutatedPos[0], nutatedPos[1], nutatedPos[2], eqj.time);

  // Rotate from EQD to true ecliptic of date (ECT).
  final tobl = et.tobl * DEG2RAD;
  return EclipticCoordinates.rotateEquatorialToEcliptic(
      eqd, cos(tobl), sin(tobl));
}

/// Calculates spherical ecliptic geocentric position of the Moon.
///
/// Given a time of observation, calculates the Moon's geocentric position
/// in ecliptic spherical coordinates. Provides the ecliptic latitude and
/// longitude in degrees, and the geocentric distance in astronomical units (AU).
///
/// The ecliptic angles are measured in "ECT": relative to the true ecliptic plane and
/// equatorial plane at the specified time. This means the Earth's equator
/// is corrected for precession and nutation, and the plane of the Earth's
/// orbit is corrected for gradual obliquity drift.
///
/// This algorithm is based on the Nautical Almanac Office's <i>Improved Lunar Ephemeris</i> of 1954,
/// which in turn derives from E. W. Brown's lunar theories from the early twentieth century.
/// It is adapted from Turbo Pascal code from the book
/// <a href="https://www.springer.com/us/book/9783540672210">Astronomy on the Personal Computer</a>
/// by Montenbruck and Pfleger.
///
/// To calculate a J2000 mean equator vector instead, use {@link GeoMoon}.
///
/// @param {FlexibleDateTime} date
///      The date and time for which to calculate the Moon's position.
///
/// @returns {Spherical}
Spherical eclipticGeoMoon(dynamic date) {
  var time = AstroTime(date);
  var moon = Moon(time);

  // Convert spherical coordinates to a vector.
  var distCosLat = moon.distance_au * cos(moon.geo_eclip_lat);
  var ecm = [
    distCosLat * cos(moon.geo_eclip_lon),
    distCosLat * sin(moon.geo_eclip_lon),
    moon.distance_au * sin(moon.geo_eclip_lat)
  ];

  // Obtain true and mean obliquity angles for the given time.
  var et = eTilt(time);

  // Convert ecliptic coordinates to equatorial coordinates, both in mean equinox of date.
  var eqm = oblEcl2EquVec(et.mobl, ecm);

  // Add nutation to convert ECM to true equatorial coordinates of date (EQD).
  var eqd = nutation(eqm, time, PrecessDirection.From2000);
  var eqdVec = AstroVector(eqd[0], eqd[1], eqd[2], time);

  // Convert back to ecliptic, this time in true equinox of date (ECT).
  var toblRad = et.tobl * DEG2RAD;
  var cosTobl = cos(toblRad);
  var sinTobl = sin(toblRad);
  var eclip =
      EclipticCoordinates.rotateEquatorialToEcliptic(eqdVec, cosTobl, sinTobl);

  return Spherical(eclip.eLat, eclip.eLon, moon.distance_au);
}

/// Performs a quadratic interpolation to find the time and derivative of a function that crosses zero.
///
/// This function takes the values of a function at three points in time (tm - dt, tm, tm + dt) and
/// uses quadratic interpolation to find the time and derivative of the function when it crosses
/// the zero value.
///
/// @param tm - The middle time point.
/// @param dt - The time step between the three points.
/// @param fa - The function value at tm - dt.
/// @param fm - The function value at tm.
/// @param fb - The function value at tm + dt.
/// @returns An `InterpResult` object containing the time and derivative when the function crosses zero,
///          or `null` if the function does not cross zero in the given interval.
InterpResult? quadInterp(
    double tm, double dt, double fa, double fm, double fb) {
  double Q = (fb + fa) / 2 - fm;
  double R = (fb - fa) / 2;
  double S = fm;
  double x;

  if (Q == 0) {
    // This is a line, not a parabola.
    if (R == 0) {
      // This is a HORIZONTAL line... can't make progress!
      return null;
    }
    x = -S / R;
    if (x < -1 || x > 1) return null; // out of bounds
  } else {
    // It really is a parabola. Find roots x1, x2.
    double u = R * R - 4 * Q * S;
    if (u <= 0) return null;
    double ru = sqrt(u);
    double x1 = (-R + ru) / (2 * Q);
    double x2 = (-R - ru) / (2 * Q);

    if (-1 <= x1 && x1 <= 1) {
      if (-1 <= x2 && x2 <= 1) return null;
      x = x1;
    } else if (-1 <= x2 && x2 <= 1) {
      x = x2;
    } else {
      return null;
    }
  }

  double t = tm + x * dt;
  double dfDt = (2 * Q * x + R) / dt;
  return InterpResult(t, dfDt);
}

/**
 * Options for the {@link Search} function.
 *
 * @typedef {object} SearchOptions
 *
 * @property {number | undefined} dt_tolerance_seconds
 *      The number of seconds for a time window smaller than which the search
 *      is considered successful.  Using too large a tolerance can result in
 *      an inaccurate time estimate.  Using too small a tolerance can cause
 *      excessive computation, or can even cause the search to fail because of
 *      limited floating-point resolution.  Defaults to 1 second.
 *
 * @property {number | undefined} init_f1
 *      As an optimization, if the caller of {@link Search}
 *      has already calculated the value of the function being searched (the parameter `func`)
 *      at the time coordinate `t1`, it can pass in that value as `init_f1`.
 *      For very expensive calculations, this can measurably improve performance.
 *
 * @property {number | undefined} init_f2
 *      The same as `init_f1`, except this is the optional initial value of `func(t2)`
 *      instead of `func(t1)`.
 *
 * @property {number | undefined} iter_limit
 */

/// Finds the time when a function ascends through zero.
///
/// Search for next time <i>t</i> (such that <i>t</i> is between `t1` and `t2`)
/// that `func(t)` crosses from a negative value to a non-negative value.
/// The given function must have "smooth" behavior over the entire inclusive range `[`t1`, `t2`]`,
/// meaning that it behaves like a continuous differentiable function.
/// It is not required that `t1` &lt; `t2`; `t1` &gt; `t2`
/// allows searching backward in time.
/// Note: `t1` and `t2` must be chosen such that there is no possibility
/// of more than one zero-crossing (ascending or descending), or it is possible
/// that the "wrong" event will be found (i.e. not the first event after t1)
/// or even that the function will return `null`, indicating that no event was found.
///
/// @param {function(AstroTime): number} func
///      The function to find an ascending zero crossing for.
///      The function must accept a single parameter of type {@link AstroTime}
///      and return a numeric value:
///      function({@link AstroTime}) =&gt; `number`
///
/// @param {AstroTime} t1
///      The lower time bound of a search window.
///
/// @param {AstroTime} t2
///      The upper time bound of a search window.
///
/// @param {SearchOptions | undefined} options
///      Options that can tune the behavior of the search.
///      Most callers can omit this argument.
///
/// @returns {AstroTime | null}
///      If the search is successful, returns the date and time of the solution.
///      If the search fails, returns `null`.
AstroTime? search(
  AstroTimeFunction f,
  AstroTime t1,
  AstroTime t2, {
  SearchOptions? options,
}) {
  final dtToleranceSeconds = verifyNumber(options?.dtToleranceSeconds ?? 1);
  final dtDays = (dtToleranceSeconds / SECONDS_PER_DAY).abs();

  var f1 = options?.initF1 ?? f(t1);
  var f2 = options?.initF2 ?? f(t2);
  double? fmid;

  var iter = 0;
  final iterLimit = options?.iterLimit ?? 20;
  var calcFmid = true;

  while (true) {
    if (++iter > iterLimit) {
      throw Exception('Excessive iteration in Search()');
    }

    final tmid = AstroTime.interpolateTime(t1, t2, 0.5);
    final dt = tmid.ut - t1.ut;

    if (dt.abs() < dtDays) {
      return tmid;
    }

    if (calcFmid) {
      fmid = f(tmid);
    } else {
      calcFmid = true;
    }

    final q = quadInterp(tmid.ut, t2.ut - tmid.ut, f1, fmid!, f2);

    if (q != null) {
      final tq = AstroTime(q.t);
      final fq = f(tq);

      if (q.dfDt != 0) {
        if ((fq / q.dfDt).abs() < dtDays) {
          return tq;
        }

        final dtGuess = 1.2 * (fq / q.dfDt).abs();
        if (dtGuess < dt / 10) {
          final tleft = tq.addDays(-dtGuess);
          final tright = tq.addDays(dtGuess);

          if ((tleft.ut - t1.ut) * (tleft.ut - t2.ut) < 0) {
            if ((tright.ut - t1.ut) * (tright.ut - t2.ut) < 0) {
              final fleft = f(tleft);
              final fright = f(tright);

              if (fleft < 0 && fright >= 0) {
                f1 = fleft;
                f2 = fright;
                t1 = tleft;
                t2 = tright;
                fmid = fq;
                calcFmid = false;
                continue;
              }
            }
          }
        }
      }
    }

    if (f1 < 0 && fmid >= 0) {
      t2 = tmid;
      f2 = fmid;
      continue;
    }

    if (fmid < 0 && f2 >= 0) {
      t1 = tmid;
      f1 = fmid;
      continue;
    }

    return null;
  }
}

/// Calculates the inverse of an atmospheric refraction angle.
///
/// Given an observed altitude angle that includes atmospheric refraction,
/// calculates the negative angular correction to obtain the unrefracted
/// altitude. This is useful for cases where observed horizontal
/// coordinates are to be converted to another orientation system,
/// but refraction first must be removed from the observed position.
///
/// @param {string} refraction
///      `"normal"`: correct altitude for atmospheric refraction (recommended).
///      `"jplhor"`: for JPL Horizons compatibility testing only; not recommended for normal use.
///      `null`: no atmospheric refraction correction is performed.
///
/// @param {number} bent_altitude
///      The apparent altitude that includes atmospheric refraction.
///
/// @returns {number}
///      The angular adjustment in degrees to be added to the
///      altitude angle to correct for atmospheric lensing.
///      This will be less than or equal to zero.
double inverseRefraction(RefractionType lRefraction, double bentAltitude) {
  if (bentAltitude < -90.0 || bentAltitude > 90.0) {
    return 0.0; // No correction for invalid altitude range
  }

  // Find the pre-adjusted altitude that gives the bent altitude after refraction correction
  double altitude = bentAltitude - refraction(lRefraction, bentAltitude);

  // Iterate until convergence
  while (true) {
    // Calculate the difference from the desired bent altitude
    double diff = (altitude + refraction(lRefraction, altitude)) - bentAltitude;

    // Check for convergence
    if (diff.abs() < 1.0e-14) {
      return altitude - bentAltitude;
    }

    // Update altitude based on the difference
    altitude -= diff;
  }
}
