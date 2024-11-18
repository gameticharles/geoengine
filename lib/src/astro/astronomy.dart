/*

    Astronomy library for JavaScript (browser and Node.js).
    https://github.com/cosinekitty/astronomy

    MIT License

    Copyright (c) 2019-2023 Don Cross <cosinekitty@gmail.com>

    Permission is hereby granted, free of charge, to any person obtaining a copy
    of this software and associated documentation files (the "Software"), to deal
    in the Software without restriction, including without limitation the rights
    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
    copies of the Software, and to permit persons to whom the Software is
    furnished to do so, subject to the following conditions:

    The above copyright notice and this permission notice shall be included in all
    copies or substantial portions of the Software.

    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
    SOFTWARE.
*/

library astronomy;
import 'package:advance_math/advance_math.dart';

part 'constant.dart';
part 'common.dart';
part 'time/astro_time.dart';
part 'time/sidereal_time.dart';
part 'earth_tilt_info.dart';
part 'other_classes.dart';
part 'season.dart';
part 'apsis.dart';

part 'moon/libration.dart';
part 'moon/moon_phase.dart';
part 'moon/moon.dart';

part 'models/rotation_matrix.dart';
part 'models/state_vector.dart';
part 'models/astro_vector.dart';
part 'models/coordinates.dart';
part 'models/gravity_sim.dart';
part 'models/axis_info.dart';
part 'models/constallation.dart';
part 'models/illumination.dart';

part 'observer.dart';
part 'enums.dart';



/// @brief Returns the product of mass and universal gravitational constant of a Solar System body.
///
/// For problems involving the gravitational interactions of Solar System bodies,
/// it is helpful to know the product GM, where G = the universal gravitational constant
/// and M = the mass of the body. In practice, GM is known to a higher precision than
/// either G or M alone, and thus using the product results in the most accurate results.
/// This function returns the product GM in the units au^3/day^2.
/// The values come from page 10 of a
/// [JPL memorandum regarding the DE405/LE405 ephemeris](https://web.archive.org/web/20120220062549/http://iau-comm4.jpl.nasa.gov/de405iom/de405iom.pdf).
///
/// @param {Body} body
///      The body for which to find the GM product.
///      Allowed to be the Sun, Moon, EMB (Earth/Moon Barycenter), or any planet.
///      Any other value will cause an exception to be thrown.
///
/// @returns {number}
///      The mass product of the given body in au^3/day^2.
double massProduct(Body body) {
  switch (body) {
    case Body.Sun: return SUN_GM;
    case Body.Mercury:return MERCURY_GM;
    case Body.Venus:return VENUS_GM;
    case Body.Earth:return EARTH_GM;
    case Body.Moon:return MOON_GM;
    case Body.EMB:return EARTH_GM + MOON_GM;
    case Body.Mars:return MARS_GM;
    case Body.Jupiter:return JUPITER_GM;
    case Body.Saturn:return SATURN_GM;
    case Body.Uranus:return URANUS_GM;
    case Body.Neptune:return NEPTUNE_GM;
    case Body.Pluto:return PLUTO_GM;
    default:
      throw Exception('Do not know mass product for body: $body');
  }
}


final List<String> StarList = [
    Body.Star1.toString().split('.').last,
    Body.Star2.toString().split('.').last,
    Body.Star3.toString().split('.').last,
    Body.Star4.toString().split('.').last,
    Body.Star5.toString().split('.').last,
    Body.Star6.toString().split('.').last,
    Body.Star7.toString().split('.').last,
    Body.Star8.toString().split('.').last,
  ];

final List<Map<String, double>> StarTable = [
  {"ra": 0, "dec": 0, "dist": 0},// Body.Star1
  {"ra": 0, "dec": 0, "dist": 0},// Body.Star2
  {"ra": 0, "dec": 0, "dist": 0},// Body.Star3
  {"ra": 0, "dec": 0, "dist": 0},// Body.Star4
  {"ra": 0, "dec": 0, "dist": 0},// Body.Star5
  {"ra": 0, "dec": 0, "dist": 0},// Body.Star6
  {"ra": 0, "dec": 0, "dist": 0},// Body.Star7
  {"ra": 0, "dec": 0, "dist": 0},// Body.Star8
];



// Define the getStar function
Map<String, double>? getStar(Body body) {
  int index = StarList.indexOf(body.name);
  return (index >= 0) ? StarTable[index] : null;
}

Map<String, double>? userDefinedStar(Body body) {
  Map<String, double>? star = getStar(body);
  // print(star!=null);
  return (star != null && star["dist"]! > 0) ? star : null;
}

/// @brief Assign equatorial coordinates to a user-defined star.
///
/// Some Astronomy Engine functions allow their `body` parameter to
/// be a user-defined fixed point in the sky, loosely called a "star".
/// This function assigns a right ascension, declination, and distance
/// to one of the eight user-defined stars `Star1`..`Star8`.
///
/// Stars are not valid until defined. Once defined, they retain their
/// definition until re-defined by another call to `DefineStar`.
///
/// @param {Body} body
///      One of the eight user-defined star identifiers:
///      `Star1`, `Star2`, `Star3`, `Star4`, `Star5`, `Star6`, `Star7`, or `Star8`.
///
/// @param {number} ra
///      The right ascension to be assigned to the star, expressed in J2000 equatorial coordinates (EQJ).
///      The value is in units of sidereal hours, and must be within the half-open range [0, 24).
///
/// @param {number} dec
///      The declination to be assigned to the star, expressed in J2000 equatorial coordinates (EQJ).
///      The value is in units of degrees north (positive) or south (negative) of the J2000 equator,
///      and must be within the closed range [-90, +90].
///
/// @param {number} distanceLightYears
///      The distance between the star and the Sun, expressed in light-years.
///      This value is used to calculate the tiny parallax shift as seen by an observer on Earth.
///      If you don't know the distance to the star, using a large value like 1000 will generally work well.
///      The minimum allowed distance is 1 light-year, which is required to provide certain internal optimizations.
void defineStar(Body body, double ra, double dec, double distanceLightYears) {
  Map<String, double>? star = getStar(body);

  if (star == null) {
    throw "Invalid star body: $body";
  }

  verifyNumber(ra);
  verifyNumber(dec);
  verifyNumber(distanceLightYears);

  if (ra < 0 || ra >= 24) {
    throw "Invalid right ascension for star: $ra";
  }

  if (dec < -90 || dec > 90) {
    throw "Invalid declination for star: $dec";
  }

  if (distanceLightYears < 1) {
    throw "Invalid star distance: $distanceLightYears";
  }

  star["ra"] = ra;
  star["dec"] = dec;
  star["dist"] = distanceLightYears * AU_PER_LY;
}

// Dart Map representing PlanetTable
final Map<String, PlanetInfo> planetTable = {
  "Mercury": PlanetInfo(87.969),
  "Venus": PlanetInfo(224.701),
  "Earth": PlanetInfo(365.256),
  "Mars": PlanetInfo(686.980),
  "Jupiter": PlanetInfo(4332.589),
  "Saturn": PlanetInfo(10759.22),
  "Uranus": PlanetInfo(30685.4),
  "Neptune": PlanetInfo(60189.0),
  "Pluto": PlanetInfo(90560.0),
};

EquatorialCoordinates vector2radec(List<double> pos, AstroTime time) {
  AstroVector vec = AstroVector.fromArray(pos, time);
  double xyproj = vec.x * vec.x + vec.y * vec.y;
  double dist = sqrt(xyproj + vec.z * vec.z);

  if (xyproj == 0) {
    if (vec.z == 0) {
      throw 'Indeterminate sky coordinates';
    }
    return EquatorialCoordinates(0, (vec.z < 0) ? -90 : 90, dist, vec);
  }

  double ra = RAD2HOUR * atan2(vec.y, vec.x);
  if (ra < 0) {
    ra += 24;
  }
  double dec = RAD2DEG * atan2(vec.z, sqrt(xyproj));
  return EquatorialCoordinates(ra, dec, dist, vec);
}

List<double> spin(double angle, List<double> pos) {
  final double angr = angle * (pi / 180); // DEG2RAD
  final double c = cos(angr);
  final double s = sin(angr);
  return [
    c * pos[0] + s * pos[1],
    c * pos[1] - s * pos[0],
    pos[2]
  ];
}

/// @brief Calculates the amount of "lift" to an altitude angle caused by atmospheric refraction.
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
double refraction(String? refraction, double altitude) {
  double refr;

  if (altitude < -90.0 || altitude > 90.0) {
    return 0.0; // No attempt to correct an invalid altitude
  }

  if (refraction == 'normal' || refraction == 'jplhor') {
    double hd = altitude;
    if (hd < -1.0) {
      hd = -1.0;
    }

    refr = (1.02 / tan((hd + 10.3 / (hd + 5.11)) * DEG2RAD)) / 60.0;

    if (refraction == 'normal' && altitude < -1.0) {
      refr *= (altitude + 90.0) / 89.0;
    }
  } else if (refraction ==null) {
    refr = 0.0;
  } else {
    throw Exception('Invalid refraction option: $refraction');
  }

  return refr;
}

const double DAYS_PER_MILLENNIUM = 365250.0;
const int LON_INDEX = 0;
const int LAT_INDEX = 1;
const int RAD_INDEX = 2;


double vsopFormula(List<List<List<double>>> formula, double t, bool clampAngle) {
  double tpower = 1;
  double coord = 0;

  for (var series in formula) {
    double sum = 0;
    for (var entry in series) {
      double ampl = entry[0];
      double phas = entry[1];
      double freq = entry[2];
      sum += ampl * cos(phas + (t * freq));
    }
    double incr = tpower * sum;
    if (clampAngle) {
      incr %= PI2; // improve precision for longitudes: they can be hundreds of radians
    }
    coord += incr;
    tpower *= t;
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
    -0.000000479966 * eclip[0] + 0.917482137087 * eclip[1] - 0.397776982902 * eclip[2],
    0.397776982902 * eclip[1] + 0.917482137087 * eclip[2],
  );
}

