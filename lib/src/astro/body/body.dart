// ignore_for_file: constant_identifier_names, non_constant_identifier_names

part of '../astronomy.dart';

enum BodyType {
  Planet,
  Star,
  Barycenter,
  UserDefinedStar,
}

class CelestialBody {
  ///  A string representing the name of the body (e.g., "Sun," "Mars," "Star1")
  final String name;

  /// An enum or string representing the category of the body (e.g., "Planet," "Star," "Barycenter").
  final BodyType type;

  /// The product of mass and universal gravitational constant for the body.
  final double GM;

  /// The physical radius of the body (optional).
  final double? radius; // Optional

  /// The mass of the body (optional, may be inferred from GM)
  final double? mass; // Optional (may be inferred from GM)

  /// The radius of the body at the equator (optional).
  final double? equatorialRadius;

  /// The radius of the body at the poles (optional)
  final double? polarRadius;

  /// The difference between the equatorial and polar radius (optional).
  final double? flattening;

  // Constructor to initialize a Body object
  CelestialBody({
    required this.name,
    required this.type,
    required this.GM,
    this.radius,
    this.mass,
    this.equatorialRadius,
    this.polarRadius,
    this.flattening,
  });

  // Methods to calculate astronomical properties (examples)
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

class BodyPosition {
  final Body observerBody;
  final Body targetBody;
  final bool aberration;
  AstroVector observerPos;

