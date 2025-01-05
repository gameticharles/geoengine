part of 'astronomy.dart';

class NutationAngles {
  double dpsi;
  double deps;

  NutationAngles(this.dpsi, this.deps);
}

/// Calculates the nutation angles for the given [AstroTime].
/// The nutation angles represent the deviation of the true obliquity of the ecliptic
/// from the mean obliquity of the ecliptic.
/// The returned [NutationAngles] contain the nutation in longitude (dpsi) and
/// the nutation in obliquity (deps).
NutationAngles iau2000b(AstroTime time) {
  double mod(double x) {
    return (x % ASEC360) * ASEC2RAD;
  }

  double t = time.tt / 36525.0;
  double elp = mod(1287104.79305 + t * 129596581.0481);
  double f = mod(335779.526232 + t * 1739527262.8478);
  double d = mod(1072260.70369 + t * 1602961601.2090);
  double om = mod(450160.398036 - t * 6962890.5431);

  double sarg = sin(om);
  double carg = cos(om);
  double dp = (-172064161.0 - 174666.0 * t) * sarg + 33386.0 * carg;
  double de = (92052331.0 + 9086.0 * t) * carg + 15377.0 * sarg;

  double arg = 2.0 * (f - d + om);
  sarg = sin(arg);
  carg = cos(arg);
  dp += (-13170906.0 - 1675.0 * t) * sarg - 13696.0 * carg;
  de += (5730336.0 - 3015.0 * t) * carg - 4587.0 * sarg;

  arg = 2.0 * (f + om);
  sarg = sin(arg);
  carg = cos(arg);
  dp += (-2276413.0 - 234.0 * t) * sarg + 2796.0 * carg;
  de += (978459.0 - 485.0 * t) * carg + 1374.0 * sarg;

  arg = 2.0 * om;
  sarg = sin(arg);
  carg = cos(arg);
  dp += (2074554.0 + 207.0 * t) * sarg - 698.0 * carg;
  de += (-897492.0 + 470.0 * t) * carg - 291.0 * sarg;

  sarg = sin(elp);
  carg = cos(elp);
  dp += (1475877.0 - 3633.0 * t) * sarg + 11817.0 * carg;
  de += (73871.0 - 184.0 * t) * carg - 1924.0 * sarg;

  return NutationAngles(-0.000135 + (dp * 1.0e-7), 0.000388 + (de * 1.0e-7));
}

/// Calculates the mean obliquity of the ecliptic for the given [AstroTime].
/// The mean obliquity of the ecliptic is the angle between the plane of the Earth's
/// equator and the plane of the Earth's orbit around the Sun.
///
/// This function uses a polynomial approximation to calculate the mean obliquity
/// in arcseconds, which is then converted to degrees.
///
/// @param time The [AstroTime] for which to calculate the mean obliquity.
/// @return The mean obliquity of the ecliptic in degrees.
double meanObliq(AstroTime time) {
  var t = time.tt / 36525.0;
  var asec =
      (((((-0.0000000434 * t - 0.000000576) * t + 0.00200340) * t - 0.0001831) *
                      t -
                  46.836769) *
              t +
          84381.406);
  return asec / 3600.0;
}

class EarthTiltInfo {
  late double tt;
  late double dpsi;
  late double deps;
  late double ee;
  late double mobl;
  late double tobl;

  EarthTiltInfo({
    required this.tt,
    required this.dpsi,
    required this.deps,
    required this.ee,
    required this.mobl,
    required this.tobl,
  });
}

EarthTiltInfo? cacheETilt;

/// Calculates the Earth's tilt information for the given [AstroTime].
///
/// This function retrieves the nutation angles and mean obliquity of the ecliptic
/// for the given time, and uses them to calculate the true obliquity of the
/// ecliptic and the equation of the equinoxes. The results are cached to avoid
/// redundant calculations.
///
/// @param time The [AstroTime] for which to calculate the Earth's tilt information.
/// @return An [EarthTiltInfo] object containing the calculated tilt information.
EarthTiltInfo eTilt(AstroTime time) {
  if (cacheETilt == null || (cacheETilt!.tt - time.tt).abs() > 1.0e-6) {
    final nut = iau2000b(time);
    final meanOb = meanObliq(time);
    final trueOb = meanOb + (nut.deps / 3600.0);
    final double ee = nut.dpsi * cos(meanOb * DEG2RAD) / 15.0;
    cacheETilt = EarthTiltInfo(
      tt: time.tt,
      dpsi: nut.dpsi,
      deps: nut.deps,
      ee: ee,
      mobl: meanOb,
      tobl: trueOb,
    );
  }
  return cacheETilt!;
}

/// Converts a vector in ecliptic coordinates to a vector in equatorial coordinates
/// for the given obliquity angle.
///
/// @param oblDegrees The obliquity angle in degrees.
/// @param pos A list of 3 doubles representing the vector in ecliptic coordinates.
/// @return A list of 3 doubles representing the vector in equatorial coordinates.
List<double> oblEcl2EquVec(double oblDegrees, List<double> pos) {
  final obl = oblDegrees * DEG2RAD;
  final cosObl = cos(obl);
  final sinObl = sin(obl);

  return [
    pos[0],
    pos[1] * cosObl - pos[2] * sinObl,
    pos[1] * sinObl + pos[2] * cosObl,
  ];
}

/// Converts a vector in ecliptic coordinates to a vector in equatorial coordinates
/// for the given [AstroTime].
///
/// This function uses the mean obliquity of the ecliptic at the given time to
/// perform the coordinate transformation.
///
/// @param time The [AstroTime] for which to perform the coordinate transformation.
/// @param pos A list of 3 doubles representing the vector in ecliptic coordinates.
/// @return A list of 3 doubles representing the vector in equatorial coordinates.
List<double> ecl2equVec(AstroTime time, List<double> pos) {
  return oblEcl2EquVec(meanObliq(time), pos);
}