AstroVector calcVsop(List<List<List<List<double>>>> model, AstroTime time) {
  double t = time.tt / DAYS_PER_MILLENNIUM; // millennia since 2000

  double lon = vsopFormula(model[LON_INDEX], t, true);
  double lat = vsopFormula(model[LAT_INDEX], t, false);
  double rad = vsopFormula(model[RAD_INDEX], t, false);


  List<double> eclip = vsopSphereToRect(lon, lat, rad);
  
  return vsopRotate(eclip).toAstroVector(time);
}
/// @brief Returns apparent geocentric true ecliptic coordinates of date for the Sun.
///
/// This function is used for calculating the times of equinoxes and solstices.
///
/// <i>Geocentric</i> means coordinates as the Sun would appear to a hypothetical observer
/// at the center of the Earth.
/// <i>Ecliptic coordinates of date</i> are measured along the plane of the Earth's mean
/// orbit around the Sun, using the
/// <a href="https://en.wikipedia.org/wiki/Equinox_(celestial_coordinates)">equinox</a>
/// of the Earth as adjusted for precession and nutation of the Earth's
/// axis of rotation on the given date.
///
/// @param {FlexibleDateTime} date
///      The date and time at which to calculate the Sun's apparent location as seen from
///      the center of the Earth.
///
/// @returns {EclipticCoordinates}
EclipticCoordinates sunPosition(dynamic date) {
  // Correct for light travel time from the Sun.
  // This is really the same as correcting for aberration.
  // Otherwise season calculations (equinox, solstice) will all be early by about 8 minutes!
  AstroTime time = AstroTime(date).addDays(-1 / C_AUDAY);

  // Get heliocentric cartesian coordinates of Earth in J2000.
  AstroVector earth2000 = calcVsop(vsopTable["Earth"]!, time);


  // Convert to geocentric location of the Sun.
  List<double> sun2000 = [-earth2000.x, -earth2000.y, -earth2000.z];

  // Convert to equator-of-date equatorial cartesian coordinates.
  List<double> gyrationResult = gyration(sun2000, time, PrecessDirection.From2000);

  // Convert to ecliptic coordinates of date.
  double trueObliq = DEG2RAD * eTilt(time).tobl;
  double cosOb = cos(trueObliq);
  double sinOb = sin(trueObliq);

  AstroVector vec = AstroVector(gyrationResult[0], gyrationResult[1], gyrationResult[2], time);
  EclipticCoordinates sunEcliptic = EclipticCoordinates.rotateEquatorialToEcliptic(vec, cosOb, sinOb);
  return sunEcliptic;
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
/// @ignore
///
/// @brief The state of a body at an incremental step in a gravity simulation.
///
/// This is an internal data structure used to represent the
/// position, velocity, and acceleration vectors of a body
/// in a gravity simulation at a given moment in time.
///
/// @property tt
///      The J2000 terrestrial time of the state [days].
///
/// @property r
///      The position vector [au].
///
/// @property v
///      The velocity vector [au/day].
///
/// @property a
///      The acceleration vector [au/day^2].
class BodyGravCalc {
  double tt;
  TerseVector r;
  TerseVector v;
  TerseVector a;

  BodyGravCalc(this.tt, this.r, this.v, this.a);

  BodyGravCalc clone() {
    return BodyGravCalc(tt, r.clone(), v.clone(), a.clone());
  }
}

BodyState calcVsopPosVel(List<List<List<List<double>>>> model, double tt) {
  final t = tt / DAYS_PER_MILLENNIUM;

  // Calculate the VSOP "B" trigonometric series to obtain ecliptic spherical coordinates.
  final lon = vsopFormula(model[LON_INDEX], t, true);
  final lat = vsopFormula(model[LAT_INDEX], t, false);
  final rad = vsopFormula(model[RAD_INDEX], t, false);

  final dlonDt = vsopDeriv(model[LON_INDEX], t);
  final dlatDt = vsopDeriv(model[LAT_INDEX], t);
  final dradDt = vsopDeriv(model[RAD_INDEX], t);

  // Use spherical coords and spherical derivatives to calculate
  // the velocity vector in rectangular coordinates.
  final coslon = cos(lon);
  final sinlon = sin(lon);
  final coslat = cos(lat);
  final sinlat = sin(lat);

  final vx = (
    (dradDt * coslat * coslon)
    - (rad * sinlat * coslon * dlatDt)
    - (rad * coslat * sinlon * dlonDt)
  );

  final vy = (
    (dradDt * coslat * sinlon)
    - (rad * sinlat * sinlon * dlatDt)
    + (rad * coslat * coslon * dlonDt)
  );

  final vz = (
    (dradDt * sinlat)
    + (rad * coslat * dlatDt)
  );

  final eclipPos = vsopSphereToRect(lon, lat, rad);

  // Convert speed units from [AU/millennium] to [AU/day].
  final List<double> eclipVel =[ 
    vx / DAYS_PER_MILLENNIUM,
    vy / DAYS_PER_MILLENNIUM,
    vz / DAYS_PER_MILLENNIUM
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

class BodyState {
  final double tt;
  final TerseVector r;
  final TerseVector v;

  BodyState(this.tt, this.r, this.v);

  BodyState clone() {
    return BodyState(tt, r.clone(), v.clone());
  }

  BodyState sub(BodyState other) {
    return BodyState(tt, r.sub(other.r), v.sub(other.v));
  }
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

BodyState adjustBarycenterPosVel(BodyState ssb, double tt, Body body, double planetGm) {
  final shift = planetGm / (planetGm + SUN_GM);
  final planet = calcVsopPosVel(vsopTable[body.name]!, tt);
  ssb.r.incr(planet.r.mul(shift));
  ssb.v.incr(planet.v.mul(shift));
  return planet;
}

TerseVector accelerationIncrement(TerseVector smallPos, double gm, TerseVector majorPos) {
  final delta = majorPos.sub(smallPos);
  final r2 = delta.quadrature();
  return delta.mul(gm / (r2 * sqrt(r2)));
}

class MajorBodies {
 late BodyState Jupiter;
  late BodyState Saturn;
  late BodyState Uranus;
  late BodyState Neptune;
  late BodyState Sun;

  MajorBodies(double tt) {
    // Accumulate the Solar System Barycenter position.
    var ssb = BodyState(tt, TerseVector(0, 0, 0), TerseVector(0, 0, 0));

    Jupiter = adjustBarycenterPosVel(ssb, tt, Body.Jupiter, JUPITER_GM);
    Saturn = adjustBarycenterPosVel(ssb, tt, Body.Saturn, SATURN_GM);
    Uranus = adjustBarycenterPosVel(ssb, tt, Body.Uranus, URANUS_GM);
    Neptune = adjustBarycenterPosVel(ssb, tt, Body.Neptune, NEPTUNE_GM);

    // Convert planets' [pos, vel] vectors from heliocentric to barycentric.
    Jupiter.r.decr(ssb.r);
    Jupiter.v.decr(ssb.v);

    Saturn.r.decr(ssb.r);
    Saturn.v.decr(ssb.v);

    Uranus.r.decr(ssb.r);
    Uranus.v.decr(ssb.v);

    Neptune.r.decr(ssb.r);
    Neptune.v.decr(ssb.v);

    // Convert heliocentric SSB to barycentric Sun.
    Sun = BodyState(tt, ssb.r.mul(-1), ssb.v.mul(-1));
  }

  TerseVector acceleration(TerseVector pos) {
    // Use barycentric coordinates of the Sun and major planets to calculate
    // the gravitational acceleration vector experienced at location 'pos'.
    var acc = accelerationIncrement(pos, SUN_GM, Sun.r);
    acc.incr(accelerationIncrement(pos, JUPITER_GM, Jupiter.r));
    acc.incr(accelerationIncrement(pos, SATURN_GM, Saturn.r));
    acc.incr(accelerationIncrement(pos, URANUS_GM, Uranus.r));
    acc.incr(accelerationIncrement(pos, NEPTUNE_GM, Neptune.r));
    return acc;
  }
}

class grav_sim_t {
  MajorBodies bary;
  BodyGravCalc grav;

  grav_sim_t(this.bary, this.grav);
}

grav_sim_t GravSim(double tt2, BodyGravCalc calc1) {
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
  
  return grav_sim_t(bary2, grav);
}


grav_sim_t gravFromState(List entry) {
  final state = bodyStateFromTable(entry);
  final bary = MajorBodies(state.tt);
  final r = state.r.add(bary.Sun.r);
  final v = state.v.add(bary.Sun.v);
  final a = bary.acceleration(r);
  final grav = BodyGravCalc(state.tt, r, v, a);
  return grav_sim_t(bary, grav);
}


final PLUTO_NUM_STATES = 51;
final PLUTO_TIME_STEP  = 29200;
final PLUTO_DT         = 146;
final PLUTO_NSTEPS     = 201;


final List<dynamic> PlutoStateTable = [
    [ -730000.0, [-26.118207232108, -14.376168177825,   3.384402515299], [ 1.6339372163656e-03, -2.7861699588508e-03, -1.3585880229445e-03]]
,   [ -700800.0, [ 41.974905202127,  -0.448502952929, -12.770351505989], [ 7.3458569351457e-04,  2.2785014891658e-03,  4.8619778602049e-04]]
,   [ -671600.0, [ 14.706930780744,  44.269110540027,   9.353698474772], [-2.1000147999800e-03,  2.2295915939915e-04,  7.0143443551414e-04]]
,   [ -642400.0, [-29.441003929957,  -6.430161530570,   6.858481011305], [ 8.4495803960544e-04, -3.0783914758711e-03, -1.2106305981192e-03]]
,   [ -613200.0, [ 39.444396946234,  -6.557989760571, -13.913760296463], [ 1.1480029005873e-03,  2.2400006880665e-03,  3.5168075922288e-04]]
,   [ -584000.0, [ 20.230380950700,  43.266966657189,   7.382966091923], [-1.9754081700585e-03,  5.3457141292226e-04,  7.5929169129793e-04]]
,   [ -554800.0, [-30.658325364620,   2.093818874552,   9.880531138071], [ 6.1010603013347e-05, -3.1326500935382e-03, -9.9346125151067e-04]]
,   [ -525600.0, [ 35.737703251673, -12.587706024764, -14.677847247563], [ 1.5802939375649e-03,  2.1347678412429e-03,  1.9074436384343e-04]]
,   [ -496400.0, [ 25.466295188546,  41.367478338417,   5.216476873382], [-1.8054401046468e-03,  8.3283083599510e-04,  8.0260156912107e-04]]
,   [ -467200.0, [-29.847174904071,  10.636426313081,  12.297904180106], [-6.3257063052907e-04, -2.9969577578221e-03, -7.4476074151596e-04]]
,   [ -438000.0, [ 30.774692107687, -18.236637015304, -14.945535879896], [ 2.0113162005465e-03,  1.9353827024189e-03, -2.0937793168297e-06]]
,   [ -408800.0, [ 30.243153324028,  38.656267888503,   2.938501750218], [-1.6052508674468e-03,  1.1183495337525e-03,  8.3333973416824e-04]]
,   [ -379600.0, [-27.288984772533,  18.643162147874,  14.023633623329], [-1.1856388898191e-03, -2.7170609282181e-03, -4.9015526126399e-04]]
,   [ -350400.0, [ 24.519605196774, -23.245756064727, -14.626862367368], [ 2.4322321483154e-03,  1.6062008146048e-03, -2.3369181613312e-04]]
,   [ -321200.0, [ 34.505274805875,  35.125338586954,   0.557361475637], [-1.3824391637782e-03,  1.3833397561817e-03,  8.4823598806262e-04]]
,   [ -292000.0, [-23.275363915119,  25.818514298769,  15.055381588598], [-1.6062295460975e-03, -2.3395961498533e-03, -2.4377362639479e-04]]
,   [ -262800.0, [ 17.050384798092, -27.180376290126, -13.608963321694], [ 2.8175521080578e-03,  1.1358749093955e-03, -4.9548725258825e-04]]
,   [ -233600.0, [ 38.093671910285,  30.880588383337,  -1.843688067413], [-1.1317697153459e-03,  1.6128814698472e-03,  8.4177586176055e-04]]
,   [ -204400.0, [-18.197852930878,  31.932869934309,  15.438294826279], [-1.9117272501813e-03, -1.9146495909842e-03, -1.9657304369835e-05]]
,   [ -175200.0, [  8.528924039997, -29.618422200048, -11.805400994258], [ 3.1034370787005e-03,  5.1393633292430e-04, -7.7293066202546e-04]]
,   [ -146000.0, [ 40.946857258640,  25.904973592021,  -4.256336240499], [-8.3652705194051e-04,  1.8129497136404e-03,  8.1564228273060e-04]]
,   [ -116800.0, [-12.326958895325,  36.881883446292,  15.217158258711], [-2.1166103705038e-03, -1.4814420035990e-03,  1.7401209844705e-04]]
,   [  -87600.0, [ -0.633258375909, -30.018759794709,  -9.171932874950], [ 3.2016994581737e-03, -2.5279858672148e-04, -1.0411088271861e-03]]
,   [  -58400.0, [ 42.936048423883,  20.344685584452,  -6.588027007912], [-5.0525450073192e-04,  1.9910074335507e-03,  7.7440196540269e-04]]
,   [  -29200.0, [ -5.975910552974,  40.611809958460,  14.470131723673], [-2.2184202156107e-03, -1.0562361130164e-03,  3.3652250216211e-04]]
,   [       0.0, [ -9.875369580774, -27.978926224737,  -5.753711824704], [ 3.0287533248818e-03, -1.1276087003636e-03, -1.2651326732361e-03]]
,   [   29200.0, [ 43.958831986165,  14.214147973292,  -8.808306227163], [-1.4717608981871e-04,  2.1404187242141e-03,  7.1486567806614e-04]]
,   [   58400.0, [  0.678136763520,  43.094461639362,  13.243238780721], [-2.2358226110718e-03, -6.3233636090933e-04,  4.7664798895648e-04]]
,   [   87600.0, [-18.282602096834, -23.305039586660,  -1.766620508028], [ 2.5567245263557e-03, -1.9902940754171e-03, -1.3943491701082e-03]]
,   [  116800.0, [ 43.873338744526,   7.700705617215, -10.814273666425], [ 2.3174803055677e-04,  2.2402163127924e-03,  6.2988756452032e-04]]
,   [  146000.0, [  7.392949027906,  44.382678951534,  11.629500214854], [-2.1932815453830e-03, -2.1751799585364e-04,  5.9556516201114e-04]]
,   [  175200.0, [-24.981690229261, -16.204012851426,   2.466457544298], [ 1.8193989149580e-03, -2.6765419531201e-03, -1.3848283502247e-03]]
,   [  204400.0, [ 42.530187039511,   0.845935508021, -12.554907527683], [ 6.5059779150669e-04,  2.2725657282262e-03,  5.1133743202822e-04]]
,   [  233600.0, [ 13.999526486822,  44.462363044894,   9.669418486465], [-2.1079296569252e-03,  1.7533423831993e-04,  6.9128485798076e-04]]
,   [  262800.0, [-29.184024803031,  -7.371243995762,   6.493275957928], [ 9.3581363109681e-04, -3.0610357109184e-03, -1.2364201089345e-03]]
,   [  292000.0, [ 39.831980671753,  -6.078405766765, -13.909815358656], [ 1.1117769689167e-03,  2.2362097830152e-03,  3.6230548231153e-04]]
,   [  321200.0, [ 20.294955108476,  43.417190420251,   7.450091985932], [-1.9742157451535e-03,  5.3102050468554e-04,  7.5938408813008e-04]]
,   [  350400.0, [-30.669992302160,   2.318743558955,   9.973480913858], [ 4.5605107450676e-05, -3.1308219926928e-03, -9.9066533301924e-04]]
,   [  379600.0, [ 35.626122155983, -12.897647509224, -14.777586508444], [ 1.6015684949743e-03,  2.1171931182284e-03,  1.8002516202204e-04]]
,   [  408800.0, [ 26.133186148561,  41.232139187599,   5.006401326220], [-1.7857704419579e-03,  8.6046232702817e-04,  8.0614690298954e-04]]
,   [  438000.0, [-29.576740229230,  11.863535943587,  12.631323039872], [-7.2292830060955e-04, -2.9587820140709e-03, -7.0824296450300e-04]]
,   [  467200.0, [ 29.910805787391, -19.159019294000, -15.013363865194], [ 2.0871080437997e-03,  1.8848372554514e-03, -3.8528655083926e-05]]
,   [  496400.0, [ 31.375957451819,  38.050372720763,   2.433138343754], [-1.5546055556611e-03,  1.1699815465629e-03,  8.3565439266001e-04]]
,   [  525600.0, [-26.360071336928,  20.662505904952,  14.414696258958], [-1.3142373118349e-03, -2.6236647854842e-03, -4.2542017598193e-04]]
,   [  554800.0, [ 22.599441488648, -24.508879898306, -14.484045731468], [ 2.5454108304806e-03,  1.4917058755191e-03, -3.0243665086079e-04]]
,   [  584000.0, [ 35.877864013014,  33.894226366071,  -0.224524636277], [-1.2941245730845e-03,  1.4560427668319e-03,  8.4762160640137e-04]]
,   [  613200.0, [-21.538149762417,  28.204068269761,  15.321973799534], [-1.7312117409010e-03, -2.1939631314577e-03, -1.6316913275180e-04]]
,   [  642400.0, [ 13.971521374415, -28.339941764789, -13.083792871886], [ 2.9334630526035e-03,  9.1860931752944e-04, -5.9939422488627e-04]]
,   [  671600.0, [ 39.526942044143,  28.939897360110,  -2.872799527539], [-1.0068481658095e-03,  1.7021132888090e-03,  8.3578230511981e-04]]
,   [  700800.0, [-15.576200701394,  34.399412961275,  15.466033737854], [-2.0098814612884e-03, -1.7191109825989e-03,  7.0414782780416e-05]]
,   [  730000.0, [  4.243252837090, -30.118201690825, -10.707441231349], [ 3.1725847067411e-03,  1.6098461202270e-04, -9.0672150593868e-04]]
];

List<BodyGravCalc>? getSegment(List<List<BodyGravCalc>?> cache, double tt) {
  final double t0 = PlutoStateTable[0][0];

  if (tt < t0 || tt > PlutoStateTable[PLUTO_NUM_STATES - 1][0]) {
    // Don't bother calculating a segment. Let the caller crawl backward/forward to this time.
    return null;
  }

  final int segIndex = clampIndex((tt - t0) / PLUTO_TIME_STEP, PLUTO_NUM_STATES - 1);
    for (int i = cache.length; i <= segIndex; i++) {
    cache.add([BodyGravCalc(0, TerseVector(0, 0, 0), TerseVector(0, 0, 0), TerseVector(0, 0, 0))]);
  }


  if (!cache.contains(segIndex)) {
    final List<BodyGravCalc> seg = List<BodyGravCalc>.filled(PLUTO_NSTEPS, BodyGravCalc(0, TerseVector(0, 0, 0), TerseVector(0, 0, 0), TerseVector(0, 0, 0)));
 
    
    cache[segIndex] = seg;

    // Each endpoint is exact.
    seg[0] = gravFromState(PlutoStateTable[segIndex]).grav;
    seg[PLUTO_NSTEPS - 1] = gravFromState(PlutoStateTable[segIndex + 1]).grav;

    // Simulate forwards from the lower time bound.
    double stepTt = seg[0].tt;
    for (int i = 1; i < PLUTO_NSTEPS - 1; ++i) {
      seg[i] = GravSim(stepTt += PLUTO_DT, seg[i - 1]).grav;
    }

    // Simulate backwards from the upper time bound.
    stepTt = seg[PLUTO_NSTEPS - 1].tt;
    final List<BodyGravCalc> reverse = List<BodyGravCalc>.filled(PLUTO_NSTEPS, BodyGravCalc(0, TerseVector(0, 0, 0), TerseVector(0, 0, 0), TerseVector(0, 0, 0)));
    reverse[PLUTO_NSTEPS - 1] = seg[PLUTO_NSTEPS - 1];
    for (int i = PLUTO_NSTEPS - 2; i > 0; --i) {
      reverse[i] = GravSim(stepTt -= PLUTO_DT, reverse[i + 1]).grav;
    }

    // Fade-mix the two series so that there are no discontinuities.
    for (int i = PLUTO_NSTEPS - 2; i > 0; --i) {
      final double ramp = i / (PLUTO_NSTEPS - 1);
      seg[i] = BodyGravCalc(
        seg[i].tt,
        seg[i].r.mul(1 - ramp).add(reverse[i].r.mul(ramp)),
        seg[i].v.mul(1 - ramp).add(reverse[i].v.mul(ramp)),
        seg[i].a.mul(1 - ramp).add(reverse[i].a.mul(ramp)),
      );
    }
  }

  return cache[segIndex];
}


grav_sim_t calcPlutoOneWay(List<dynamic> entry, double targetTt, double dt) {
  var sim = gravFromState(entry);
  final n = ((targetTt - sim.grav.tt) / dt).ceil();
  for (var i = 0; i < n; ++i) {
    sim = GravSim((i + 1 == n) ? targetTt : (sim.grav.tt + dt), sim.grav);
  }
  return sim;
}

StateVector calcPluto(AstroTime time, bool helio) {
  TerseVector r, v;
  MajorBodies? bary;
  final seg = getSegment(plutoCache, time.tt);
  if (seg == null) {
    // The target time is outside the year range 0000..4000.
    // Calculate it by crawling backward from 0000 or forward from 4000.
    // FIXFIXFIX - This is super slow. Could optimize this with extra caching if needed.
    grav_sim_t sim;
    if (time.tt < PlutoStateTable[0][0]) {
      sim = calcPlutoOneWay(PlutoStateTable[0], time.tt, -PLUTO_DT.toDouble());
    } else{
      sim = calcPlutoOneWay(PlutoStateTable[PLUTO_NUM_STATES - 1], time.tt, PLUTO_DT.toDouble());
    }
    r = sim.grav.r;
    v = sim.grav.v;
    bary = sim.bary;
  } else {
    final left = clampIndex((time.tt - seg[0].tt) / PLUTO_DT, PLUTO_NSTEPS - 1);
    final s1 = seg[left];
    final s2 = seg[left + 1];

    // Find mean acceleration vector over the interval.
    final acc = s1.a.mean(s2.a);

    // Use Newtonian mechanics to extrapolate away from t1 in the positive time direction.
    final ra = TerseVector.updatePosition(time.tt - s1.tt, s1.r, s1.v, acc);
    final va = TerseVector.updateVelocity(time.tt - s1.tt, s1.v, acc);

    // Use Newtonian mechanics to extrapolate away from t2 in the negative time direction.
    final rb = TerseVector.updatePosition(time.tt - s2.tt, s2.r, s2.v, acc);
    final vb = TerseVector.updateVelocity(time.tt - s2.tt, s2.v, acc);

    // Use fade in/out idea to blend the two position estimates.
    final ramp = (time.tt - s1.tt) / PLUTO_DT;
    r = ra.mul(1 - ramp).add(rb.mul(ramp));
    v = va.mul(1 - ramp).add(vb.mul(ramp));
  }

  if (helio) {
    // Convert barycentric vectors to heliocentric vectors.
    bary ??= MajorBodies(time.tt);
    r = r.sub(bary.Sun.r);
    v = v.sub(bary.Sun.v);
  }

  return StateVector(r.x, r.y, r.z, v.x, v.y, v.z, time);
}

StateVector exportState(BodyState terse, AstroTime time) {
  return StateVector(terse.r.x, terse.r.y, terse.r.z, terse.v.x, terse.v.y, terse.v.z, time);
}

void adjustBarycenter(AstroVector ssb, AstroTime time, Body body, double pmass) {
  final shift = pmass / (pmass + SUN_GM);
  final planet = calcVsop(vsopTable[body.name]!, time);
  ssb.x += shift * planet.x;
  ssb.y += shift * planet.y;
  ssb.z += shift * planet.z;
}

AstroVector calcSolarSystemBarycenter(AstroTime time) {
  AstroVector ssb = AstroVector(0.0, 0.0, 0.0, time);
  adjustBarycenter(ssb, time, Body.Jupiter, JUPITER_GM);
  adjustBarycenter(ssb, time, Body.Saturn, SATURN_GM);
  adjustBarycenter(ssb, time, Body.Uranus, URANUS_GM);
  adjustBarycenter(ssb, time, Body.Neptune, NEPTUNE_GM);
  return ssb;
}



// Jupiter Moons ends --------------------------------------------------------


/// @brief Calculates a vector from the center of the Sun to the given body at the given time.
///
/// Calculates heliocentric (i.e., with respect to the center of the Sun)
/// Cartesian coordinates in the J2000 equatorial system of a celestial
/// body at a specified time. The position is not corrected for light travel time or aberration.
///
/// @param {Body} body
///      One of the following values:
///      `Body.Sun`, `Body.Moon`, `Body.Mercury`, `Body.Venus`,
///      `Body.Earth`, `Body.Mars`, `Body.Jupiter`, `Body.Saturn`,
///      `Body.Uranus`, `Body.Neptune`, `Body.Pluto`,
///      `Body.SSB`, or `Body.EMB`.
///      Also allowed to be a user-defined star created by {@link DefineStar}.
///
/// @param {FlexibleDateTime} date
///      The date and time for which the body's position is to be calculated.
///
/// @returns {Vector}
AstroVector helioVector(Body body, dynamic date) {
  var time = AstroTime(date);

  if (vsopTable.containsKey(body.name)) {
    return calcVsop(vsopTable[body.name]!, time);
  }
  if (body == Body.Pluto) {
    // print("run");
    var p = calcPluto(time, true);
    return AstroVector(p.x, p.y, p.z, time);
  }
  if (body == Body.Sun) {
    return AstroVector(0, 0, 0, time);
  }
  if (body == Body.Moon) {
    var e = calcVsop(vsopTable["Earth"]!, time);
    var m = Moon(time).geoMoon();
    return AstroVector(e.x + m.x, e.y + m.y, e.z + m.z, time);
  }
  if (body == Body.EMB) {
    var e = calcVsop(vsopTable["Earth"]!, time);
    var m = Moon(time).geoMoon();
    var denom = 1.0 + EARTH_MOON_MASS_RATIO;
    return AstroVector(e.x + (m.x / denom), e.y + (m.y / denom), e.z + (m.z / denom), time);
  }
  if (body == Body.SSB) {
    return calcSolarSystemBarycenter(time);
  }

  var star = userDefinedStar(body);
  if (star != null) {
    var sphere = Spherical(star["dec"]!, 15 * star["ra"]!, star["dist"]!);
    return AstroVector.vectorFromSphere(sphere, time);
  }

  throw Exception('HelioVector: Unknown body "$body"');
}

/// @brief  Calculates heliocentric position and velocity vectors for the given body.
///
/// Given a body and a time, calculates the position and velocity
/// vectors for the center of that body at that time, relative to the center of the Sun.
/// The vectors are expressed in J2000 mean equator coordinates (EQJ).
/// If you need the position vector only, it is more efficient to call {@link HelioVector}.
/// The Sun's center is a non-inertial frame of reference. In other words, the Sun
/// experiences acceleration due to gravitational forces, mostly from the larger
/// planets (Jupiter, Saturn, Uranus, and Neptune). If you want to calculate momentum,
/// kinetic energy, or other quantities that require a non-accelerating frame
/// of reference, consider using {@link BaryState} instead.
///
/// @param {Body} body
///      The celestial body whose heliocentric state vector is to be calculated.
///      Supported values are `Body.Sun`, `Body.Moon`, `Body.EMB`, `Body.SSB`, and all planets:
///      `Body.Mercury`, `Body.Venus`, `Body.Earth`, `Body.Mars`, `Body.Jupiter`,
///      `Body.Saturn`, `Body.Uranus`, `Body.Neptune`, `Body.Pluto`.
///      Also allowed to be a user-defined star created by {@link DefineStar}.
///
///  @param {FlexibleDateTime} date
///      The date and time for which to calculate position and velocity.
///
///  @returns {StateVector}
///      An object that contains heliocentric position and velocity vectors.
StateVector helioState(Body body, dynamic date) {
  var time = AstroTime(date);

  switch (body) {
    case Body.Sun:
      // Trivial case: the Sun is the origin of the heliocentric frame.
      return StateVector(0.0, 0.0, 0.0, 0.0, 0.0, 0.0, time);

    case Body.SSB:
      // Calculate the barycentric Sun. Then the negative of that is the heliocentric SSB.
      var bary = MajorBodies(time.tt);
      return StateVector(
        -bary.Sun.r.x,
        -bary.Sun.r.y,
        -bary.Sun.r.z,
        -bary.Sun.v.x,
        -bary.Sun.v.y,
        -bary.Sun.v.z,
        time,
      );

    case Body.Mercury:
    case Body.Venus:
    case Body.Earth:
    case Body.Mars:
    case Body.Jupiter:
    case Body.Saturn:
    case Body.Uranus:
    case Body.Neptune:
      // Planets included in the VSOP87 model.
      var planet = calcVsopPosVel(vsopTable[body.name]!, time.tt);
      return exportState(planet, time);

    case Body.Pluto:
      return calcPluto(time, true);

    case Body.Moon:
    case Body.EMB:
      var earth = calcVsopPosVel(vsopTable[Body.Earth.toString().split('.').last]!, time.tt);
      var state = (body == Body.Moon) ? Moon.geoMoonState(time) : Moon.geoEmbState(time);
      return StateVector(
        state.x + earth.r.x,
        state.y + earth.r.y,
        state.z + earth.r.z,
        state.vx + earth.v.x,
        state.vy + earth.v.y,
        state.vz + earth.v.z,
        time,
      );

    default:
      var star = userDefinedStar(body);
      if (star != null) {
        var vec = helioVector(body, time);
        return StateVector(vec.x, vec.y, vec.z, 0, 0, 0, time);
      }
      throw Exception('HelioState: Unsupported body "$body"');
  }
}

class BodyPosition {
  final Body observerBody;
  final Body targetBody;
  final bool aberration;
  AstroVector observerPos;

  BodyPosition(this.observerBody, this.targetBody, this.aberration, this.observerPos);

  AstroVector Position(AstroTime time) {
    if (aberration) {
      // Update observer position with aberration correction
      observerPos = helioVector(observerBody, time);
    }
    
    // Calculate target position
    final targetPos = helioVector(targetBody, time);

    // Calculate relative position
    return AstroVector(
      targetPos.x - observerPos.x,
      targetPos.y - observerPos.y,
      targetPos.z - observerPos.z,
      time,
    );
  }
}
/// @brief Solve for light travel time correction of apparent position.
///
/// When observing a distant object, for example Jupiter as seen from Earth,
/// the amount of time it takes for light to travel from the object to the
/// observer can significantly affect the object's apparent position.
///
/// This function solves the light travel time correction for the apparent
/// relative position vector of a target body as seen by an observer body
/// at a given observation time.
///
/// For geocentric calculations, {@link GeoVector} also includes light
/// travel time correction, but the time `t` embedded in its returned vector
/// refers to the observation time, not the backdated time that light left
/// the observed body. Thus `BackdatePosition` provides direct
/// access to the light departure time for callers that need it.
///
/// For a more generalized light travel correction solver, see {@link CorrectLightTravel}.
///
/// @param {FlexibleDateTime} date
///      The time of observation.
///
/// @param {Body} observerBody
///      The body to be used as the observation location.
///
/// @param {Body} targetBody
///      The body to be observed.
///
/// @param {boolean} aberration
///      `true` to correct for aberration, or `false` to leave uncorrected.
///
/// @returns {Vector}
///      The position vector at the solved backdated time.
///      The `t` field holds the time that light left the observed
///      body to arrive at the observer at the observation time.
AstroVector backdatePosition(
    dynamic date,
    Body observerBody,
    Body targetBody,
    bool aberration,
) {
    verifyBoolean(aberration);
    var time = AstroTime(date);

    if (userDefinedStar(targetBody)!=null) {
      
        // Handle user-defined stars as a special case.
        // Assuming heliocentric position does not change with time and is already corrected for light travel time.
        var tvec = helioVector(targetBody, time);

        if (aberration) {
            // Calculate aberration-corrected direction to the target body.
            var ostate = helioState(observerBody, time);
            var rvec = AstroVector(tvec.x - ostate.x, tvec.y - ostate.y, tvec.z - ostate.z, time);
            var s = C_AUDAY / rvec.length(); // Conversion factor from relative distance to speed of light
            return AstroVector(
                rvec.x + ostate.vx / s,
                rvec.y + ostate.vy / s,
                rvec.z + ostate.vz / s,
                time,
            );
        }

        // No correction needed, return the star's current position as seen from the observer.
        var ovec = helioVector(observerBody, time);
        return AstroVector(
            tvec.x - ovec.x,
            tvec.y - ovec.y,
            tvec.z - ovec.z,
            time,
        );
    }

    AstroVector observerPos;
    if (aberration) {
        // With aberration, `BackdatePosition` calculates `observerPos` at different times.
        // Placeholder value will be ignored as it is not calculated yet.
        observerPos = AstroVector(0, 0, 0, time);
    } else {
      
        observerPos = helioVector(observerBody, time);
    }

    // Calculate the position of the target body relative to the observer.
    var bpos = BodyPosition(observerBody, targetBody, aberration, observerPos);
    
    // Correct for light travel time.
    return correctLightTravel((time) => bpos.Position(time), time);
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
AstroVector correctLightTravel(AstroVector Function(AstroTime) func, AstroTime time) {
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
    if (dt < 1.0e-9) { // 86.4 microseconds
      return pos;
    }
    ltime = ltime2;
  }
  throw Exception('Light-travel time solver did not converge: dt = $dt');
}
/// @brief Calculates a vector from the center of the Earth to the given body at the given time.
///
/// Calculates geocentric (i.e., with respect to the center of the Earth)
/// Cartesian coordinates in the J2000 equatorial system of a celestial
/// body at a specified time. The position is always corrected for light travel time:
/// this means the position of the body is "back-dated" based on how long it
/// takes light to travel from the body to an observer on the Earth.
/// Also, the position can optionally be corrected for aberration, an effect
/// causing the apparent direction of the body to be shifted based on
/// transverse movement of the Earth with respect to the rays of light
/// coming from that body.
///
/// @param {Body} body
///      One of the following values:
///      `Body.Sun`, `Body.Moon`, `Body.Mercury`, `Body.Venus`,
///      `Body.Earth`, `Body.Mars`, `Body.Jupiter`, `Body.Saturn`,
///      `Body.Uranus`, `Body.Neptune`, or `Body.Pluto`.
///      Also allowed to be a user-defined star created with {@link DefineStar}.
///
/// @param {FlexibleDateTime} date
///      The date and time for which the body's position is to be calculated.
///
/// @param {boolean} aberration
///      Pass `true` to correct for
///      <a href="https://en.wikipedia.org/wiki/Aberration_of_light">aberration</a>,
///      or `false` to leave uncorrected.
///
/// @returns {Vector}
AstroVector geoVector(
    Body body,
    dynamic date,
    bool aberration,
) {
    verifyBoolean(aberration);
    var time = AstroTime(date);

    switch (body) {
        case Body.Earth:
            return AstroVector(0, 0, 0, time);

        case Body.Moon:
            return Moon(time).geoMoon();

        default:
            var vec = backdatePosition(time, Body.Earth, body, aberration);
            vec.time = time; // Return the observation time, not the backdated time
            return vec;
    }
}
/// @brief Calculates equatorial coordinates of a Solar System body at a given time.
///
/// Returns topocentric equatorial coordinates (right ascension and declination)
/// in one of two different systems: J2000 or true-equator-of-date.
/// Allows optional correction for aberration.
/// Always corrects for light travel time (represents the object as seen by the observer
/// with light traveling to the Earth at finite speed, not where the object is right now).
/// <i>Topocentric</i> refers to a position as seen by an observer on the surface of the Earth.
/// This function corrects for
/// <a href="https://en.wikipedia.org/wiki/Parallax">parallax</a>
/// of the object between a geocentric observer and a topocentric observer.
/// This is most significant for the Moon, because it is so close to the Earth.
/// However, it can have a small effect on the apparent positions of other bodies.
///
/// @param {Body} body
///      The body for which to find equatorial coordinates.
///      Not allowed to be `Body.Earth`.
///
/// @param {FlexibleDateTime} date
///      Specifies the date and time at which the body is to be observed.
///
/// @param {Observer} observer
///      The location on the Earth of the observer.
///
/// @param {bool} ofdate
///      Pass `true` to return equatorial coordinates of date,
///      i.e. corrected for precession and nutation at the given date.
///      This is needed to get correct horizontal coordinates when you call
///      {@link Horizon}.
///      Pass `false` to return equatorial coordinates in the J2000 system.
///
/// @param {bool} aberration
///      Pass `true` to correct for
///      <a href="https://en.wikipedia.org/wiki/Aberration_of_light">aberration</a>,
///      or `false` to leave uncorrected.
///
/// @returns {EquatorialCoordinates}
///      The topocentric coordinates of the body as adjusted for the given observer.
EquatorialCoordinates equator(
    Body body,
    dynamic date,
    Observer observer,
    bool ofdate,
    bool aberration,
) {
    verifyObserver(observer);
    verifyBoolean(ofdate);
    verifyBoolean(aberration);
    
    var time = AstroTime(date);
    var gcObserver = geoPos(time, observer);
    var gc = geoVector(body, time, aberration);
    
    var j2000 = [
        gc.x - gcObserver[0],
        gc.y - gcObserver[1],
        gc.z - gcObserver[2],
    ];

    if (!ofdate) {
      return vector2radec(j2000, time);
    }

    var datevect = gyration(j2000, time, PrecessDirection.From2000);
    return vector2radec(datevect, time);
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
    svec.pos[0], svec.pos[1], svec.pos[2],
    svec.vel[0], svec.vel[1], svec.vel[2],
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
/// @brief Converts a J2000 mean equator (EQJ) vector to a true ecliptic of date (ETC) vector and angles.
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
  final eqd = AstroVector(nutatedPos[0], nutatedPos[1], nutatedPos[2], eqj.time);

  // Rotate from EQD to true ecliptic of date (ECT).
  final tobl = et.tobl * DEG2RAD;
  return EclipticCoordinates.rotateEquatorialToEcliptic(eqd, cos(tobl), sin(tobl));
}

/// @brief Calculates spherical ecliptic geocentric position of the Moon.
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
Spherical EclipticGeoMoon(date) {
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
  var eclip = EclipticCoordinates.rotateEquatorialToEcliptic(eqdVec, cosTobl, sinTobl);

  return Spherical(eclip.elat, eclip.elon, moon.distance_au);
}

class JupiterMoonT {
  final double mu;
  final  List<double> al;
  final List<List<double>> a;
  final List<List<double>> l;
  final List<List<double>> z;
  final List<List<double>> zeta;

  JupiterMoonT({
    required this.mu,
    required this.al,
    required this.a,
    required this.l,
    required this.z,
    required this.zeta,
  });
}

RotationMatrix Rotation_JUP_EQJ =  RotationMatrix([
    [  9.99432765338654e-01, -3.36771074697641e-02,  0.00000000000000e+00 ],
    [  3.03959428906285e-02,  9.02057912352809e-01,  4.30543388542295e-01 ],
    [ -1.44994559663353e-02, -4.30299169409101e-01,  9.02569881273754e-01 ]
]);

final List<JupiterMoonT> JupiterMoonModel  = [JupiterMoonT(
    // [0] Io
    
        mu:  2.8248942843381399e-07,
        al: [ 1.4462132960212239e+00,  3.5515522861824000e+00],
        a: [
            [  0.0028210960212903,  0.0000000000000000e+00,  0.0000000000000000e+00 ]
        ],
        l: [
            [ -0.0001925258348666,  4.9369589722644998e+00,  1.3584836583050000e-02 ],
            [ -0.0000970803596076,  4.3188796477322002e+00,  1.3034138432430000e-02 ],
            [ -0.0000898817416500,  1.9080016428616999e+00,  3.0506486715799999e-03 ],
            [ -0.0000553101050262,  1.4936156681568999e+00,  1.2938928911549999e-02 ]
        ],
        z: [
            [  0.0041510849668155,  4.0899396355450000e+00, -1.2906864146660001e-02 ],
            [  0.0006260521444113,  1.4461888986270000e+00,  3.5515522949801999e+00 ],
            [  0.0000352747346169,  2.1256287034577999e+00,  1.2727416566999999e-04 ]
        ],
        zeta: [
            [  0.0003142172466014,  2.7964219722923001e+00, -2.3150960980000000e-03 ],
            [  0.0000904169207946,  1.0477061879627001e+00, -5.6920638196000003e-04 ]
        ]
    ),

    // [1] Europa
    JupiterMoonT(
        mu:  2.8248327439289299e-07,
        al: [-3.7352634374713622e-01,  1.7693227111234699e+00],
        a: [
            [  0.0044871037804314,  0.0000000000000000e+00,  0.0000000000000000e+00 ],
            [  0.0000004324367498,  1.8196456062910000e+00,  1.7822295777568000e+00 ]
        ],
        l: [
            [  0.0008576433172936,  4.3188693178264002e+00,  1.3034138308049999e-02 ],
            [  0.0004549582875086,  1.4936531751079001e+00,  1.2938928819619999e-02 ],
            [  0.0003248939825174,  1.8196494533458001e+00,  1.7822295777568000e+00 ],
            [ -0.0003074250079334,  4.9377037005910998e+00,  1.3584832867240000e-02 ],
            [  0.0001982386144784,  1.9079869054759999e+00,  3.0510121286900001e-03 ],
            [  0.0001834063551804,  2.1402853388529000e+00,  1.4500978933800000e-03 ],
            [ -0.0001434383188452,  5.6222140366630002e+00,  8.9111478887838003e-01 ],
            [ -0.0000771939140944,  4.3002724372349999e+00,  2.6733443704265998e+00 ]
        ],
        z: [
            [ -0.0093589104136341,  4.0899396509038999e+00, -1.2906864146660001e-02 ],
            [  0.0002988994545555,  5.9097265185595003e+00,  1.7693227079461999e+00 ],
            [  0.0002139036390350,  2.1256289300016000e+00,  1.2727418406999999e-04 ],
            [  0.0001980963564781,  2.7435168292649998e+00,  6.7797343008999997e-04 ],
            [  0.0001210388158965,  5.5839943711203004e+00,  3.2056614899999997e-05 ],
            [  0.0000837042048393,  1.6094538368039000e+00, -9.0402165808846002e-01 ],
            [  0.0000823525166369,  1.4461887708689001e+00,  3.5515522949801999e+00 ]
        ],
        zeta: [
            [  0.0040404917832303,  1.0477063169425000e+00, -5.6920640539999997e-04 ],
            [  0.0002200421034564,  3.3368857864364001e+00, -1.2491307306999999e-04 ],
            [  0.0001662544744719,  2.4134862374710999e+00,  0.0000000000000000e+00 ],
            [  0.0000590282470983,  5.9719930968366004e+00, -3.0561602250000000e-05 ]
        ]
    ),

    // [2] Ganymede
    JupiterMoonT(
        mu:  2.8249818418472298e-07,
        al: [ 2.8740893911433479e-01,  8.7820792358932798e-01],
        a: [
            [  0.0071566594572575,  0.0000000000000000e+00,  0.0000000000000000e+00 ],
            [  0.0000013930299110,  1.1586745884981000e+00,  2.6733443704265998e+00 ]
        ],
        l: [
            [  0.0002310797886226,  2.1402987195941998e+00,  1.4500978438400001e-03 ],
            [ -0.0001828635964118,  4.3188672736968003e+00,  1.3034138282630000e-02 ],
            [  0.0001512378778204,  4.9373102372298003e+00,  1.3584834812520000e-02 ],
            [ -0.0001163720969778,  4.3002659861490002e+00,  2.6733443704265998e+00 ],
            [ -0.0000955478069846,  1.4936612842567001e+00,  1.2938928798570001e-02 ],
            [  0.0000815246854464,  5.6222137132535002e+00,  8.9111478887838003e-01 ],
            [ -0.0000801219679602,  1.2995922951532000e+00,  1.0034433456728999e+00 ],
            [ -0.0000607017260182,  6.4978769669238001e-01,  5.0172167043264004e-01 ]
        ],
        z: [
            [  0.0014289811307319,  2.1256295942738999e+00,  1.2727413029000001e-04 ],
            [  0.0007710931226760,  5.5836330003496002e+00,  3.2064341100000001e-05 ],
            [  0.0005925911780766,  4.0899396636447998e+00, -1.2906864146660001e-02 ],
            [  0.0002045597496146,  5.2713683670371996e+00, -1.2523544076106000e-01 ],
            [  0.0001785118648258,  2.8743156721063001e-01,  8.7820792442520001e-01 ],
            [  0.0001131999784893,  1.4462127277818000e+00,  3.5515522949801999e+00 ],
            [ -0.0000658778169210,  2.2702423990985001e+00, -1.7951364394536999e+00 ],
            [  0.0000497058888328,  5.9096792204858000e+00,  1.7693227129285001e+00 ]
        ],
        zeta: [
            [  0.0015932721570848,  3.3368862796665000e+00, -1.2491307058000000e-04 ],
            [  0.0008533093128905,  2.4133881688166001e+00,  0.0000000000000000e+00 ],
            [  0.0003513347911037,  5.9720789850126996e+00, -3.0561017709999999e-05 ],
            [ -0.0001441929255483,  1.0477061764435001e+00, -5.6920632124000004e-04 ]
        ]
    ),

    // [3] Callisto
    JupiterMoonT(
        mu:  2.8249214488990899e-07,
        al: [-3.6203412913757038e-01,  3.7648623343382798e-01],
        a: [
            [  0.0125879701715314,  0.0000000000000000e+00,  0.0000000000000000e+00 ],
            [  0.0000035952049470,  6.4965776007116005e-01,  5.0172168165034003e-01 ],
            [  0.0000027580210652,  1.8084235781510001e+00,  3.1750660413359002e+00 ]
        ],
        l: [
            [  0.0005586040123824,  2.1404207189814999e+00,  1.4500979323100001e-03 ],
            [ -0.0003805813868176,  2.7358844897852999e+00,  2.9729650620000000e-05 ],
            [  0.0002205152863262,  6.4979652596399995e-01,  5.0172167243580001e-01 ],
            [  0.0001877895151158,  1.8084787604004999e+00,  3.1750660413359002e+00 ],
            [  0.0000766916975242,  6.2720114319754998e+00,  1.3928364636651001e+00 ],
            [  0.0000747056855106,  1.2995916202344000e+00,  1.0034433456728999e+00 ]
        ],
        z: [
            [  0.0073755808467977,  5.5836071576083999e+00,  3.2065099140000001e-05 ],
            [  0.0002065924169942,  5.9209831565786004e+00,  3.7648624194703001e-01 ],
            [  0.0001589869764021,  2.8744006242622999e-01,  8.7820792442520001e-01 ],
            [ -0.0001561131605348,  2.1257397865089001e+00,  1.2727441285000001e-04 ],
            [  0.0001486043380971,  1.4462134301023000e+00,  3.5515522949801999e+00 ],
            [  0.0000635073108731,  5.9096803285953996e+00,  1.7693227129285001e+00 ],
            [  0.0000599351698525,  4.1125517584797997e+00, -2.7985797954588998e+00 ],
            [  0.0000540660842731,  5.5390350845569003e+00,  2.8683408228299999e-03 ],
            [ -0.0000489596900866,  4.6218149483337996e+00, -6.2695712529518999e-01 ]
        ],
        zeta: [
            [  0.0038422977898495,  2.4133922085556998e+00,  0.0000000000000000e+00 ],
            [  0.0022453891791894,  5.9721736773277003e+00, -3.0561255249999997e-05 ],
            [ -0.0002604479450559,  3.3368746306408998e+00, -1.2491309972000001e-04 ],
            [  0.0000332112143230,  5.5604137742336999e+00,  2.9003768850700000e-03 ]
        ]
    )
];

/// @brief Holds the positions and velocities of Jupiter's major 4 moons.
///
/// The {@link JupiterMoons} function returns an object of this type
/// to report position and velocity vectors for Jupiter's largest 4 moons
/// Io, Europa, Ganymede, and Callisto. Each position vector is relative
/// to the center of Jupiter. Both position and velocity are oriented in
/// the EQJ system (that is, using Earth's equator at the J2000 epoch).
/// The positions are expressed in astronomical units (AU),
/// and the velocities in AU/day.
///
/// @property {StateVector} io
///      The position and velocity of Jupiter's moon Io.
///
/// @property {StateVector} europa
///      The position and velocity of Jupiter's moon Europa.
///
/// @property {StateVector} ganymede
///      The position and velocity of Jupiter's moon Ganymede.
///
/// @property {StateVector} callisto
///      The position and velocity of Jupiter's moon Callisto.
class JupiterMoonsInfo {
  final StateVector io;
  final StateVector europa;
  final StateVector ganymede;
  final StateVector callisto;

  JupiterMoonsInfo({
    required this.io,
    required this.europa,
    required this.ganymede,
    required this.callisto,
  });
}

StateVector JupiterMoon_elem2pv(
    AstroTime time,
    double mu,
    List<double> elem) {

  // Dart doesn't support destructuring directly in function parameters like TypeScript,
  // so accessing elements from the list directly by index.

  double A = elem[0];
  double AL = elem[1];
  double K = elem[2];
  double H = elem[3];
  double Q = elem[4];
  double P = elem[5];

  double AN = sqrt(mu / (A * A * A));

  double CE, SE, DE;
  double EE = AL + K * sin(AL) - H * cos(AL);
  do {
    CE = cos(EE);
    SE = sin(EE);
    DE = (AL - EE + K * SE - H * CE) / (1.0 - K * CE - H * SE);
    EE += DE;
  } while (DE.abs() >= 1.0e-12);

  CE = cos(EE);
  SE = sin(EE);
  double DLE = H * CE - K * SE;
  double RSAM1 = -K * CE - H * SE;
  double ASR = 1.0 / (1.0 + RSAM1);
  double PHI = sqrt(1.0 - K * K - H * H);
  double PSI = 1.0 / (1.0 + PHI);
  double X1 = A * (CE - K - PSI * H * DLE);
  double Y1 = A * (SE - H + PSI * K * DLE);
  double VX1 = AN * ASR * A * (-SE - PSI * H * RSAM1);
  double VY1 = AN * ASR * A * (CE + PSI * K * RSAM1);
  double F2 = 2.0 * sqrt(1.0 - Q * Q - P * P);
  double P2 = 1.0 - 2.0 * P * P;
  double Q2 = 1.0 - 2.0 * Q * Q;
  double PQ = 2.0 * P * Q;

  return StateVector(
    X1 * P2 + Y1 * PQ,
    X1 * PQ + Y1 * Q2,
    (Q * Y1 - X1 * P) * F2,
    VX1 * P2 + VY1 * PQ,
    VX1 * PQ + VY1 * Q2,
    (Q * VY1 - VX1 * P) * F2,
    time,
  );
}

StateVector CalcJupiterMoon(AstroTime time, JupiterMoonT m) {
  final double t = time.tt + 18262.5; // number of days since 1950-01-01T00:00:00Z

  // Calculate 6 orbital elements at the given time t
  List<double> elem = [0, m.al[0] + (t * m.al[1]), 0, 0, 0, 0];

  for (var term in m.a) {
    double amplitude = term[0];
    double phase = term[1];
    double frequency = term[2];
    elem[0] += amplitude * cos(phase + (t * frequency));
  }

  for (var term in m.l) {
    double amplitude = term[0];
    double phase = term[1];
    double frequency = term[2];
    elem[1] += amplitude * sin(phase + (t * frequency));
  }

  elem[1] %= PI2;
  if (elem[1] < 0) elem[1] += PI2;

  for (var term in m.z) {
    double amplitude = term[0];
    double phase = term[1];
    double frequency = term[2];
    double arg = phase + (t * frequency);
    elem[2] += amplitude * cos(arg);
    elem[3] += amplitude * sin(arg);
  }

  for (var term in m.zeta) {
    double amplitude = term[0];
    double phase = term[1];
    double frequency = term[2];
    double arg = phase + (t * frequency);
    elem[4] += amplitude * cos(arg);
    elem[5] += amplitude * sin(arg);
  }

  // Convert the orbital elements into position vectors in the Jupiter equatorial system (JUP).
  StateVector state = JupiterMoon_elem2pv(time, m.mu, elem);

  // Re-orient position and velocity vectors from Jupiter-equatorial (JUP) to Earth-equatorial in J2000 (EQJ).
  return StateVector.rotateState(Rotation_JUP_EQJ, state);
}

/// @brief Calculates jovicentric positions and velocities of Jupiter's largest 4 moons.
///
/// Calculates position and velocity vectors for Jupiter's moons
/// Io, Europa, Ganymede, and Callisto, at the given date and time.
/// The vectors are jovicentric (relative to the center of Jupiter).
/// Their orientation is the Earth's equatorial system at the J2000 epoch (EQJ).
/// The position components are expressed in astronomical units (AU), and the
/// velocity components are in AU/day.
///
/// To convert to heliocentric vectors, call {@link HelioVector}
/// with `Astronomy.Body.Jupiter` to get Jupiter's heliocentric position, then
/// add the jovicentric vectors. Likewise, you can call {@link GeoVector}
/// to convert to geocentric vectors.
///
/// @param {FlexibleDateTime} date
///      The date and time for which to calculate Jupiter's moons.
///
/// @return {JupiterMoonsInfo}
///      Position and velocity vectors of Jupiter's largest 4 moons.
JupiterMoonsInfo JupiterMoons(dynamic date) {
  AstroTime time = AstroTime(date);

 return JupiterMoonsInfo(
    io: CalcJupiterMoon(time, JupiterMoonModel[0]),
    europa: CalcJupiterMoon(time, JupiterMoonModel[1]),
    ganymede: CalcJupiterMoon(time, JupiterMoonModel[2]),
    callisto: CalcJupiterMoon(time, JupiterMoonModel[3]),
  );
}
/// @brief Calculates the distance between a body and the Sun at a given time.
///
/// Given a date and time, this function calculates the distance between
/// the center of `body` and the center of the Sun.
/// For the planets Mercury through Neptune, this function is significantly
/// more efficient than calling {@link HelioVector} followed by taking the length
/// of the resulting vector.
///
/// @param {Body} body
///      A body for which to calculate a heliocentric distance:
///      the Sun, Moon, any of the planets, or a user-defined star.
///
/// @param {FlexibleDateTime} date
///      The date and time for which to calculate the heliocentric distance.
///
/// @returns {number}
///      The heliocentric distance in AU.
double HelioDistance(Body body, dynamic date) {

  var star = userDefinedStar(body); // Assuming userDefinedStar function is defined elsewhere
  if (star != null) {
    return star['dist']!;
  }

  var time = AstroTime(date); // Assuming AstroTime function is defined elsewhere
  if (vsopTable.containsKey(body.name)) {
    return vsopFormula(vsopTable[body.name]![RAD_INDEX], time.tt / DAYS_PER_MILLENNIUM, false);
  }

  return helioVector(body, time).length();
}

/// @brief  Calculates barycentric position and velocity vectors for the given body.
///
/// Given a body and a time, calculates the barycentric position and velocity
/// vectors for the center of that body at that time.
/// The vectors are expressed in J2000 mean equator coordinates (EQJ).
///
/// @param {Body} body
///      The celestial body whose barycentric state vector is to be calculated.
///      Supported values are `Body.Sun`, `Body.Moon`, `Body.EMB`, `Body.SSB`, and all planets:
///      `Body.Mercury`, `Body.Venus`, `Body.Earth`, `Body.Mars`, `Body.Jupiter`,
///      `Body.Saturn`, `Body.Uranus`, `Body.Neptune`, `Body.Pluto`.
///
/// @param {FlexibleDateTime} date
///      The date and time for which to calculate position and velocity.
///
///  @returns {StateVector}
///      An object that contains barycentric position and velocity vectors.
StateVector baryState(Body body, dynamic date) {
  final time = AstroTime(date);

  if (body == Body.SSB) {
    // Trivial case: the solar system barycenter itself.
    return StateVector(0, 0, 0, 0, 0, 0, time);
  }

  if (body == Body.Pluto) {
    return calcPluto(time, false);
  }

  // Find the barycentric positions and velocities for the 5 major bodies:
  // Sun, Jupiter, Saturn, Uranus, Neptune.
  final bary = MajorBodies(time.tt);
  // print(bary);

  switch (body) {
    case Body.Sun:
      return exportState(bary.Sun, time);
    case Body.Jupiter:
      return exportState(bary.Jupiter, time);
    case Body.Saturn:
      return exportState(bary.Saturn, time);
    case Body.Uranus:
      return exportState(bary.Uranus, time);
    case Body.Neptune:
      return exportState(bary.Neptune, time);
    case Body.Moon:
    case Body.EMB:
      final earth = calcVsopPosVel(vsopTable[Body.Earth..toString().split('.').last]!, time.tt);
      final state = (body == Body.Moon) ? Moon.geoMoonState(time) : Moon.geoEmbState(time);
      return StateVector(
        state.x + bary.Sun.r.x + earth.r.x,
        state.y + bary.Sun.r.y + earth.r.y,
        state.z + bary.Sun.r.z + earth.r.z,
        state.vx + bary.Sun.v.x + earth.v.x,
        state.vy + bary.Sun.v.y + earth.v.y,
        state.vz + bary.Sun.v.z + earth.v.z,
        time,
      );
    case _:
      // Handle the remaining VSOP bodies: Mercury, Venus, Earth, Mars.
      if (vsopTable.containsKey(body.name)) {
        
        // print(vsopTable.containsKey(body.name));
        final planet = calcVsopPosVel(vsopTable[body.name]!, time.tt);
        return StateVector(
          bary.Sun.r.x + planet.r.x,
          bary.Sun.r.y + planet.r.y,
          bary.Sun.r.z + planet.r.z,
          bary.Sun.v.x + planet.v.x,
          bary.Sun.v.y + planet.v.y,
          bary.Sun.v.z + planet.v.z,
          time,
        );
      }

  }

  throw Exception('BaryState: Unsupported body "$body"');
}

class InterpResult {
  final double t;
  final double dfDt;

  InterpResult(this.t, this.dfDt);
}

InterpResult? quadInterp(double tm, double dt, double fa, double fm, double fb) {
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
// Quirk: for some reason, I need to put the interface declaration *before* its
// documentation, or jsdoc2md will strip it out.

class SearchOptions {
  final double? dtToleranceSeconds;
  final double? initF1;
  final double? initF2;
  final int? iterLimit;

  SearchOptions({
    this.dtToleranceSeconds,
    this.initF1,
    this.initF2,
    this.iterLimit,
  });
}


typedef AstroTimeFunction = double Function(AstroTime t);
/**
 * @brief Options for the {@link Search} function.
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

/// @brief Finds the time when a function ascends through zero.
///
/// Search for next time <i>t</i> (such that <i>t</i> is between `t1` and `t2`)
/// that `func(t)` crosses from a negative value to a non-negative value.
/// The given function must have "smooth" behavior over the entire inclusive range [`t1`, `t2`],
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
AstroTime? search (
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


/// @brief Searches for when the Sun reaches a given ecliptic longitude.
///
/// Searches for the moment in time when the center of the Sun reaches a given apparent
/// ecliptic longitude, as seen from the center of the Earth, within a given range of dates.
/// This function can be used to determine equinoxes and solstices.
/// However, it is usually more convenient and efficient to call {@link Seasons}
/// to calculate equinoxes and solstices for a given calendar year.
/// `SearchSunLongitude` is more general in that it allows searching for arbitrary longitude values.
///
/// @param {number} targetLon
///      The desired ecliptic longitude of date in degrees.
///      This may be any value in the range [0, 360), although certain
///      values have conventional meanings:
///
///      When `targetLon` is 0, finds the March equinox,
///      which is the moment spring begins in the northern hemisphere
///      and the beginning of autumn in the southern hemisphere.
///
///      When `targetLon` is 180, finds the September equinox,
///      which is the moment autumn begins in the northern hemisphere and
///      spring begins in the southern hemisphere.
///
///      When `targetLon` is 90, finds the northern solstice, which is the
///      moment summer begins in the northern hemisphere and winter
///      begins in the southern hemisphere.
///
///      When `targetLon` is 270, finds the southern solstice, which is the
///      moment winter begins in the northern hemisphere and summer
///      begins in the southern hemisphere.
///
/// @param {FlexibleDateTime} dateStart
///      A date and time known to be earlier than the desired longitude event.
///
/// @param {number} limitDays
///      A floating point number of days, which when added to `dateStart`,
///      yields a date and time known to be after the desired longitude event.
///
/// @returns {AstroTime | null}
///      The date and time when the Sun reaches the apparent ecliptic longitude `targetLon`
///      within the range of times specified by `dateStart` and `limitDays`.
///      If the Sun does not reach the target longitude within the specified time range, or the
///      time range is excessively wide, the return value is `null`.
///      To avoid a `null` return value, the caller must pick a time window around
///      the event that is within a few days but not so small that the event might fall outside the window.
AstroTime? searchSunLongitude(double targetLon, dynamic dateStart, double limitDays) {
  double sunOffset(AstroTime t) {
    final pos = sunPosition(t);
  
    return LongitudeOffset(pos.elon - targetLon);
  }

  verifyNumber(targetLon);
  verifyNumber(limitDays);

  final t1 = AstroTime(dateStart);
  final t2 = t1.addDays(limitDays);

  return search(sunOffset, t1, t2,options:SearchOptions(dtToleranceSeconds: 0.01));
}

/// @brief Returns one body's ecliptic longitude with respect to another, as seen from the Earth.
///
/// This function determines where one body appears around the ecliptic plane
/// (the plane of the Earth's orbit around the Sun) as seen from the Earth,
/// relative to the another body's apparent position.
/// The function returns an angle in the half-open range [0, 360) degrees.
/// The value is the ecliptic longitude of `body1` relative to the ecliptic
/// longitude of `body2`.
///
/// The angle is 0 when the two bodies are at the same ecliptic longitude
/// as seen from the Earth. The angle increases in the prograde direction
/// (the direction that the planets orbit the Sun and the Moon orbits the Earth).
///
/// When the angle is 180 degrees, it means the two bodies appear on opposite sides
/// of the sky for an Earthly observer.
///
/// Neither `body1` nor `body2` is allowed to be `Body.Earth`.
/// If this happens, the function throws an exception.
///
/// @param {Body} body1
///      The first body, whose longitude is to be found relative to the second body.
///
/// @param {Body} body2
///      The second body, relative to which the longitude of the first body is to be found.
///
/// @param {FlexibleDateTime} date
///      The date and time of the observation.
///
/// @returns {number}
///      An angle in the range [0, 360), expressed in degrees.
double pairLongitude(Body body1, Body body2, dynamic date) {
  if (body1 == Body.Earth || body2 == Body.Earth) {
    throw Exception('The Earth does not have a longitude as seen from itself.');
  }

  final time = AstroTime(date);

  final vector1 = geoVector(body1, time, false);
  final eclip1 = ecliptic(vector1);

  final vector2 = geoVector(body2, time, false);
  final eclip2 = ecliptic(vector2);

  return NormalizeLongitude(eclip1.elon - eclip2.elon);
}

/// @brief Calculates the angular separation between the Sun and the given body.
///
/// Returns the full angle seen from
/// the Earth, between the given body and the Sun.
/// Unlike {@link PairLongitude}, this function does not
/// project the body's "shadow" onto the ecliptic;
/// the angle is measured in 3D space around the plane that
/// contains the centers of the Earth, the Sun, and `body`.
///
/// @param {Body} body
///      The name of a supported celestial body other than the Earth.
///
/// @param {FlexibleDateTime} date
///      The time at which the angle from the Sun is to be found.
///
/// @returns {number}
///      An angle in degrees in the range [0, 180].
double angleFromSun(Body body, dynamic date) {
  if (body == Body.Earth) {
    throw Exception('The Earth does not have an angle as seen from itself.');
  }

  final time = AstroTime(date);
  final sv = geoVector(Body.Sun, time, true);
  final bv = geoVector(body, time, true);
  final angle = angleBetween(sv, bv);
  return angle;
}
/// @brief Calculates heliocentric ecliptic longitude of a body.
///
/// This function calculates the angle around the plane of the Earth's orbit
/// of a celestial body, as seen from the center of the Sun.
/// The angle is measured prograde (in the direction of the Earth's orbit around the Sun)
/// in degrees from the true equinox of date. The ecliptic longitude is always in the range [0, 360).
///
/// @param {Body} body
///      A body other than the Sun.
///
/// @param {FlexibleDateTime} date
///      The date and time for which to calculate the ecliptic longitude.
///
/// @returns {number}
double eclipticLongitude(Body body, dynamic date) {
  if (body == Body.Sun) {
    throw Exception('Cannot calculate heliocentric longitude of the Sun.');
  }

  final time = AstroTime(date);
  final hv = helioVector(body, time);
  final eclip = ecliptic(hv);
  return eclip.elon;
}

double log10(num x) => log(x) / ln10;

double visualMagnitude(Body body, double phase, double helioDist, double geoDist) {
  double c0, c1 = 0, c2 = 0, c3 = 0;

  switch (body) {
    case Body.Mercury:
      c0 = -0.60;
      c1 = 4.98;
      c2 = -4.88;
      c3 = 3.02;
      break;
    case Body.Venus:
      if (phase < 163.6) {
        c0 = -4.47;
        c1 = 1.03;
        c2 = 0.57;
        c3 = 0.13;
      } else {
        c0 = 0.98;
        c1 = -1.02;
      }
      break;
    case Body.Mars:
      c0 = -1.52;
      c1 = 1.60;
      break;
    case Body.Jupiter:
      c0 = -9.40;
      c1 = 0.50;
      break;
    case Body.Uranus:
      c0 = -7.19;
      c1 = 0.25;
      break;
    case Body.Neptune:
      c0 = -6.87;
      break;
    case Body.Pluto:
      c0 = -1.00;
      c1 = 4.00;
      break;
    default:
      throw Exception('VisualMagnitude: unsupported body $body');
  }

  double x = phase / 100;
  double mag = c0 + x * (c1 + x * (c2 + x * c3));
  mag += 5 * log10(helioDist * geoDist);
  return mag;
}

class SaturnMagnitudeResult {
  double mag;
  double ringTilt;

  SaturnMagnitudeResult(this.mag, this.ringTilt);
}

SaturnMagnitudeResult saturnMagnitude(double phase, double helioDist, double geoDist, AstroVector gc, AstroTime time) {
  // Based on formulas by Paul Schlyter found here:
  // http://www.stjarnhimlen.se/comp/ppcomp.html#15

  // We must handle Saturn's rings as a major component of its visual magnitude.
  // Find geocentric ecliptic coordinates of Saturn.
  final eclip = ecliptic(gc);
  double ir = DEG2RAD * 28.06;   // tilt of Saturn's rings to the ecliptic, in radians
  double Nr = DEG2RAD * (169.51 + (3.82e-5 * time.tt));    // ascending node of Saturn's rings, in radians

  // Find tilt of Saturn's rings, as seen from Earth.
  double lat = DEG2RAD * eclip.elat;
  double lon = DEG2RAD * eclip.elon;
  double tilt = asin(sin(lat) * cos(ir) - cos(lat) * sin(ir) * sin(lon - Nr));
  double sinTilt = sin(tilt.abs());

  double mag = -9.0 + 0.044 * phase;
  mag += sinTilt * (-2.6 + 1.2 * sinTilt);
  mag += 5 * log(helioDist * geoDist);

  return SaturnMagnitudeResult(mag, RAD2DEG * tilt);
}



double synodicPeriod(Body body) {
  if (body == Body.Earth) {
    throw Exception('The Earth does not have a synodic period as seen from itself.');
  }

  if (body == Body.Moon) {
    return MEAN_SYNODIC_MONTH;
  }

  final planetName = body.name;
  final planetInfo = planetTable[planetName];
  if (planetInfo == null) {
    throw Exception('Not a valid planet name: $planetName');
  }

  final earthOrbitalPeriod = planetTable['Earth']!.orbitalPeriod;
  final synodicPeriod = (earthOrbitalPeriod / (earthOrbitalPeriod / planetInfo.orbitalPeriod - 1)).abs();

  return synodicPeriod;
}
/// @brief Searches for when the Earth and a given body reach a relative ecliptic longitude separation.
///
/// Searches for the date and time the relative ecliptic longitudes of
/// the specified body and the Earth, as seen from the Sun, reach a certain
/// difference. This function is useful for finding conjunctions and oppositions
/// of the planets. For the opposition of a superior planet (Mars, Jupiter, ..., Pluto),
/// or the inferior conjunction of an inferior planet (Mercury, Venus),
/// call with `targetRelLon` = 0. The 0 value indicates that both
/// planets are on the same ecliptic longitude line, ignoring the other planet's
/// distance above or below the plane of the Earth's orbit.
/// For superior conjunctions, call with `targetRelLon` = 180.
/// This means the Earth and the other planet are on opposite sides of the Sun.
///
/// @param {Body} body
///      Any planet other than the Earth.
///
/// @param {number} targetRelLon
///      The desired angular difference in degrees between the ecliptic longitudes
///      of `body` and the Earth. Must be in the range (-180, +180].
///
/// @param {FlexibleDateTime} startDate
///      The date and time after which to find the next occurrence of the
///      body and the Earth reaching the desired relative longitude.
///
/// @returns {AstroTime}
///      The time when the Earth and the body next reach the specified relative longitudes.
AstroTime searchRelativeLongitude(Body body, double targetRelLon, dynamic startDate) {
  verifyNumber(targetRelLon);
  final planet = planetTable[body.name]!;
  if (body == Body.Earth) {
    throw Exception('Cannot search relative longitude for the Earth (it is always 0).');
  }

  final direction = planet.orbitalPeriod > planetTable["Earth"]!.orbitalPeriod? 1 : -1;

  double offset(AstroTime t) {
    final plon = eclipticLongitude(body, t);
    final elon = eclipticLongitude(Body.Earth, t);
    final diff = direction * (elon - plon);
    return LongitudeOffset(diff - targetRelLon);
  }

  var syn = synodicPeriod(body);
  var time = AstroTime(startDate);

  var errorAngle = offset(time);
  if (errorAngle > 0) errorAngle -= 360;

  for (var iter = 0; iter < 100; ++iter) {
    var dayAdjust = (-errorAngle / 360) * syn;
    time = time.addDays(dayAdjust);
    if ((dayAdjust * SECONDS_PER_DAY).abs() < 1) {
      return time;
    }

    var prevAngle = errorAngle;
    errorAngle = offset(time);

    if (prevAngle.abs() < 30) {
      if (prevAngle != errorAngle) {
        var ratio = prevAngle / (prevAngle - errorAngle);
        if (ratio > 0.5 && ratio < 2.0) {
          syn *= ratio;
        }
      }
    }
  }

  throw Exception('Relative longitude search failed to converge for $body near ${time.toString()} (error_angle = $errorAngle).');
}

/// @brief Information about idealized atmospheric variables at a given elevation.
///
/// @property {number} pressure
///      Atmospheric pressure in pascals.
///
/// @property {number} temperature
///      Atmospheric temperature in kelvins.
///
/// @property {number} density
///      Atmospheric density relative to sea level.
class AtmosphereInfo {
  final double pressure;
  final double temperature;
  final double density;

  AtmosphereInfo(this.pressure, this.temperature, this.density);
}
/// @brief Calculates U.S. Standard Atmosphere (1976) variables as a function of elevation.
///
/// This function calculates idealized values of pressure, temperature, and density
/// using the U.S. Standard Atmosphere (1976) model.
/// 1. COESA, U.S. Standard Atmosphere, 1976, U.S. Government Printing Office, Washington, DC, 1976.
/// 2. Jursa, A. S., Ed., Handbook of Geophysics and the Space Environment, Air Force Geophysics Laboratory, 1985.
/// See:
/// https://hbcp.chemnetbase.com/faces/documents/14_12/14_12_0001.xhtml
/// https://ntrs.nasa.gov/api/citations/19770009539/downloads/19770009539.pdf
/// https://www.ngdc.noaa.gov/stp/space-weather/online-publications/miscellaneous/us-standard-atmosphere-1976/us-standard-atmosphere_st76-1562_noaa.pdf
///
/// @param {number} elevationMeters
///      The elevation above sea level at which to calculate atmospheric variables.
///      Must be in the range -500 to +100000, or an exception will occur.
///
/// @returns {AtmosphereInfo}
AtmosphereInfo atmosphere(double elevationMeters) {
  const double P0 = 101325.0;     // pressure at sea level [pascals]
  const double T0 = 288.15;       // temperature at sea level [kelvins]
  const double T1 = 216.65;       // temperature between 20 km and 32 km [kelvins]

  if (!elevationMeters.isFinite || elevationMeters < -500.0 || elevationMeters > 100000.0) {
    throw Exception('Invalid elevation: $elevationMeters');
  }

  double temperature;
  double pressure;
  if (elevationMeters <= 11000.0) {
    temperature = T0 - 0.0065 * elevationMeters;
    pressure = P0 * pow(T0 / temperature, -5.25577);
  } else if (elevationMeters <= 20000.0) {
    temperature = T1;
    pressure = 22632.0 * exp(-0.00015768832 * (elevationMeters - 11000.0));
  } else {
    temperature = T1 + 0.001 * (elevationMeters - 20000.0);
    pressure = 5474.87 * pow(T1 / temperature, 34.16319);
  }

  // Calculate density relative to sea level value
  final density = (pressure / temperature) / (P0 / T0);

  return AtmosphereInfo(pressure, temperature, density);
}

double horizonDipAngle(Observer observer, double metersAboveGround) {
  // Calculate the effective radius of the Earth at ground level below the observer.
  // Correct for the Earth's oblateness.
  double phi = observer.latitude * DEG2RAD;
  double sinphi = sin(phi);
  double cosphi = cos(phi);
  double c = 1.0 / hypot(cosphi, sinphi * EARTH_FLATTENING);
  double s = c * (EARTH_FLATTENING * EARTH_FLATTENING);
  double htKm = (observer.height - metersAboveGround) / 1000.0; // height of ground above sea level
  double ach = EARTH_EQUATORIAL_RADIUS_KM * c + htKm;
  double ash = EARTH_EQUATORIAL_RADIUS_KM * s + htKm;
  double radiusM = 1000.0 * hypot(ach * cosphi, ash * sinphi);

  // Correct refraction of a ray of light traveling tangent to the Earth's surface.
  // Based on: https://www.largeformatphotography.info/sunmooncalc/SMCalc.js
  // which in turn derives from:
  // Sweer, John. 1938.  The Path of a Ray of Light Tangent to the Surface of the Earth.
  // Journal of the Optical Society of America 28 (September):327-329.

  // k = refraction index
  double k = 0.175 * pow(1.0 - (6.5e-3 / 283.15) * (observer.height - (2.0 / 3.0) * metersAboveGround), 3.256);

  // Calculate how far below the observer's horizontal plane the observed horizon dips.
  return RAD2DEG * -(sqrt(2 * (1 - k) * metersAboveGround / radiusM) / (1 - k));
}

double bodyRadiusAu(Body body) {
  // For the purposes of calculating rise/set times,
  // only the Sun and Moon appear large enough to an observer
  // on the Earth for their radius to matter.
  // All other bodies are treated as points.
  switch (body) {
    case Body.Sun:
      return SUN_RADIUS_AU;
    case Body.Moon:
      return MOON_EQUATORIAL_RADIUS_AU;
    default:
      return 0;
  }
}

double maxAltitudeSlope(Body body, double latitude) {
  // Calculate the maximum possible rate that this body's altitude
  // could change [degrees/day] as seen by this observer.
  // First use experimentally determined extreme bounds for this body
  // of how much topocentric RA and DEC can ever change per rate of time.
  // We need minimum possible d(RA)/dt, and maximum possible magnitude of d(DEC)/dt.
  // Conservatively, we round d(RA)/dt down, d(DEC)/dt up.
  // Then calculate the resulting maximum possible altitude change rate.

  if (latitude < -90 || latitude > 90) {
    throw Exception('Invalid geographic latitude: $latitude');
  }

  double derivRa;
  double derivDec;

  switch (body) {
    case Body.Moon:
      derivRa = 4.5;
      derivDec = 8.2;
      break;

    case Body.Sun:
      derivRa = 0.8;
      derivDec = 0.5;
      break;

    case Body.Mercury:
      derivRa = -1.6;
      derivDec = 1.0;
      break;

    case Body.Venus:
      derivRa = -0.8;
      derivDec = 0.6;
      break;

    case Body.Mars:
      derivRa = -0.5;
      derivDec = 0.4;
      break;

    case Body.Jupiter:
    case Body.Saturn:
    case Body.Uranus:
    case Body.Neptune:
    case Body.Pluto:
      derivRa = -0.2;
      derivDec = 0.2;
      break;

    case Body.Star1:
    case Body.Star2:
    case Body.Star3:
    case Body.Star4:
    case Body.Star5:
    case Body.Star6:
    case Body.Star7:
    case Body.Star8:
      // The minimum allowed heliocentric distance of a user-defined star
      // is one light-year. This can cause a tiny amount of parallax (about 0.001 degrees).
      // Also, including stellar aberration (22 arcsec = 0.006 degrees), we provide a
      // generous safety buffer of 0.008 degrees.
      derivRa = -0.008;
      derivDec = 0.008;
      break;

    default:
      throw Exception('Body not allowed for altitude search: $body');
  }

  final latrad = DEG2RAD * latitude;
  return (360.0 / SOLAR_DAYS_PER_SIDEREAL_DAY - derivRa).abs() * cos(latrad) + derivDec.abs() * sin(latrad);
}

class AscentInfo {
  final AstroTime tx;
  final AstroTime ty;
  final double ax;
  final double ay;

  AscentInfo(this.tx, this.ty, this.ax, this.ay);
}

AscentInfo? findAscent(
    int depth,
    double Function(AstroTime t) altdiff,
    double maxDerivAlt,
    AstroTime t1,
    AstroTime t2,
    double a1,
    double a2) {
  
  // See if we can find any time interval where the altitude-diff function
  // rises from non-positive to positive.

  if (a1 < 0.0 && a2 >= 0.0) {
    // Trivial success case: the endpoints already rise through zero.
    return AscentInfo(t1, t2, a1, a2);
  }

  if (a1 >= 0.0 && a2 < 0.0) {
    // Trivial failure case: Assume Nyquist condition prevents an ascent.
    return null;
  }

  if (depth > 17) {
    // Safety valve: do not allow unlimited recursion.
    // This should never happen if the rest of the logic is working correctly,
    // so fail the whole search if it does happen. It's a bug!
    throw Exception('Excessive recursion in rise/set ascent search.');
  }

  // Both altitudes are on the same side of zero: both are negative, or both are non-negative.
  // There could be a convex "hill" or a concave "valley" that passes through zero.
  // In polar regions sometimes there is a rise/set or set/rise pair within minutes of each other.
  // For example, the Moon can be below the horizon, then the very top of it becomes
  // visible (moonrise) for a few minutes, then it moves sideways and down below
  // the horizon again (moonset). We want to catch these cases.
  // However, for efficiency and practicality concerns, because the rise/set search itself
  // has a 0.1 second threshold, we do not worry about rise/set pairs that are less than
  // one second apart. These are marginal cases that are rendered highly uncertain
  // anyway, due to unpredictable atmospheric refraction conditions (air temperature and pressure).

  final dt = t2.ut - t1.ut;
  if (dt * SECONDS_PER_DAY < 1.0) {
    return null;
  }

  // Is it possible to reach zero from the altitude that is closer to zero?
  final da = a1.abs().compareTo(a2.abs()) <= 0 ? a1.abs() : a2.abs();

  // Without loss of generality, assume |a1| <= |a2|.
  // (Reverse the argument in the case |a2| < |a1|.)
  // Imagine you have to "drive" from a1 to 0, then back to a2.
  // You can't go faster than max_deriv_alt. If you can't reach 0 in half the time,
  // you certainly don't have time to reach 0, turn around, and still make your way
  // back up to a2 (which is at least as far from 0 than a1 is) in the time interval dt.
  // Therefore, the time threshold is half the time interval, or dt/2.
  if (da > maxDerivAlt * (dt / 2)) {
    // Prune: the altitude cannot change fast enough to reach zero.
    return null;
  }

  // Bisect the time interval and evaluate the altitude at the midpoint.
  final tmid = AstroTime((t1.ut + t2.ut) / 2);
  final amid = altdiff(tmid);

  // Use recursive bisection to search for a solution bracket.
  return findAscent(
          depth + 1, altdiff, maxDerivAlt, t1, tmid, a1, amid) ??
      findAscent(depth + 1, altdiff, maxDerivAlt, tmid, t2, amid, a2);
}

// Define InternalSearchAltitude function
AstroTime? internalSearchAltitude(
    Body body,
    Observer observer,
    double direction,
    dynamic dateStart,
    double limitDays,
    double bodyRadiusAu,
    double targetAltitude) {
  
  if (targetAltitude < -90 || targetAltitude > 90) {
    throw Exception('Invalid target altitude angle: $targetAltitude');
  }

  const riseSetDt = 0.42; // 10.08 hours: Nyquist-safe for 22-hour period.
  final maxDerivAlt = maxAltitudeSlope(body, observer.latitude);

  double altdiff(AstroTime time) {
    final ofdate = equator(body, time, observer, true, true);
    final hor = HorizontalCoordinates.horizon(time, observer, ofdate.ra, ofdate.dec);
    final altitude = hor.altitude + toDegrees(asin(bodyRadiusAu / ofdate.dist));
    return direction * (altitude - targetAltitude);
  }
  final startTime = AstroTime(dateStart);
  var t1 = startTime;
  var t2 = startTime;
  var a1 = altdiff(t1);
  var a2 = a1;

  for (;;) {
    if (limitDays < 0.0) {
      t1 = AstroTime(t2.ut - riseSetDt);
      a1 = altdiff(t1);
    } else {
      t2 = AstroTime(t1.ut + riseSetDt);
      a2 = altdiff(t2);
    }

    final ascent = findAscent(0, altdiff, maxDerivAlt, t1, t2, a1, a2);
    if (ascent != null) {
      final time = search(altdiff, ascent.tx, ascent.ty, options: SearchOptions(
        dtToleranceSeconds: 0.1,
        initF1: ascent.ax,
        initF2: ascent.ay,
      ));

      if (time != null) {
        if (limitDays < 0.0) {
          if (time.ut < startTime.ut + limitDays) return null;
        } else {
          if (time.ut > startTime.ut + limitDays) return null;
        }
        return time; // success!
      }

      throw Exception('Rise/set search failed after finding ascent: t1=$t1, t2=$t2, a1=$a1, a2=$a2');
    }

    if (limitDays < 0.0) {
      if (t1.ut < startTime.ut + limitDays) return null;
      t2 = t1;
      a2 = a1;
    } else {
      if (t2.ut > startTime.ut + limitDays) return null;
      t1 = t2;
      a1 = a2;
    }
  }
}
/// @brief Searches for the next time a celestial body rises or sets as seen by an observer on the Earth.
///
/// This function finds the next rise or set time of the Sun, Moon, or planet other than the Earth.
/// Rise time is when the body first starts to be visible above the horizon.
/// For example, sunrise is the moment that the top of the Sun first appears to peek above the horizon.
/// Set time is the moment when the body appears to vanish below the horizon.
/// Therefore, this function adjusts for the apparent angular radius of the observed body
/// (significant only for the Sun and Moon).
///
/// This function corrects for a typical value of atmospheric refraction, which causes celestial
/// bodies to appear higher above the horizon than they would if the Earth had no atmosphere.
/// Astronomy Engine uses a correction of 34 arcminutes. Real-world refraction varies based
/// on air temperature, pressure, and humidity; such weather-based conditions are outside
/// the scope of Astronomy Engine.
///
/// Note that rise or set may not occur in every 24 hour period.
/// For example, near the Earth's poles, there are long periods of time where
/// the Sun stays below the horizon, never rising.
/// Also, it is possible for the Moon to rise just before midnight but not set during the subsequent 24-hour day.
/// This is because the Moon sets nearly an hour later each day due to orbiting the Earth a
/// significant amount during each rotation of the Earth.
/// Therefore callers must not assume that the function will always succeed.
///
/// @param {Body} body
///      The Sun, Moon, any planet other than the Earth,
///      or a user-defined star that was created by a call to {@link DefineStar}.
///
/// @param {Observer} observer
///      Specifies the geographic coordinates and elevation above sea level of the observer.
///
/// @param {number} direction
///      Either +1 to find rise time or -1 to find set time.
///      Any other value will cause an exception to be thrown.
///
/// @param {FlexibleDateTime} dateStart
///      The date and time after which the specified rise or set time is to be found.
///
/// @param {number} limitDays
///      Limits how many days to search for a rise or set time, and defines
///      the direction in time to search. When `limitDays` is positive, the
///      search is performed into the future, after `dateStart`.
///      When negative, the search is performed into the past, before `dateStart`.
///      To limit a rise or set time to the same day, you can use a value of 1 day.
///      In cases where you want to find the next rise or set time no matter how far
///      in the future (for example, for an observer near the south pole), you can
///      pass in a larger value like 365.
///
/// @param {number?} metersAboveGround
///      Defaults to 0.0 if omitted.
///      Usually the observer is located at ground level. Then this parameter
///      should be zero. But if the observer is significantly higher than ground
///      level, for example in an airplane, this parameter should be a positive
///      number indicating how far above the ground the observer is.
///      An exception occurs if `metersAboveGround` is negative.
///
/// @returns {AstroTime | null}
///      The date and time of the rise or set event, or null if no such event
///      occurs within the specified time window.
AstroTime? searchRiseSet(Body body, Observer observer, double direction, dynamic dateStart, double limitDays, {double metersAboveGround = 0.0}) {
  if (!metersAboveGround.isFinite || metersAboveGround < 0.0) {
    throw Exception('Invalid value for metersAboveGround: $metersAboveGround');
  }

  // We want to find when the top of the body crosses the horizon, not the body's center.
  // Therefore, we need to know the body's radius.
  double bodyRadiusAuValue = bodyRadiusAu(body);

  // Calculate atmospheric density at ground level.
  AtmosphereInfo atmos = atmosphere(observer.height - metersAboveGround);

  // Calculate the apparent angular dip of the horizon.
  double dip = horizonDipAngle(observer, metersAboveGround);

  // Correct refraction for objects near the horizon, using atmospheric density at the ground.
  double altitude = dip - (REFRACTION_NEAR_HORIZON * atmos.density);

  // Search for the top of the body crossing the corrected altitude angle.
  return internalSearchAltitude(body, observer, direction, dateStart, limitDays, bodyRadiusAuValue, altitude);
}

/// @brief Finds the next time the center of a body passes through a given altitude.
///
/// Finds when the center of the given body ascends or descends through a given
/// altitude angle, as seen by an observer at the specified location on the Earth.
/// By using the appropriate combination of `direction` and `altitude` parameters,
/// this function can be used to find when civil, nautical, or astronomical twilight
/// begins (dawn) or ends (dusk).
///
/// Civil dawn begins before sunrise when the Sun ascends through 6 degrees below
/// the horizon. To find civil dawn, pass +1 for `direction` and -6 for `altitude`.
///
/// Civil dusk ends after sunset when the Sun descends through 6 degrees below the horizon.
/// To find civil dusk, pass -1 for `direction` and -6 for `altitude`.
///
/// Nautical twilight is similar to civil twilight, only the `altitude` value should be -12 degrees.
///
/// Astronomical twilight uses -18 degrees as the `altitude` value.
///
/// By convention for twilight time calculations, the altitude is not corrected for
/// atmospheric refraction. This is because the target altitudes are below the horizon,
/// and refraction is not directly observable.
///
/// `SearchAltitude` is not intended to find rise/set times of a body for two reasons:
/// (1) Rise/set times of the Sun or Moon are defined by their topmost visible portion, not their centers.
/// (2) Rise/set times are affected significantly by atmospheric refraction.
/// Therefore, it is better to use {@link SearchRiseSet} to find rise/set times, which
/// corrects for both of these considerations.
///
/// `SearchAltitude` will not work reliably for altitudes at or near the body's
/// maximum or minimum altitudes. To find the time a body reaches minimum or maximum altitude
/// angles, use {@link SearchHourAngle}.
///
/// @param {Body} body
///      The Sun, Moon, any planet other than the Earth,
///      or a user-defined star that was created by a call to {@link DefineStar}.
///
/// @param {Observer} observer
///      Specifies the geographic coordinates and elevation above sea level of the observer.
///
/// @param {number} direction
///      Either +1 to find when the body ascends through the altitude,
///      or -1 for when the body descends through the altitude.
///      Any other value will cause an exception to be thrown.
///
/// @param {FlexibleDateTime} dateStart
///      The date and time after which the specified altitude event is to be found.
///
/// @param {number} limitDays
///      Limits how many days to search for the body reaching the altitude angle,
///      and defines the direction in time to search. When `limitDays` is positive, the
///      search is performed into the future, after `dateStart`.
///      When negative, the search is performed into the past, before `dateStart`.
///      To limit the search to the same day, you can use a value of 1 day.
///      In cases where you want to find the altitude event no matter how far
///      in the future (for example, for an observer near the south pole), you can
///      pass in a larger value like 365.
///
/// @param {number} altitude
///      The desired altitude angle of the body's center above (positive)
///      or below (negative) the observer's local horizon, expressed in degrees.
///      Must be in the range [-90, +90].
///
/// @returns {AstroTime | null}
///      The date and time of the altitude event, or null if no such event
///      occurs within the specified time window.
AstroTime? searchAltitude(
  Body body,
  Observer observer,
  double direction,
  dynamic dateStart,
  double limitDays,
  double altitude) {
  
  if (!altitude.isFinite || altitude < -90 || altitude > 90) {
    throw Exception('Invalid altitude angle: $altitude');
  }

  return internalSearchAltitude(body, observer, direction, dateStart, limitDays, 0, altitude);
}

/// @brief Horizontal position of a body upon reaching an hour angle.
///
/// Returns information about an occurrence of a celestial body
/// reaching a given hour angle as seen by an observer at a given
/// location on the surface of the Earth.
///
/// @property {AstroTime} time
///      The date and time of the celestial body reaching the hour angle.
///
/// @property {HorizontalCoordinates} hor
///      Topocentric horizontal coordinates for the body
///      at the time indicated by the `time` property.
class HourAngleEvent {
  AstroTime time;
  HorizontalCoordinates hor;

  HourAngleEvent(this.time, this.hor);
}

/// @brief Searches for the time when the center of a body reaches a specified hour angle as seen by an observer on the Earth.
///
/// The *hour angle* of a celestial body indicates its position in the sky with respect
/// to the Earth's rotation. The hour angle depends on the location of the observer on the Earth.
/// The hour angle is 0 when the body's center reaches its highest angle above the horizon in a given day.
/// The hour angle increases by 1 unit for every sidereal hour that passes after that point, up
/// to 24 sidereal hours when it reaches the highest point again. So the hour angle indicates
/// the number of hours that have passed since the most recent time that the body has culminated,
/// or reached its highest point.
///
/// This function searches for the next or previous time a celestial body reaches the given hour angle
/// relative to the date and time specified by `dateStart`.
/// To find when a body culminates, pass 0 for `hourAngle`.
/// To find when a body reaches its lowest point in the sky, pass 12 for `hourAngle`.
///
/// Note that, especially close to the Earth's poles, a body as seen on a given day
/// may always be above the horizon or always below the horizon, so the caller cannot
/// assume that a culminating object is visible nor that an object is below the horizon
/// at its minimum altitude.
///
/// The function returns the date and time, along with the horizontal coordinates
/// of the body at that time, as seen by the given observer.
///
/// @param {Body} body
///      The Sun, Moon, any planet other than the Earth,
///      or a user-defined star that was created by a call to {@link DefineStar}.
///
/// @param {Observer} observer
///      Specifies the geographic coordinates and elevation above sea level of the observer.
///
/// @param {number} hourAngle
///      The hour angle expressed in
///      <a href="https://en.wikipedia.org/wiki/Sidereal_time">sidereal</a>
///      hours for which the caller seeks to find the body attain.
///      The value must be in the range [0, 24).
///      The hour angle represents the number of sidereal hours that have
///      elapsed since the most recent time the body crossed the observer's local
///      <a href="https://en.wikipedia.org/wiki/Meridian_(astronomy)">meridian</a>.
///      This specifying `hourAngle` = 0 finds the moment in time
///      the body reaches the highest angular altitude in a given sidereal day.
///
/// @param {FlexibleDateTime} dateStart
///      The date and time after which the desired hour angle crossing event
///      is to be found.
///
/// @param {number} direction
///      The direction in time to perform the search: a positive value
///      searches forward in time, a negative value searches backward in time.
///      The function throws an exception if `direction` is zero.
///
/// @returns {HourAngleEvent}
HourAngleEvent searchHourAngle(
  Body body,
  Observer observer,
  double hourAngle,
  dynamic dateStart,
  {double direction = 1}
) {
  verifyObserver(observer);
  var time = AstroTime(dateStart);
  var iter = 0;

  if (body == Body.Earth) {
    throw Exception('Cannot search for hour angle of the Earth.');
  }

  verifyNumber(hourAngle);
  if (hourAngle < 0.0 || hourAngle >= 24.0) {
    throw Exception('Invalid hour angle $hourAngle');
  }

  verifyNumber(direction);
  if (direction == 0) {
    throw Exception('Direction must be positive or negative.');
  }

  while (true) {
    iter++;

    // Calculate Greenwich Apparent Sidereal Time (GAST) at the given time.
    var gast = siderealTime(time);

    var ofdate = equator(body, time, observer, true, true);

    // Calculate the adjustment needed in sidereal time to bring
    // the hour angle to the desired value.
    var deltaSiderealHours = ((hourAngle + ofdate.ra - observer.longitude / 15) - gast) % 24;
    if (iter == 1) {
      // On the first iteration, always search in the requested time direction.
      if (direction > 0) {
        // Search forward in time.
        if (deltaSiderealHours < 0) {
          deltaSiderealHours += 24;
        }
      } else {
        // Search backward in time.
        if (deltaSiderealHours > 0) {
          deltaSiderealHours -= 24;
        }
      }
    } else {
      // On subsequent iterations, we make the smallest possible adjustment,
      // either forward or backward in time.
      if (deltaSiderealHours < -12) {
        deltaSiderealHours += 24;
      } else if (deltaSiderealHours > 12) {
        deltaSiderealHours -= 24;
      }
    }

    // If the error is tolerable (less than 0.1 seconds), stop searching.
    if ((deltaSiderealHours.abs() * 3600) < 0.1) {
      var hor = HorizontalCoordinates.horizon(time, observer, ofdate.ra, ofdate.dec, 'normal');
      return HourAngleEvent(time, hor);
    }

    // We need to loop another time to get more accuracy.
    // Update the terrestrial time adjusting by sidereal time.
    var deltaDays = (deltaSiderealHours / 24) * SOLAR_DAYS_PER_SIDEREAL_DAY;
    time = time.addDays(deltaDays);
  }
}
/// @brief Finds the hour angle of a body for a given observer and time.
///
/// The *hour angle* of a celestial body indicates its position in the sky with respect
/// to the Earth's rotation. The hour angle depends on the location of the observer on the Earth.
/// The hour angle is 0 when the body's center reaches its highest angle above the horizon in a given day.
/// The hour angle increases by 1 unit for every sidereal hour that passes after that point, up
/// to 24 sidereal hours when it reaches the highest point again. So the hour angle indicates
/// the number of hours that have passed since the most recent time that the body has culminated,
/// or reached its highest point.
///
/// This function returns the hour angle of the body as seen at the given time and geogrpahic location.
/// The hour angle is a number in the half-open range [0, 24).
///
/// @param {Body} body
///      The body whose observed hour angle is to be found.
///
/// @param {FlexibleDateTime} date
///      The date and time of the observation.
///
/// @param {Observer} observer
///      The geographic location where the observation takes place.
///
/// @returns {number}
double hourAngle(Body body, dynamic date, Observer observer) {
  final time = AstroTime(date);
  
  
  final gast = siderealTime(time);

  final ofdate = equator(body, time, observer, true, true);
  var hourAngle = (observer.longitude / 15 + gast - ofdate.ra) % 24;
  if (hourAngle < 0.0) {
    hourAngle += 24.0;
  }
  return hourAngle;
}

/// @brief The viewing conditions of a body relative to the Sun.
///
/// Represents the angular separation of a body from the Sun as seen from the Earth
/// and the relative ecliptic longitudes between that body and the Earth as seen from the Sun.
///
/// @property {AstroTime} time
///      The date and time of the observation.
///
/// @property {string}  visibility
///      Either `"morning"` or `"evening"`,
///      indicating when the body is most easily seen.
///
/// @property {number}  elongation
///      The angle in degrees, as seen from the center of the Earth,
///      of the apparent separation between the body and the Sun.
///      This angle is measured in 3D space and is not projected onto the ecliptic plane.
///      When `elongation` is less than a few degrees, the body is very
///      difficult to see from the Earth because it is lost in the Sun's glare.
///      The elongation is always in the range [0, 180].
///
/// @property {number}  ecliptic_separation
///      The absolute value of the difference between the body's ecliptic longitude
///      and the Sun's ecliptic longitude, both as seen from the center of the Earth.
///      This angle measures around the plane of the Earth's orbit (the ecliptic),
///      and ignores how far above or below that plane the body is.
///      The ecliptic separation is measured in degrees and is always in the range [0, 180].
///
/// @see {@link Elongation}
class ElongationEvent {
  final AstroTime time;
  final String visibility;
  final double elongation;
  final double eclipticSeparation;

  ElongationEvent(this.time, this.visibility, this.elongation, this.eclipticSeparation);
}
/// @brief Calculates the viewing conditions of a body relative to the Sun.
///
/// Calculates angular separation of a body from the Sun as seen from the Earth
/// and the relative ecliptic longitudes between that body and the Earth as seen from the Sun.
/// See the return type {@link ElongationEvent} for details.
///
/// This function is helpful for determining how easy
/// it is to view a planet away from the Sun's glare on a given date.
/// It also determines whether the object is visible in the morning or evening;
/// this is more important the smaller the elongation is.
/// It is also used to determine how far a planet is from opposition, conjunction, or quadrature.
///
/// @param {Body} body
///      The name of the observed body. Not allowed to be `Body.Earth`.
///
/// @param {FlexibleDateTime} date
///      The date and time of the observation.
///
/// @returns {ElongationEvent}
ElongationEvent elongation(Body body, dynamic date) {
  AstroTime time = AstroTime(date);

  double lon = pairLongitude(body, Body.Sun, time);
  String vis;
  if (lon > 180) {
    vis = 'morning';
    lon = 360 - lon;
  } else {
    vis = 'evening';
  }
  double angle = angleFromSun(body, time);
  return ElongationEvent(time, vis, angle, lon);
}

class InferiorPlanetEntry {
  final double s1;
  final double s2;

  InferiorPlanetEntry(this.s1, this.s2);
}

class InferiorPlanetTable {
  final Map<String, InferiorPlanetEntry> table;

  InferiorPlanetTable(this.table);

  InferiorPlanetEntry? operator [](Body body) {
    return table[body.toString()];
  }
}
/// @brief Finds the next time Mercury or Venus reaches maximum elongation.
///
/// Searches for the next maximum elongation event for Mercury or Venus
/// that occurs after the given start date. Calling with other values
/// of `body` will result in an exception.
/// Maximum elongation occurs when the body has the greatest
/// angular separation from the Sun, as seen from the Earth.
/// Returns an `ElongationEvent` object containing the date and time of the next
/// maximum elongation, the elongation in degrees, and whether
/// the body is visible in the morning or evening.
///
/// @param {Body} body
///      Either `Body.Mercury` or `Body.Venus`.
///
/// @param {FlexibleDateTime} startDate
///      The date and time after which to search for the next maximum elongation event.
///
/// @returns {ElongationEvent}
ElongationEvent searchMaxElongation(Body body, dynamic startDate) {
  const double dt = 0.01;

  double negSlope(AstroTime t) {
    // The slope de/dt goes from positive to negative at the maximum elongation event.
    // But Search() is designed for functions that ascend through zero.
    // So this function returns the negative slope.
    AstroTime t1 = t.addDays(-dt / 2);
    AstroTime t2 = t.addDays(dt / 2);
    double e1 = angleFromSun(body, t1);
    double e2 = angleFromSun(body, t2);
    double m = (e1 - e2) / dt;
    return m;
  }

  AstroTime startTime = AstroTime(startDate);

  
  final InferiorPlanetTable table = InferiorPlanetTable({
    'Mercury': InferiorPlanetEntry(50.0, 85.0),
    'Venus': InferiorPlanetEntry(40.0, 50.0),
  });

  InferiorPlanetEntry? planet = table.table[body.name];
  if (planet == null) {
    throw 'SearchMaxElongation works for Mercury and Venus only.';
  }

  int iter = 0;
  while (++iter <= 2) {
    // Find current heliocentric relative longitude between the
    // inferior planet and the Earth.
    double plon = eclipticLongitude(body, startTime);
    double elon = eclipticLongitude(Body.Earth, startTime);
    double rlon = LongitudeOffset(plon - elon); // clamp to (-180, +180]

    // The slope function is not well-behaved when rlon is near 0 degrees or 180 degrees
    // because there is a cusp there that causes a discontinuity in the derivative.
    // So we need to guard against searching near such times.

    double rlonLo, rlonHi, adjustDays;
    if (rlon >= -planet.s1 && rlon < planet.s1) {
      // Seek to the window [+s1, +s2].
      adjustDays = 0;
      // Search forward for the time t1 when rel lon = +s1.
      rlonLo = planet.s1;
      // Search forward for the time t2 when rel lon = +s2.
      rlonHi = planet.s2;
    } else if (rlon >= planet.s2 || rlon < -planet.s2) {
      // Seek to the next search window at [-s2, -s1].
      adjustDays = 0;
      // Search forward for the time t1 when rel lon = -s2.
      rlonLo = -planet.s2;
      // Search forward for the time t2 when rel lon = -s1.
      rlonHi = -planet.s1;
    } else if (rlon >= 0) {
      // rlon must be in the middle of the window [+s1, +s2].
      // Search BACKWARD for the time t1 when rel lon = +s1.
      adjustDays = -synodicPeriod(body) / 4;
      rlonLo = planet.s1;
      rlonHi = planet.s2;
      // Search forward from t1 to find t2 such that rel lon = +s2.
    } else {
      // rlon must be in the middle of the window [-s2, -s1].
      // Search BACKWARD for the time t1 when rel lon = -s2.
      adjustDays = -synodicPeriod(body) / 4;
      rlonLo = -planet.s2;
      rlonHi = -planet.s1;
      // Search forward from t1 to find t2 such that rel lon = -s1.
    }

    AstroTime tStart = startTime.addDays(adjustDays);
    AstroTime t1 = searchRelativeLongitude(body, rlonLo, tStart);
    AstroTime t2 = searchRelativeLongitude(body, rlonHi, t1);

    // Now we have a time range [t1,t2] that brackets a maximum elongation event.
    // Confirm the bracketing.
    double m1 = negSlope(t1);
    if (m1 >= 0) {
      throw 'SearchMaxElongation: internal error: m1 = $m1';
    }

    double m2 = negSlope(t2);
    if (m2 <= 0) {
      throw 'SearchMaxElongation: internal error: m2 = $m2';
    }

    // Use the generic search algorithm to home in on where the slope crosses from negative to positive.
    AstroTime? tx = search(negSlope, t1, t2, options: SearchOptions(initF1: m1, initF2: m2, dtToleranceSeconds: 10));

   
    if (tx == null) {
      throw 'SearchMaxElongation: failed search iter $iter (t1=${t1.toString()}, t2=${t2.toString()})';
    }

    if (tx.tt >= startTime.tt) {
      return elongation(body, tx);
    }

    // This event is in the past (earlier than startDate).
    // We need to search forward from t2 to find the next possible window.
    // We never need to search more than twice.
    startTime = t2.addDays(1);
  }

  throw 'SearchMaxElongation: failed to find event after 2 tries.';
}





/// @brief Calculates the inverse of an atmospheric refraction angle.
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
double inverseRefraction(String? lRefraction, double bentAltitude) {
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

/// Calculates the refraction correction for a given altitude.





/// @brief Returns information about a lunar eclipse.
///
/// Returned by {@link SearchLunarEclipse} or {@link NextLunarEclipse}
/// to report information about a lunar eclipse event.
/// When a lunar eclipse is found, it is classified as penumbral, partial, or total.
/// Penumbral eclipses are difficult to observe, because the Moon is only slightly dimmed
/// by the Earth's penumbra; no part of the Moon touches the Earth's umbra.
/// Partial eclipses occur when part, but not all, of the Moon touches the Earth's umbra.
/// Total eclipses occur when the entire Moon passes into the Earth's umbra.
///
/// The `kind` field thus holds one of the enum values `EclipseKind.Penumbral`, `EclipseKind.Partial`,
/// or `EclipseKind.Total`, depending on the kind of lunar eclipse found.
///
/// The `obscuration` field holds a value in the range [0, 1] that indicates what fraction
/// of the Moon's apparent disc area is covered by the Earth's umbra at the eclipse's peak.
/// This indicates how dark the peak eclipse appears. For penumbral eclipses, the obscuration
/// is 0, because the Moon does not pass through the Earth's umbra. For partial eclipses,
/// the obscuration is somewhere between 0 and 1. For total lunar eclipses, the obscuration is 1.
///
/// Field `peak` holds the date and time of the peak of the eclipse, when it is at its peak.
///
/// Fields `sd_penum`, `sd_partial`, and `sd_total` hold the semi-duration of each phase
/// of the eclipse, which is half of the amount of time the eclipse spends in each
/// phase (expressed in minutes), or 0 if the eclipse never reaches that phase.
/// By converting from minutes to days, and subtracting/adding with `peak`, the caller
/// may determine the date and time of the beginning/end of each eclipse phase.
///
/// @property {EclipseKind} kind
///      The type of lunar eclipse found.
///
/// @property {number} obscuration
///      The peak fraction of the Moon's apparent disc that is covered by the Earth's umbra.
///
/// @property {AstroTime} peak
///      The time of the eclipse at its peak.
///
/// @property {number} sd_penum
///      The semi-duration of the penumbral phase in minutes.
///
/// @property {number} sd_partial
///      The semi-duration of the penumbral phase in minutes, or 0.0 if none.
///
/// @property {number} sd_total
///      The semi-duration of the penumbral phase in minutes, or 0.0 if none.
///
class LunarEclipseInfo {
  EclipseKind kind;
  double obscuration;
  AstroTime peak;
  double sdPenum;
  double sdPartial;
  double sdTotal;

  LunarEclipseInfo(this.kind, this.obscuration, this.peak, this.sdPenum, this.sdPartial, this.sdTotal);
}

/// @ignore
///
/// @brief Represents the relative alignment of the Earth and another body, and their respective shadows.
///
/// This is an internal data structure used to assist calculation of
/// lunar eclipses, solar eclipses, and transits of Mercury and Venus.
///
/// Definitions:
///
/// casting body = A body that casts a shadow of interest, possibly striking another body.
///
/// receiving body = A body on which the shadow of another body might land.
///
/// shadow axis = The line passing through the center of the Sun and the center of the casting body.
///
/// shadow plane = The plane passing through the center of a receiving body,
/// and perpendicular to the shadow axis.
///
/// @property {AstroTime} time
///      The time associated with the shadow calculation.
///
/// @property {number} u
///      The distance [au] between the center of the casting body and the shadow plane.
///
/// @property {number} r
///      The distance [km] between center of receiving body and the shadow axis.
///
/// @property {number} k
///      The umbra radius [km] at the shadow plane.
///
/// @property {number} p
///      The penumbra radius [km] at the shadow plane.
///
/// @property {Vector} target
///      The location in space where we are interested in determining how close a shadow falls.
///      For example, when calculating lunar eclipses, `target` would be the center of the Moon
///      expressed in geocentric coordinates. Then we can evaluate how far the center of the Earth's
///      shadow cone approaches the center of the Moon.
///      The vector components are expressed in [au].
///
/// @property {Vector} dir
///      The direction in space that the shadow points away from the center of a shadow-casting body.
///      This vector lies on the shadow axis and points away from the Sun.
///      In other words: the direction light from the Sun would be traveling,
///      except that the center of a body (Earth, Moon, Mercury, or Venus) is blocking it.
///      The distance units do not matter, because the vector will be normalized.
class ShadowInfo {
  AstroTime time;
  double u;
  double r;
  double k;
  double p;
  AstroVector target;
  AstroVector dir;

  ShadowInfo(this.time, this.u, this.r, this.k, this.p, this.target, this.dir);
}


ShadowInfo calcShadow(double bodyRadiusKm, AstroTime time, AstroVector target, AstroVector dir) {
  double u = (dir.x * target.x + dir.y * target.y + dir.z * target.z) /
      (dir.x * dir.x + dir.y * dir.y + dir.z * dir.z);
  double dx = (u * dir.x) - target.x;
  double dy = (u * dir.y) - target.y;
  double dz = (u * dir.z) - target.z;
  double r = KM_PER_AU * sqrt(dx * dx + dy * dy + dz * dz);
  double k = SUN_RADIUS_KM - (1.0 + u) * (SUN_RADIUS_KM - bodyRadiusKm);
  double p = -SUN_RADIUS_KM + (1.0 + u) * (SUN_RADIUS_KM + bodyRadiusKm);
  return ShadowInfo(time, u, r, k, p, target, dir);
}

ShadowInfo earthShadow(AstroTime time) {
  // Light-travel and aberration corrected vector from the Earth to the Sun.
  AstroVector s = geoVector(Body.Sun, time, true);
  // The vector e = -s is thus the path of sunlight through the center of the Earth.
  AstroVector e = AstroVector(-s.x, -s.y, -s.z,s.time); // Assuming `s.t` is not used in Vector constructor
  // Geocentric moon.
  AstroVector m = Moon(time).geoMoon();
  return calcShadow(EARTH_ECLIPSE_RADIUS_KM, time, m, e);
}

ShadowInfo moonShadow(AstroTime time) {
  AstroVector s = geoVector(Body.Sun, time, true);
  AstroVector m = Moon(time).geoMoon(); // geocentric Moon
  // Calculate lunacentric Earth.
  AstroVector e = AstroVector(-m.x, -m.y, -m.z,m.time); // Assuming `m.t` is not used in Vector constructor
  // Convert geocentric moon to heliocentric Moon.
  m.x -= s.x;
  m.y -= s.y;
  m.z -= s.z;
  return calcShadow(MOON_MEAN_RADIUS_KM, time, e, m);
}

ShadowInfo localMoonShadow(AstroTime time, Observer observer) {
  // Calculate observer's geocentric position.
  List<double> pos = geoPos(time, observer);

  // Calculate light-travel and aberration corrected Sun.
  AstroVector s = geoVector(Body.Sun, time, true);

  // Calculate geocentric Moon.
  AstroVector m = Moon(time).geoMoon(); // geocentric Moon

  // Calculate lunacentric location of an observer on the Earth's surface.
  AstroVector o = AstroVector(pos[0] - m.x, pos[1] - m.y, pos[2] - m.z,time); // Assuming `time` should be passed as `m.t`

  // Convert geocentric moon to heliocentric Moon.
 m.x -= s.x;
 m.y -= s.y;
 m.z -= s.z;

  return calcShadow(MOON_MEAN_RADIUS_KM, time, o, m);
}


ShadowInfo planetShadow(Body body, double planetRadiusKm, AstroTime time) {
  // Calculate light-travel-corrected vector from Earth to planet.
  AstroVector g = geoVector(body, time, true);

  // Calculate light-travel-corrected vector from Earth to Sun.
  AstroVector e = geoVector(Body.Sun, time, true);

  // Deduce light-travel-corrected vector from Sun to planet.
  AstroVector p = AstroVector(g.x - e.x, g.y - e.y, g.z - e.z,time); // Assuming `time` should be passed as `g.t`

  // Calculate Earth's position from the planet's point of view.
 e.x = -g.x;
 e.y = -g.y;
 e.z = -g.z;

  return calcShadow(planetRadiusKm, time, e, p);
}

double shadowDistanceSlope(ShadowInfo Function(AstroTime) shadowfunc, AstroTime time) {
  final dt = 1.0 / 86400.0;
  final t1 = time.addDays(-dt);
  final t2 = time.addDays(dt);
  final shadow1 = shadowfunc(t1);
  final shadow2 = shadowfunc(t2);
  return (shadow2.r - shadow1.r) / dt;
}

double planetShadowSlope(Body body, double planetRadiusKm, AstroTime time) {
  final dt = 1.0 / 86400.0;
  final shadow1 = planetShadow(body, planetRadiusKm, time.addDays(-dt));
  final shadow2 = planetShadow(body, planetRadiusKm, time.addDays(dt));
  return (shadow2.r - shadow1.r) / dt;
}

ShadowInfo peakEarthShadow(AstroTime searchCenterTime) {
  final window = 0.03; /* initial search window, in days, before/after given time */
  final t1 = searchCenterTime.addDays(-window);
  final t2 = searchCenterTime.addDays(window);
  final tx = search((AstroTime time) => shadowDistanceSlope(earthShadow, time), t1, t2);
  if (tx == null) {
    throw 'Failed to find peak Earth shadow time.';
  }
  return earthShadow(tx);
}

ShadowInfo peakMoonShadow(AstroTime searchCenterTime) {
  final window = 0.03; /* initial search window, in days, before/after given time */
  final t1 = searchCenterTime.addDays(-window);
  final t2 = searchCenterTime.addDays(window);
  final tx = search((AstroTime time) => shadowDistanceSlope(moonShadow, time), t1, t2);
  if (tx == null) {
    throw 'Failed to find peak Moon shadow time.';
  }
  return moonShadow(tx);
}

ShadowInfo peakPlanetShadow(Body body, double planetRadiusKm, AstroTime searchCenterTime) {
  // Search for when the body's shadow is closest to the center of the Earth.
  final window = 1.0; // days before/after inferior conjunction to search for minimum shadow distance.
  final t1 = searchCenterTime.addDays(-window);
  final t2 = searchCenterTime.addDays(window);
  final tx = search((AstroTime time) => planetShadowSlope(body, planetRadiusKm, time), t1, t2);
  if (tx == null) {
    throw 'Failed to find peak planet shadow time.';
  }
  return planetShadow(body, planetRadiusKm, tx);
}

ShadowInfo peakLocalMoonShadow(AstroTime searchCenterTime, Observer observer) {
  // Search for the time near searchCenterTime that the Moon's shadow comes
  // closest to the given observer.
  final window = 0.2;
  final t1 = searchCenterTime.addDays(-window);
  final t2 = searchCenterTime.addDays(window);

  ShadowInfo shadowfunc(AstroTime time) {
    return localMoonShadow(time, observer);
  }

  final time = search((AstroTime time) => shadowDistanceSlope(shadowfunc, time), t1, t2);
  if (time == null) {
    throw 'PeakLocalMoonShadow: search failure for searchCenterTime = $searchCenterTime';
  }
  return localMoonShadow(time, observer);
}

double shadowSemiDurationMinutes(AstroTime centerTime, double radiusLimit, double windowMinutes) {
  // Search backwards and forwards from the center time until shadow axis distance crosses radius limit.
  final window = windowMinutes / (24.0 * 60.0);
  final before = centerTime.addDays(-window);
  final after = centerTime.addDays(window);

  final t1 = search((AstroTime time) => -(earthShadow(time).r - radiusLimit), before, centerTime);
  final t2 = search((AstroTime time) => (earthShadow(time).r - radiusLimit), centerTime, after);

  if (t1 == null || t2 == null) {
    throw 'Failed to find shadow semiduration';
  }

  return (t2.ut - t1.ut) * ((24.0 * 60.0) / 2.0); // convert days to minutes and average the semi-durations.
}



double obscuration(double a, double b, double c) {
  if (a <= 0.0) {
    throw 'Radius of first disc must be positive.';
  }

  if (b <= 0.0) {
    throw 'Radius of second disc must be positive.';
  }

  if (c < 0.0) {
    throw 'Distance between discs is not allowed to be negative.';
  }

  if (c >= a + b) {
    // The discs are too far apart to have any overlapping area.
    return 0.0;
  }

  if (c == 0.0) {
    // The discs have a common center. Therefore, one disc is inside the other.
    return (a <= b) ? 1.0 : (b * b) / (a * a);
  }

  final x = (a * a - b * b + c * c) / (2 * c);
  final radicand = a * a - x * x;
  if (radicand <= 0.0) {
    // The circumferences do not intersect, or are tangent.
    // We already ruled out the case of non-overlapping discs.
    // Therefore, one disc is inside the other.
    return (a <= b) ? 1.0 : (b * b) / (a * a);
  }

  // The discs overlap fractionally in a pair of lens-shaped areas.
  final y = sqrt(radicand);

  // Return the overlapping fractional area.
  // There are two lens-shaped areas, one to the left of x, the other to the right of x.
  // Each part is calculated by subtracting a triangular area from a sector's area.
  final lens1 = a * a * acos(x / a) - x * y;
  final lens2 = b * b * acos((c - x) / b) - (c - x) * y;

  // Find the fractional area with respect to the first disc.
  return (lens1 + lens2) / (pi * a * a);
}

double solarEclipseObscuration(AstroVector hm, AstroVector lo) {
  // Find heliocentric observer.
  final ho = AstroVector(hm.x + lo.x, hm.y + lo.y, hm.z + lo.z, hm.time);

  // Calculate the apparent angular radius of the Sun for the observer.
  final sunRadius = asin(SUN_RADIUS_AU / ho.length());

  // Calculate the apparent angular radius of the Moon for the observer.
  final moonRadius = asin(MOON_POLAR_RADIUS_AU / lo.length());

  // Calculate the apparent angular separation between the Sun's center and the Moon's center.
  final sunMoonSeparation = angleBetween(lo, ho);

  // Find the fraction of the Sun's apparent disc area that is covered by the Moon.
  final obscuration1 = obscuration(sunRadius, moonRadius, sunMoonSeparation * DEG2RAD);

  // HACK: In marginal cases, we need to clamp obscuration to less than 1.0.
  // This function is never called for total eclipses, so it should never return 1.0.
  return min(0.9999, obscuration1);
}
/// @brief Searches for a lunar eclipse.
///
/// This function finds the first lunar eclipse that occurs after `startTime`.
/// A lunar eclipse may be penumbral, partial, or total.
/// See {@link LunarEclipseInfo} for more information.
/// To find a series of lunar eclipses, call this function once,
/// then keep calling {@link NextLunarEclipse} as many times as desired,
/// passing in the `peak` value returned from the previous call.
///
/// @param {FlexibleDateTime} date
///      The date and time for starting the search for a lunar eclipse.
///
/// @returns {LunarEclipseInfo}
LunarEclipseInfo searchLunarEclipse(dynamic date) {
  const double PruneLatitude = 1.8; // full Moon's ecliptic latitude above which eclipse is impossible
  var fmtime = AstroTime(date);
  for (var fmcount = 0; fmcount < 12; ++fmcount) {
    // Search for the next full moon. Any eclipse will be near it.
    final fullmoon = searchMoonPhase(180, fmtime, 40);
    if (fullmoon == null) {
      throw 'Cannot find full moon.';
    }

    // Pruning: if the full Moon's ecliptic latitude is too large,
    // a lunar eclipse is not possible. Avoid needless work searching for the minimum moon distance.
    final eclipLat = Moon(fullmoon).moonEclipticLatitudeDegrees();
    if (eclipLat.abs() < PruneLatitude) {
      // Search near the full moon for the time when the center of the Moon
      // is closest to the line passing through the centers of the Sun and Earth.
      final shadow = peakEarthShadow(fullmoon);
      if (shadow.r < shadow.p + MOON_MEAN_RADIUS_KM) {
        // This is at least a penumbral eclipse. We will return a result.
        var kind = EclipseKind.Penumbral;
        var obscuration1 = 0.0;
        var sdTotal = 0.0;
        var sdPartial = 0.0;
        var sdPenum = shadowSemiDurationMinutes(shadow.time, shadow.p + MOON_MEAN_RADIUS_KM, 200.0);

        if (shadow.r < shadow.k + MOON_MEAN_RADIUS_KM) {
          // This is at least a partial eclipse.
          kind = EclipseKind.Partial;
          sdPartial = shadowSemiDurationMinutes(shadow.time, shadow.k + MOON_MEAN_RADIUS_KM, sdPenum);

          if (shadow.r + MOON_MEAN_RADIUS_KM < shadow.k) {
            // This is a total eclipse.
            kind = EclipseKind.Total;
            obscuration1 = 1.0;
            sdTotal = shadowSemiDurationMinutes(shadow.time, shadow.k - MOON_MEAN_RADIUS_KM, sdPartial);
          } else {
            obscuration1 = obscuration(MOON_MEAN_RADIUS_KM, shadow.k, shadow.r);
          }
        }
        return LunarEclipseInfo(kind, obscuration1, shadow.time, sdPenum, sdPartial, sdTotal);
      }
    }

    // We didn't find an eclipse on this full moon, so search for the next one.
    fmtime = fullmoon.addDays(10);
  }

  // This should never happen because there are always at least 2 full moons per year.
  throw 'Failed to find lunar eclipse within 12 full moons.';
}

/// @brief Reports the time and geographic location of the peak of a solar eclipse.
///
/// Returned by {@link SearchGlobalSolarEclipse} or {@link NextGlobalSolarEclipse}
/// to report information about a solar eclipse event.
///
/// The eclipse is classified as partial, annular, or total, depending on the
/// maximum amount of the Sun's disc obscured, as seen at the peak location
/// on the surface of the Earth.
///
/// The `kind` field thus holds one of the values `EclipseKind.Partial`, `EclipseKind.Annular`, or `EclipseKind.Total`.
/// A total eclipse is when the peak observer sees the Sun completely blocked by the Moon.
/// An annular eclipse is like a total eclipse, but the Moon is too far from the Earth's surface
/// to completely block the Sun; instead, the Sun takes on a ring-shaped appearance.
/// A partial eclipse is when the Moon blocks part of the Sun's disc, but nobody on the Earth
/// observes either a total or annular eclipse.
///
/// If `kind` is `EclipseKind.Total` or `EclipseKind.Annular`, the `latitude` and `longitude`
/// fields give the geographic coordinates of the center of the Moon's shadow projected
/// onto the daytime side of the Earth at the instant of the eclipse's peak.
/// If `kind` has any other value, `latitude` and `longitude` are undefined and should
/// not be used.
///
/// For total or annular eclipses, the `obscuration` field holds the fraction (0, 1]
/// of the Sun's apparent disc area that is blocked from view by the Moon's silhouette,
/// as seen by an observer located at the geographic coordinates `latitude`, `longitude`
/// at the darkest time `peak`. The value will always be 1 for total eclipses, and less than
/// 1 for annular eclipses.
/// For partial eclipses, `obscuration` is undefined and should not be used.
/// This is because there is little practical use for an obscuration value of
/// a partial eclipse without supplying a particular observation location.
/// Developers who wish to find an obscuration value for partial solar eclipses should therefore use
/// {@link SearchLocalSolarEclipse} and provide the geographic coordinates of an observer.
///
/// @property {EclipseKind} kind
///     One of the following enumeration values: `EclipseKind.Partial`, `EclipseKind.Annular`, `EclipseKind.Total`.
///
/// @property {number | undefined} obscuration
///      The peak fraction of the Sun's apparent disc area obscured by the Moon (total and annular eclipses only)
///
/// @property {AstroTime} peak
///     The date and time when the solar eclipse is darkest.
///     This is the instant when the axis of the Moon's shadow cone passes closest to the Earth's center.
///
/// @property {number} distance
///     The distance in kilometers between the axis of the Moon's shadow cone
///     and the center of the Earth at the time indicated by `peak`.
///
/// @property {number | undefined} latitude
///     If `kind` holds `EclipseKind.Total`, the geographic latitude in degrees
///     where the center of the Moon's shadow falls on the Earth at the
///     time indicated by `peak`; otherwise, `latitude` holds `undefined`.
///
/// @property {number | undefined} longitude
///     If `kind` holds `EclipseKind.Total`, the geographic longitude in degrees
///     where the center of the Moon's shadow falls on the Earth at the
///     time indicated by `peak`; otherwise, `longitude` holds `undefined`.
class GlobalSolarEclipseInfo {
  EclipseKind kind;
  late var obscuration;
  AstroTime peak;
  late double distance;
  late var latitude;
  late var longitude;

  GlobalSolarEclipseInfo(
      this.kind, this.obscuration, this.peak, this.distance, this.latitude, this.longitude);
}

EclipseKind eclipseKindFromUmbra(double k) {
  // The umbra radius tells us what kind of eclipse the observer sees.
  // If the umbra radius is positive, this is a total eclipse. Otherwise, it's annular.
  // HACK: I added a tiny bias (14 meters) to match Espenak test data.
  return (k > 0.014) ? EclipseKind.Total : EclipseKind.Annular;
}



GlobalSolarEclipseInfo geoidIntersect(ShadowInfo shadow) {
  var kind = EclipseKind.Partial;
  var peak = shadow.time;
  var distance = shadow.r;
  dynamic latitude; // left undefined for partial eclipses
  dynamic longitude; // left undefined for partial eclipses

  // We want to calculate the intersection of the shadow axis with the Earth's geoid.
  // First we must convert EQJ (equator of J2000) coordinates to EQD (equator of date)
  // coordinates that are perfectly aligned with the Earth's equator at this
  // moment in time.
  final rot = RotationMatrix.rotationEQJtoEQD(shadow.time);
  final v = AstroVector.rotateVector(rot, shadow.dir); // shadow-axis vector in equator-of-date coordinates
  final e = AstroVector.rotateVector(rot, shadow.target); // lunacentric Earth in equator-of-date coordinates

  // Convert all distances from AU to km.
  // But dilate the z-coordinates so that the Earth becomes a perfect sphere.
  // Then find the intersection of the vector with the sphere.
  // See p 184 in Montenbruck & Pfleger's "Astronomy on the Personal Computer", second edition.
  v.x *= KM_PER_AU;
  v.y *= KM_PER_AU;
  v.z *= KM_PER_AU / EARTH_FLATTENING;
  e.x *= KM_PER_AU;
  e.y *= KM_PER_AU;
  e.z *= KM_PER_AU / EARTH_FLATTENING;

  // Solve the quadratic equation that finds whether and where
  // the shadow axis intersects with the Earth in the dilated coordinate system.
  final R = EARTH_EQUATORIAL_RADIUS_KM;
  final A = v.x * v.x + v.y * v.y + v.z * v.z;
  final B = -2.0 * (v.x * e.x + v.y * e.y + v.z * e.z);
  final C = (e.x * e.x + e.y * e.y + e.z * e.z) - R * R;
  final radic = B * B - 4 * A * C;

  double? obscuration;

  if (radic > 0.0) {
    // Calculate the closer of the two intersection points.
    // This will be on the day side of the Earth.
    final u = (-B - sqrt(radic)) / (2 * A);

    // Convert lunacentric dilated coordinates to geocentric coordinates.
    final px = u * v.x - e.x;
    final py = u * v.y - e.y;
    final pz = (u * v.z - e.z) * EARTH_FLATTENING;

    // Convert cartesian coordinates into geodetic latitude/longitude.
    final proj = hypot(px, py) * EARTH_FLATTENING_SQUARED;
    if (proj == 0.0) {
      latitude = (pz > 0.0) ? 90.0 : -90.0;
    } else {
      latitude = RAD2DEG * atan(pz / proj);
    }

    // Adjust longitude for Earth's rotation at the given UT.
    final gast = sidereal_time(peak);
    longitude = (RAD2DEG * atan2(py, px) - (15 * gast)) % 360.0;
    if (longitude <= -180.0) {
      longitude += 360.0;
    } else if (longitude > 180.0) {
      longitude -= 360.0;
    }

    // We want to determine whether the observer sees a total eclipse or an annular eclipse.
    // We need to perform a series of vector calculations...
    // Calculate the inverse rotation matrix, so we can convert EQD to EQJ.
    final inv = RotationMatrix.inverseRotation(rot);

    // Put the EQD geocentric coordinates of the observer into the vector 'o'.
    // Also convert back from kilometers to astronomical units.
    var o = AstroVector(px / KM_PER_AU, py / KM_PER_AU, pz / KM_PER_AU, shadow.time);

    // Rotate the observer's geocentric EQD back to the EQJ system.
    o = AstroVector.rotateVector(inv, o);

    // Convert geocentric vector to lunacentric vector.
    o.x += shadow.target.x;
    o.y += shadow.target.y;
    o.z += shadow.target.z;

    // Recalculate the shadow using a vector from the Moon's center toward the observer.
    final surface = calcShadow(MOON_POLAR_RADIUS_KM, shadow.time, o, shadow.dir);

    // If we did everything right, the shadow distance should be very close to zero.
    // That's because we already determined the observer 'o' is on the shadow axis!
    if (surface.r > 1.0e-9 || surface.r < 0.0) {
      throw 'Unexpected shadow distance from geoid intersection = ${surface.r}';
    }

    kind = eclipseKindFromUmbra(surface.k);
    obscuration = (kind == EclipseKind.Total) ? 1.0 : solarEclipseObscuration(shadow.dir, o);
  } else {
    // This is a partial solar eclipse. It does not make practical sense to calculate obscuration.
    // Anyone who wants obscuration should use Astronomy.searchLocalSolarEclipse for a specific location on the Earth.
    obscuration = null;
  }

  return GlobalSolarEclipseInfo(kind, obscuration, peak, distance, latitude, longitude);
}

/// @brief Searches for the next lunar eclipse in a series.
///
/// After using {@link SearchLunarEclipse} to find the first lunar eclipse
/// in a series, you can call this function to find the next consecutive lunar eclipse.
/// Pass in the `peak` value from the {@link LunarEclipseInfo} returned by the
/// previous call to `SearchLunarEclipse` or `NextLunarEclipse`
/// to find the next lunar eclipse.
///
/// @param {FlexibleDateTime} prevEclipseTime
///      A date and time near a full moon. Lunar eclipse search will start at the next full moon.
///
/// @returns {LunarEclipseInfo}
LunarEclipseInfo nextLunarEclipse(dynamic prevEclipseTime) {
  var startTime = AstroTime(prevEclipseTime);
  startTime = startTime.addDays(10); // Add 10 days to the previous eclipse time
  return searchLunarEclipse(startTime);
}


/// @brief Searches for a solar eclipse visible anywhere on the Earth's surface.
///
/// This function finds the first solar eclipse that occurs after `startTime`.
/// A solar eclipse may be partial, annular, or total.
/// See {@link GlobalSolarEclipseInfo} for more information.
/// To find a series of solar eclipses, call this function once,
/// then keep calling {@link NextGlobalSolarEclipse} as many times as desired,
/// passing in the `peak` value returned from the previous call.
///
/// @param {FlexibleDateTime} startTime
///      The date and time for starting the search for a solar eclipse.
///
/// @returns {GlobalSolarEclipseInfo}
GlobalSolarEclipseInfo searchGlobalSolarEclipse(dynamic startTime) {
  startTime = AstroTime(startTime);
  const double pruneLatitude = 1.8; // Moon's ecliptic latitude beyond which eclipse is impossible
  
  // Iterate through consecutive new moons until we find a solar eclipse visible somewhere on Earth.
  var nmtime = startTime;
  for (var nmcount = 0; nmcount < 12; ++nmcount) {
    // Search for the next new moon. Any eclipse will be near it.
    var newmoon = searchMoonPhase(0.0, nmtime, 40.0);
    if (newmoon == null) {
      throw 'Cannot find new moon';
    }

    // Pruning: if the new moon's ecliptic latitude is too large, a solar eclipse is not possible.
    var eclipLat = Moon(newmoon).moonEclipticLatitudeDegrees();
    if (eclipLat.abs() < pruneLatitude) {
      // Search near the new moon for the time when the center of the Earth
      // is closest to the line passing through the centers of the Sun and Moon.
      var shadow = peakMoonShadow(newmoon);
      if (shadow.r < shadow.p + EARTH_MEAN_RADIUS_KM ) {
        // This is at least a partial solar eclipse visible somewhere on Earth.
        // Try to find an intersection between the shadow axis and the Earth's oblate geoid.
        return geoidIntersect(shadow);
      }
    }

    // We didn't find an eclipse on this new moon, so search for the next one.
    nmtime = newmoon.addDays(10.0);
  }

  // Safety valve to prevent infinite loop.
  // This should never happen, because at least 2 solar eclipses happen per year.
  throw 'Failed to find solar eclipse within 12 full moons.';
}


/// @brief Searches for the next global solar eclipse in a series.
///
/// After using {@link SearchGlobalSolarEclipse} to find the first solar eclipse
/// in a series, you can call this function to find the next consecutive solar eclipse.
/// Pass in the `peak` value from the {@link GlobalSolarEclipseInfo} returned by the
/// previous call to `SearchGlobalSolarEclipse` or `NextGlobalSolarEclipse`
/// to find the next solar eclipse.
///
/// @param {FlexibleDateTime} prevEclipseTime
///      A date and time near a new moon. Solar eclipse search will start at the next new moon.
///
/// @returns {GlobalSolarEclipseInfo}
GlobalSolarEclipseInfo nextGlobalSolarEclipse(dynamic prevEclipseTime) {
  prevEclipseTime = AstroTime(prevEclipseTime);
  var startTime = prevEclipseTime.addDays(10.0);
  return searchGlobalSolarEclipse(startTime);
}

/// @brief Holds a time and the observed altitude of the Sun at that time.
///
/// When reporting a solar eclipse observed at a specific location on the Earth
/// (a "local" solar eclipse), a series of events occur. In addition
/// to the time of each event, it is important to know the altitude of the Sun,
/// because each event may be invisible to the observer if the Sun is below
/// the horizon.
///
/// If `altitude` is negative, the event is theoretical only; it would be
/// visible if the Earth were transparent, but the observer cannot actually see it.
/// If `altitude` is positive but less than a few degrees, visibility will be impaired by
/// atmospheric interference (sunrise or sunset conditions).
///
/// @property {AstroTime} time
///      The date and time of the event.
///
/// @property {number} altitude
///      The angular altitude of the center of the Sun above/below the horizon, at `time`,
///      corrected for atmospheric refraction and expressed in degrees.
class EclipseEvent {
   AstroTime time;
   double altitude;

  EclipseEvent(this.time, this.altitude);
}


/// @brief Information about a solar eclipse as seen by an observer at a given time and geographic location.
///
/// Returned by {@link SearchLocalSolarEclipse} or {@link NextLocalSolarEclipse}
/// to report information about a solar eclipse as seen at a given geographic location.
///
/// When a solar eclipse is found, it is classified by setting `kind`
/// to `EclipseKind.Partial`, `EclipseKind.Annular`, or `EclipseKind.Total`.
/// A partial solar eclipse is when the Moon does not line up directly enough with the Sun
/// to completely block the Sun's light from reaching the observer.
/// An annular eclipse occurs when the Moon's disc is completely visible against the Sun
/// but the Moon is too far away to completely block the Sun's light; this leaves the
/// Sun with a ring-like appearance.
/// A total eclipse occurs when the Moon is close enough to the Earth and aligned with the
/// Sun just right to completely block all sunlight from reaching the observer.
///
/// The `obscuration` field reports what fraction of the Sun's disc appears blocked
/// by the Moon when viewed by the observer at the peak eclipse time.
/// This is a value that ranges from 0 (no blockage) to 1 (total eclipse).
/// The obscuration value will be between 0 and 1 for partial eclipses and annular eclipses.
/// The value will be exactly 1 for total eclipses. Obscuration gives an indication
/// of how dark the eclipse appears.
///
/// There are 5 "event" fields, each of which contains a time and a solar altitude.
/// Field `peak` holds the date and time of the center of the eclipse, when it is at its peak.
/// The fields `partial_begin` and `partial_end` are always set, and indicate when
/// the eclipse begins/ends. If the eclipse reaches totality or becomes annular,
/// `total_begin` and `total_end` indicate when the total/annular phase begins/ends.
/// When an event field is valid, the caller must also check its `altitude` field to
/// see whether the Sun is above the horizon at the time indicated by the `time` field.
/// See {@link EclipseEvent} for more information.
///
/// @property {EclipseKind} kind
///      The type of solar eclipse found: `EclipseKind.Partial`, `EclipseKind.Annular`, or `EclipseKind.Total`.
///
/// @property {number} obscuration
///      The fraction of the Sun's apparent disc area obscured by the Moon at the eclipse peak.
///
/// @property {EclipseEvent} partial_begin
///      The time and Sun altitude at the beginning of the eclipse.
///
/// @property {EclipseEvent | undefined} total_begin
///      If this is an annular or a total eclipse, the time and Sun altitude when annular/total phase begins; otherwise undefined.
///
/// @property {EclipseEvent} peak
///      The time and Sun altitude when the eclipse reaches its peak.
///
/// @property {EclipseEvent | undefined} total_end
///      If this is an annular or a total eclipse, the time and Sun altitude when annular/total phase ends; otherwise undefined.
///
/// @property {EclipseEvent} partial_end
///      The time and Sun altitude at the end of the eclipse.
class LocalSolarEclipseInfo {
  EclipseKind kind;
  double obscuration;
  EclipseEvent partialBegin;
  EclipseEvent? totalBegin;
  EclipseEvent peak;
  EclipseEvent? totalEnd;
  EclipseEvent partialEnd;

  LocalSolarEclipseInfo(
    this.kind,
    this.obscuration,
    this.partialBegin,
    this.totalBegin,
    this.peak,
    this.totalEnd,
    this.partialEnd,
  );
}


double localPartialDistance(ShadowInfo shadow) {
  return shadow.p - shadow.r;
}

double localTotalDistance(ShadowInfo shadow) {
  // Must take the absolute value of the umbra radius 'k'
  // because it can be negative for an annular eclipse.
  return (shadow.k.abs()) - shadow.r;
}


LocalSolarEclipseInfo localEclipse(ShadowInfo shadow, Observer observer) {
  const partialWindow = 0.2;
  const totalWindow = 0.01;
  final peak = calcEvent(observer, shadow.time);
  var t1 = shadow.time.addDays(-partialWindow);
  var t2 = shadow.time.addDays(partialWindow);
  final partialBegin = localEclipseTransition(
      observer, 1.0, localPartialDistance, t1, shadow.time);
  final partialEnd = localEclipseTransition(
      observer, -1.0, localPartialDistance, shadow.time, t2);
  EclipseEvent? totalBegin;
  EclipseEvent? totalEnd;
  late EclipseKind kind;

  if (shadow.r < shadow.k.abs()) {
    // take absolute value of 'k' to handle annular eclipses too.
    t1 = shadow.time.addDays(-totalWindow);
    t2 = shadow.time.addDays(totalWindow);
    totalBegin = localEclipseTransition(
        observer, 1.0, localTotalDistance, t1, shadow.time);
    totalEnd =
        localEclipseTransition(observer, -1.0, localTotalDistance, shadow.time, t2);
    kind = eclipseKindFromUmbra(shadow.k);
  } else {
    kind = EclipseKind.Partial;
  }

  final obscuration =
      (kind == EclipseKind.Total) ? 1.0 : solarEclipseObscuration(shadow.dir, shadow.target);

  return LocalSolarEclipseInfo(kind, obscuration, partialBegin, totalBegin, peak,
      totalEnd, partialEnd);
}

double sunAltitude(AstroTime time, Observer observer) {
  final equ = equator(Body.Sun, time, observer, true, true); // Adjust Body.Sun to your actual implementation
  final hor = HorizontalCoordinates.horizon(time, observer, equ.ra, equ.dec, 'normal'); // Adjust 'normal' to your actual implementation
  return hor.altitude;
}

typedef ShadowFunc = double Function(ShadowInfo shadow);

EclipseEvent calcEvent(Observer observer, AstroTime time) {
  final altitude = sunAltitude(time, observer);
  return EclipseEvent(time, altitude);
}


EclipseEvent localEclipseTransition(Observer observer, double direction, ShadowFunc func, AstroTime t1, AstroTime t2) {
  double evaluate(AstroTime time) {
    final shadow = localMoonShadow(time, observer);
    return direction * func(shadow);
  }
  final searchResult = search(evaluate, t1, t2);
  if (searchResult == null) {
    throw "Local eclipse transition search failed.";
  }
  return calcEvent(observer, searchResult);
}

/// @brief Searches for a solar eclipse visible at a specific location on the Earth's surface.
///
/// This function finds the first solar eclipse that occurs after `startTime`.
/// A solar eclipse may be partial, annular, or total.
/// See {@link LocalSolarEclipseInfo} for more information.
///
/// To find a series of solar eclipses, call this function once,
/// then keep calling {@link NextLocalSolarEclipse} as many times as desired,
/// passing in the `peak` value returned from the previous call.
///
/// IMPORTANT: An eclipse reported by this function might be partly or
/// completely invisible to the observer due to the time of day.
/// See {@link LocalSolarEclipseInfo} for more information about this topic.
///
/// @param {FlexibleDateTime} startTime
///      The date and time for starting the search for a solar eclipse.
///
/// @param {Observer} observer
///      The geographic location of the observer.
///
/// @returns {LocalSolarEclipseInfo}
LocalSolarEclipseInfo searchLocalSolarEclipse(dynamic startTime, Observer observer) {
  startTime = AstroTime(startTime);
  verifyObserver(observer);
  const PruneLatitude = 1.8; // Moon's ecliptic latitude beyond which eclipse is impossible

  // Iterate through consecutive new moons until we find a solar eclipse visible somewhere on Earth.
  var nmtime = startTime;
  for (;;) {
    // Search for the next new moon. Any eclipse will be near it.
    final newmoon = searchMoonPhase(0.0, nmtime, 40.0);
    if (newmoon == null) {
      throw 'Cannot find next new moon';
    }

    // Pruning: if the new moon's ecliptic latitude is too large, a solar eclipse is not possible.
    final eclipLat = Moon(newmoon).moonEclipticLatitudeDegrees();
    if (eclipLat.abs() < PruneLatitude) {
      // Search near the new moon for the time when the observer
      // is closest to the line passing through the centers of the Sun and Moon.
      final shadow = peakLocalMoonShadow(newmoon, observer);
      if (shadow.r < shadow.p) {
        // This is at least a partial solar eclipse for the observer.
        final eclipse = localEclipse(shadow, observer);

        // Ignore any eclipse that happens completely at night.
        // More precisely, the center of the Sun must be above the horizon
        // at the beginning or the end of the eclipse, or we skip the event.
        if (eclipse.partialBegin.altitude > 0.0 || eclipse.partialEnd.altitude > 0.0) {
          return eclipse;
        }
      }
    }

    // We didn't find an eclipse on this new moon, so search for the next one.
    nmtime = newmoon.addDays(10.0);
  }
}

/// @brief Searches for the next local solar eclipse in a series.
///
/// After using {@link SearchLocalSolarEclipse} to find the first solar eclipse
/// in a series, you can call this function to find the next consecutive solar eclipse.
/// Pass in the `peak` value from the {@link LocalSolarEclipseInfo} returned by the
/// previous call to `SearchLocalSolarEclipse` or `NextLocalSolarEclipse`
/// to find the next solar eclipse.
/// This function finds the first solar eclipse that occurs after `startTime`.
/// A solar eclipse may be partial, annular, or total.
/// See {@link LocalSolarEclipseInfo} for more information.
///
/// @param {FlexibleDateTime} prevEclipseTime
///      The date and time for starting the search for a solar eclipse.
///
/// @param {Observer} observer
///      The geographic location of the observer.
///
/// @returns {LocalSolarEclipseInfo}
LocalSolarEclipseInfo nextLocalSolarEclipse(dynamic prevEclipseTime, Observer observer) {
  prevEclipseTime = AstroTime(prevEclipseTime);
  final startTime = prevEclipseTime.addDays(10.0);
  return searchLocalSolarEclipse(startTime, observer);
}


/// @brief Searches for the next local solar eclipse in a series.
///
/// After using {@link SearchLocalSolarEclipse} to find the first solar eclipse
/// in a series, you can call this function to find the next consecutive solar eclipse.
/// Pass in the `peak` value from the {@link LocalSolarEclipseInfo} returned by the
/// previous call to `SearchLocalSolarEclipse` or `NextLocalSolarEclipse`
/// to find the next solar eclipse.
/// This function finds the first solar eclipse that occurs after `startTime`.
/// A solar eclipse may be partial, annular, or total.
/// See {@link LocalSolarEclipseInfo} for more information.
///
/// @param {FlexibleDateTime} prevEclipseTime
///      The date and time for starting the search for a solar eclipse.
///
/// @param {Observer} observer
///      The geographic location of the observer.
///
/// @returns {LocalSolarEclipseInfo}
class TransitInfo {
  AstroTime start;
  AstroTime peak;
  AstroTime finish;
  double separation;

  TransitInfo(this.start, this.peak, this.finish, this.separation);
}


double planetShadowBoundary(AstroTime time, Body body, double planetRadiusKm, double direction) {
  // Call PlanetShadow function with appropriate arguments
  final shadow = planetShadow(body, planetRadiusKm, time);
  return direction * (shadow.r - shadow.p);
}

AstroTime planetTransitBoundary(Body body, double planetRadiusKm, AstroTime t1, AstroTime t2, double direction) {
  // Search for the time the planet's penumbra begins/ends making contact with the center of the Earth.
  final tx = search((AstroTime time) => planetShadowBoundary(time, body, planetRadiusKm, direction), t1, t2);
  if (tx == null) {
    throw 'Planet transit boundary search failed';
  }
  return tx;
}

/// @brief Searches for the first transit of Mercury or Venus after a given date.
///
/// Finds the first transit of Mercury or Venus after a specified date.
/// A transit is when an inferior planet passes between the Sun and the Earth
/// so that the silhouette of the planet is visible against the Sun in the background.
/// To continue the search, pass the `finish` time in the returned structure to
/// {@link NextTransit}.
///
/// @param {Body} body
///      The planet whose transit is to be found. Must be `Body.Mercury` or `Body.Venus`.
///
/// @param {FlexibleDateTime} startTime
///      The date and time for starting the search for a transit.
///
/// @returns {TransitInfo}
TransitInfo searchTransit(Body body, dynamic startTime) {
  startTime = AstroTime(startTime);
  const double thresholdAngle = 0.4; // maximum angular separation to attempt transit calculation
  const double dtDays = 1.0;

  // Validate the planet and find its mean radius.
  double planetRadiusKm;
  switch (body) {
    case Body.Mercury:
      planetRadiusKm = 2439.7;
      break;
    case Body.Venus:
      planetRadiusKm = 6051.8;
      break;
    default:
      throw 'Invalid body: $body';
  }

  var searchTime = startTime;
  for (;;) {
    // Search for the next inferior conjunction of the given planet.
    // This is the next time the Earth and the other planet have the same
    // ecliptic longitude as seen from the Sun.
    final conj = searchRelativeLongitude(body, 0.0, searchTime);

    // Calculate the angular separation between the body and the Sun at this time.
    final conjSeparation = angleFromSun(body, conj);

    if (conjSeparation < thresholdAngle) {
      // The planet's angular separation from the Sun is small enough
      // to consider it a transit candidate.
      // Search for the moment when the line passing through the Sun
      // and planet are closest to the Earth's center.
      final shadow = peakPlanetShadow(body, planetRadiusKm, conj);

      if (shadow.r < shadow.p) {
        // does the planet's penumbra touch the Earth's center?
        // Find the beginning and end of the penumbral contact.
        final timeBefore = shadow.time.addDays(-dtDays);
        final start = planetTransitBoundary(body, planetRadiusKm, timeBefore, shadow.time, -1.0);
        final timeAfter = shadow.time.addDays(dtDays);
        final finish = planetTransitBoundary(body, planetRadiusKm, shadow.time, timeAfter, 1.0);
        final minSeparation = 60.0 * angleFromSun(body, shadow.time);
        return TransitInfo(start, shadow.time, finish, minSeparation);
      }
    }

    // This inferior conjunction was not a transit. Try the next inferior conjunction.
    searchTime = conj.addDays(10.0);
  }
}

/// @brief Searches for the next transit of Mercury or Venus in a series.
///
/// After calling {@link SearchTransit} to find a transit of Mercury or Venus,
/// this function finds the next transit after that.
/// Keep calling this function as many times as you want to keep finding more transits.
///
/// @param {Body} body
///      The planet whose transit is to be found. Must be `Body.Mercury` or `Body.Venus`.
///
/// @param {FlexibleDateTime} prevTransitTime
///      A date and time near the previous transit.
///
/// @returns {TransitInfo}
TransitInfo nextTransit(Body body, dynamic prevTransitTime) {
  prevTransitTime = AstroTime(prevTransitTime);
  final startTime = prevTransitTime.addDays(100.0);
  return searchTransit(body, startTime);
}

/// @brief Indicates whether a crossing through the ecliptic plane is ascending or descending.
///
/// `Invalid` is a placeholder for an unknown or missing node.
/// `Ascending` indicates a body passing through the ecliptic plane from south to north.
/// `Descending` indicates a body passing through the ecliptic plane from north to south.
///
/// @enum {number}
class NodeEventKind {
  final int value;
  const NodeEventKind._internal(this.value);

  static const Invalid = NodeEventKind._internal(0);
  static const Ascending = NodeEventKind._internal(1);
  static const Descending = NodeEventKind._internal(-1);
  
  @override
  String toString() {
    switch (value) {
      case 0:
        return 'Invalid';
      case 1:
        return 'Ascending';
      case -1:
        return 'Descending';
      default:
        return 'Unknown';
    }
  }
}
/// @brief Information about an ascending or descending node of a body.
///
/// This object is returned by {@link SearchMoonNode} and {@link NextMoonNode}
/// to report information about the center of the Moon passing through the ecliptic plane.
///
/// @property {NodeEventKind} kind   Whether the node is ascending (south to north) or descending (north to south).
/// @property {AstroTime} time       The time when the body passes through the ecliptic plane.
class NodeEventInfo {
  final NodeEventKind kind;
  final AstroTime time;

  NodeEventInfo(this.kind, this.time);
}

final MoonNodeStepDays = 10.0;  
/// @brief Searches for a time when the Moon's center crosses through the ecliptic plane.
///
/// Searches for the first ascending or descending node of the Moon after `startTime`.
/// An ascending node is when the Moon's center passes through the ecliptic plane
/// (the plane of the Earth's orbit around the Sun) from south to north.
/// A descending node is when the Moon's center passes through the ecliptic plane
/// from north to south. Nodes indicate possible times of solar or lunar eclipses,
/// if the Moon also happens to be in the correct phase (new or full, respectively).
/// Call `SearchMoonNode` to find the first of a series of nodes.
/// Then call {@link NextMoonNode} to find as many more consecutive nodes as desired.
///
/// @param {FlexibleDateTime} startTime
///      The date and time for starting the search for an ascending or descending node of the Moon.
///
/// @returns {NodeEventInfo}
NodeEventInfo searchMoonNode(dynamic startTime) {
  // Start at the given moment in time and sample the Moon's ecliptic latitude.
  // Step 10 days at a time, searching for an interval where that latitude crosses zero.

  AstroTime time1 = AstroTime(startTime);
  Spherical eclip1 = EclipticGeoMoon(time1);

  for (;;) {
    AstroTime time2 = time1.addDays(MoonNodeStepDays);
    Spherical eclip2 = EclipticGeoMoon(time2);
    if (eclip1.lat * eclip2.lat <= 0.0) {
      // There is a node somewhere inside this closed time interval.
      // Figure out whether it is an ascending node or a descending node.
      NodeEventKind kind = (eclip2.lat > eclip1.lat) ? NodeEventKind.Ascending : NodeEventKind.Descending;
      final result = search((t) => kind.value * EclipticGeoMoon(t).lat, time1, time2);
      if (result == null) {
        throw 'Could not find moon node.'; // should never happen
      }
      return NodeEventInfo(kind, result);
    }
    time1 = time2;
    eclip1 = eclip2;
  }
}

/// @brief Searches for the next time when the Moon's center crosses through the ecliptic plane.
///
/// Call {@link SearchMoonNode} to find the first of a series of nodes.
/// Then call `NextMoonNode` to find as many more consecutive nodes as desired.
///
/// @param {NodeEventInfo} prevNode
///      The previous node found from calling {@link SearchMoonNode} or `NextMoonNode`.
///
/// @returns {NodeEventInfo}
NodeEventInfo nextMoonNode(NodeEventInfo prevNode) {
  AstroTime time = prevNode.time.addDays(MoonNodeStepDays);
  NodeEventInfo node = searchMoonNode(time);
  switch (prevNode.kind) {
    case NodeEventKind.Ascending:
      if (node.kind != NodeEventKind.Descending) {
        throw 'Internal error: previous node was ascending, but this node was: ${node.kind}';
      }
      break;
    case NodeEventKind.Descending:
      if (node.kind != NodeEventKind.Ascending) {
        throw 'Internal error: previous node was descending, but this node was: ${node.kind}';
      }
      break;
    default:
      throw 'Previous node has an invalid node kind: ${prevNode.kind}';
  }
  return node;
}


void main() {
  // bruteSearchPlanetApsis(Body.Mercury, AstroTime(34.22)).dist_km
  // print(nextTransit(Body.Venus, DateTime.now()));
  AstroTime time = AstroTime(64473.24);

  // print( rotationAxis(Body.Mars, time).dec);

  print(StateVector.lagrangePoint(1,time,Body.Earth,Body.Moon).y);
  // print(NodeEventKind.index());
}