  BodyPosition(
      this.observerBody, this.targetBody, this.aberration, this.observerPos);

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
    case Body.Sun:
      return SUN_GM;
    case Body.Mercury:
      return MERCURY_GM;
    case Body.Venus:
      return VENUS_GM;
    case Body.Earth:
      return EARTH_GM;
    case Body.Moon:
      return MOON_GM;
    case Body.EMB:
      return EARTH_GM + MOON_GM;
    case Body.Mars:
      return MARS_GM;
    case Body.Jupiter:
      return JUPITER_GM;
    case Body.Saturn:
      return SATURN_GM;
    case Body.Uranus:
      return URANUS_GM;
    case Body.Neptune:
      return NEPTUNE_GM;
    case Body.Pluto:
      return PLUTO_GM;
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
  {"ra": 0, "dec": 0, "dist": 0}, // Body.Star1
  {"ra": 0, "dec": 0, "dist": 0}, // Body.Star2
  {"ra": 0, "dec": 0, "dist": 0}, // Body.Star3
  {"ra": 0, "dec": 0, "dist": 0}, // Body.Star4
  {"ra": 0, "dec": 0, "dist": 0}, // Body.Star5
  {"ra": 0, "dec": 0, "dist": 0}, // Body.Star6
  {"ra": 0, "dec": 0, "dist": 0}, // Body.Star7
  {"ra": 0, "dec": 0, "dist": 0}, // Body.Star8
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

StateVector exportState(BodyState terse, AstroTime time) {
  return StateVector(
      terse.r.x, terse.r.y, terse.r.z, terse.v.x, terse.v.y, terse.v.z, time);
}

void adjustBarycenter(
    AstroVector ssb, AstroTime time, Body body, double pmass) {
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
    return AstroVector(
        e.x + (m.x / denom), e.y + (m.y / denom), e.z + (m.z / denom), time);
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
      var earth = calcVsopPosVel(
          vsopTable[Body.Earth.toString().split('.').last]!, time.tt);
      var state = (body == Body.Moon)
          ? Moon.geoMoonState(time)
          : Moon.geoEmbState(time);
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

  if (userDefinedStar(targetBody) != null) {
    // Handle user-defined stars as a special case.
    // Assuming heliocentric position does not change with time and is already corrected for light travel time.
    var tvec = helioVector(targetBody, time);

    if (aberration) {
      // Calculate aberration-corrected direction to the target body.
      var ostate = helioState(observerBody, time);
      var rvec = AstroVector(
          tvec.x - ostate.x, tvec.y - ostate.y, tvec.z - ostate.z, time);
      var s = C_AUDAY /
          rvec.length(); // Conversion factor from relative distance to speed of light
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
///      This is needed to get correct horizontal coordinates when you call {@link Horizon}.
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
  var gcObserver = Observer.geoPos(time, observer);
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
  var star = userDefinedStar(
      body); // Assuming userDefinedStar function is defined elsewhere
  if (star != null) {
    return star['dist']!;
  }

  var time =
      AstroTime(date); // Assuming AstroTime function is defined elsewhere
  if (vsopTable.containsKey(body.name)) {
    return vsopFormula(
        vsopTable[body.name]![radIndex], time.tt / daysPerMillennium, false);
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
      final earth = calcVsopPosVel(vsopTable[Body.Earth.name]!, time.tt);
      final state = (body == Body.Moon)
          ? Moon.geoMoonState(time)
          : Moon.geoEmbState(time);
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
  return eclip.eLon;
}

double log10(num x) => log(x) / ln10;

double visualMagnitude(
    Body body, double phase, double helioDist, double geoDist) {
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

double synodicPeriod(Body body) {
  if (body == Body.Earth) {
    throw Exception(
        'The Earth does not have a synodic period as seen from itself.');
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
  final synodicPeriod =
      (earthOrbitalPeriod / (earthOrbitalPeriod / planetInfo.orbitalPeriod - 1))
          .abs();

  return synodicPeriod;
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

  return NormalizeLongitude(eclip1.eLon - eclip2.eLon);
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
AstroTime searchRelativeLongitude(
    Body body, double targetRelLon, dynamic startDate) {
  verifyNumber(targetRelLon);
  final planet = planetTable[body.name]!;
  if (body == Body.Earth) {
    throw Exception(
        'Cannot search relative longitude for the Earth (it is always 0).');
  }

  final direction =
      planet.orbitalPeriod > planetTable["Earth"]!.orbitalPeriod ? 1 : -1;

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

  throw Exception(
      'Relative longitude search failed to converge for $body near ${time.toString()} (error_angle = $errorAngle).');
}

double horizonDipAngle(Observer observer, double metersAboveGround) {
  // Calculate the effective radius of the Earth at ground level below the observer.
  // Correct for the Earth's oblateness.
  double phi = observer.latitude * DEG2RAD;
  double sinphi = sin(phi);
  double cosphi = cos(phi);
  double c = 1.0 / hypot(cosphi, sinphi * EARTH_FLATTENING);
  double s = c * (EARTH_FLATTENING * EARTH_FLATTENING);
  double htKm = (observer.height - metersAboveGround) /
      1000.0; // height of ground above sea level
  double ach = EARTH_EQUATORIAL_RADIUS_KM * c + htKm;
  double ash = EARTH_EQUATORIAL_RADIUS_KM * s + htKm;
  double radiusM = 1000.0 * hypot(ach * cosphi, ash * sinphi);

  // Correct refraction of a ray of light traveling tangent to the Earth's surface.
  // Based on: https://www.largeformatphotography.info/sunmooncalc/SMCalc.js
  // which in turn derives from:
  // Sweer, John. 1938.  The Path of a Ray of Light Tangent to the Surface of the Earth.
  // Journal of the Optical Society of America 28 (September):327-329.

  // k = refraction index
  double k = 0.175 *
      pow(
          1.0 -
              (6.5e-3 / 283.15) *
                  (observer.height - (2.0 / 3.0) * metersAboveGround),
          3.256);

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
  return (360.0 / SOLAR_DAYS_PER_SIDEREAL_DAY - derivRa).abs() * cos(latrad) +
      derivDec.abs() * sin(latrad);
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
    final hor =
        HorizontalCoordinates.horizon(time, observer, ofdate.ra, ofdate.dec);
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

    final ascent =
        AscentInfo.findAscent(0, altdiff, maxDerivAlt, t1, t2, a1, a2);
    if (ascent != null) {
      final time = search(altdiff, ascent.tx, ascent.ty,
          options: SearchOptions(
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

      throw Exception(
          'Rise/set search failed after finding ascent: t1=$t1, t2=$t2, a1=$a1, a2=$a2');
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
AstroTime? searchRiseSet(Body body, Observer observer, double direction,
    dynamic dateStart, double limitDays,
    {double metersAboveGround = 0.0}) {
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
  return internalSearchAltitude(body, observer, direction, dateStart, limitDays,
      bodyRadiusAuValue, altitude);
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
AstroTime? searchAltitude(Body body, Observer observer, double direction,
    dynamic dateStart, double limitDays, double altitude) {
  if (!altitude.isFinite || altitude < -90 || altitude > 90) {
    throw Exception('Invalid altitude angle: $altitude');
  }

  return internalSearchAltitude(
      body, observer, direction, dateStart, limitDays, 0, altitude);
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
    Body body, Observer observer, double hourAngle, dynamic dateStart,
    {double direction = 1}) {
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
    var deltaSiderealHours =
        ((hourAngle + ofdate.ra - observer.longitude / 15) - gast) % 24;
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
      var hor = HorizontalCoordinates.horizon(
          time, observer, ofdate.ra, ofdate.dec, 'normal');
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
/// This function returns the hour angle of the body as seen at the given time and geographic location.
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

/// Calculates the body's position in equatorial and horizontal coordinates.
///
/// This function takes the body, date, and observer information, and calculates
/// the body's position in both equatorial (right ascension and declination) and
/// horizontal (azimuth and altitude) coordinates.
///
/// @param body The celestial body to calculate the position for.
/// @param date The date and time for which to calculate the position.
/// @param observer The observer's location and other relevant information.
/// @return A map containing the body's equatorial and horizontal coordinates.
({double ra, double dec, double azimuth, double altitude}) bodyPosition(
    Body body, dynamic date, Observer observer) {
  var equ2000 = equator(body, date, observer, false, true);
  var equOfDate = equator(body, date, observer, true, true);
  var hor = HorizontalCoordinates.horizon(
      date, observer, equOfDate.ra, equOfDate.dec, 'normal');

  return (
    ra: equ2000.ra,
    dec: equ2000.dec,
    azimuth: hor.azimuth,
    altitude: hor.altitude
  );
}
