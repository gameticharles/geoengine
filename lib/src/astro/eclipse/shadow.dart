part of '../astronomy.dart';

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

  static ShadowInfo calcShadow(double bodyRadiusKm, AstroTime time,
      AstroVector target, AstroVector dir) {
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

  static ShadowInfo earthShadow(AstroTime time) {
    // Light-travel and aberration corrected vector from the Earth to the Sun.
    AstroVector s = geoVector(Body.Sun, time, true);
    // The vector e = -s is thus the path of sunlight through the center of the Earth.
    AstroVector e = AstroVector(-s.x, -s.y, -s.z,
        s.time); // Assuming `s.t` is not used in Vector constructor
    // Geocentric moon.
    AstroVector m = Moon(time).geoMoon();
    return calcShadow(EARTH_ECLIPSE_RADIUS_KM, time, m, e);
  }

  static ShadowInfo moonShadow(AstroTime time) {
    AstroVector s = geoVector(Body.Sun, time, true);
    AstroVector m = Moon(time).geoMoon(); // geocentric Moon
    // Calculate lunacentric Earth.
    AstroVector e = AstroVector(-m.x, -m.y, -m.z,
        m.time); // Assuming `m.t` is not used in Vector constructor
    // Convert geocentric moon to heliocentric Moon.
    m.x -= s.x;
    m.y -= s.y;
    m.z -= s.z;
    return calcShadow(MOON_MEAN_RADIUS_KM, time, e, m);
  }

  static ShadowInfo localMoonShadow(AstroTime time, Observer observer) {
    // Calculate observer's geocentric position.
    List<double> pos = geoPos(time, observer);

    // Calculate light-travel and aberration corrected Sun.
    AstroVector s = geoVector(Body.Sun, time, true);

    // Calculate geocentric Moon.
    AstroVector m = Moon(time).geoMoon(); // geocentric Moon

    // Calculate lunacentric location of an observer on the Earth's surface.
    AstroVector o = AstroVector(pos[0] - m.x, pos[1] - m.y, pos[2] - m.z,
        time); // Assuming `time` should be passed as `m.t`

    // Convert geocentric moon to heliocentric Moon.
    m.x -= s.x;
    m.y -= s.y;
    m.z -= s.z;

    return calcShadow(MOON_MEAN_RADIUS_KM, time, o, m);
  }

  static ShadowInfo planetShadow(
      Body body, double planetRadiusKm, AstroTime time) {
    // Calculate light-travel-corrected vector from Earth to planet.
    AstroVector g = geoVector(body, time, true);

    // Calculate light-travel-corrected vector from Earth to Sun.
    AstroVector e = geoVector(Body.Sun, time, true);

    // Deduce light-travel-corrected vector from Sun to planet.
    AstroVector p = AstroVector(g.x - e.x, g.y - e.y, g.z - e.z,
        time); // Assuming `time` should be passed as `g.t`

    // Calculate Earth's position from the planet's point of view.
    e.x = -g.x;
    e.y = -g.y;
    e.z = -g.z;

    return calcShadow(planetRadiusKm, time, e, p);
  }

  static double shadowDistanceSlope(
      ShadowInfo Function(AstroTime) shadowFunc, AstroTime time) {
    final dt = 1.0 / 86400.0;
    final t1 = time.addDays(-dt);
    final t2 = time.addDays(dt);
    final shadow1 = shadowFunc(t1);
    final shadow2 = shadowFunc(t2);
    return (shadow2.r - shadow1.r) / dt;
  }

  static double planetShadowSlope(
      Body body, double planetRadiusKm, AstroTime time) {
    final dt = 1.0 / 86400.0;
    final shadow1 = planetShadow(body, planetRadiusKm, time.addDays(-dt));
    final shadow2 = planetShadow(body, planetRadiusKm, time.addDays(dt));
    return (shadow2.r - shadow1.r) / dt;
  }

  static ShadowInfo peakEarthShadow(AstroTime searchCenterTime) {
    final window =
        0.03; /* initial search window, in days, before/after given time */
    final t1 = searchCenterTime.addDays(-window);
    final t2 = searchCenterTime.addDays(window);
    final tx = search(
        (AstroTime time) => shadowDistanceSlope(earthShadow, time), t1, t2);
    if (tx == null) {
      throw 'Failed to find peak Earth shadow time.';
    }
    return earthShadow(tx);
  }

  static ShadowInfo peakMoonShadow(AstroTime searchCenterTime) {
    final window =
        0.03; /* initial search window, in days, before/after given time */
    final t1 = searchCenterTime.addDays(-window);
    final t2 = searchCenterTime.addDays(window);
    final tx = search(
        (AstroTime time) => shadowDistanceSlope(moonShadow, time), t1, t2);
    if (tx == null) {
      throw 'Failed to find peak Moon shadow time.';
    }
    return moonShadow(tx);
  }

  static ShadowInfo peakPlanetShadow(
      Body body, double planetRadiusKm, AstroTime searchCenterTime) {
    // Search for when the body's shadow is closest to the center of the Earth.
    final window =
        1.0; // days before/after inferior conjunction to search for minimum shadow distance.
    final t1 = searchCenterTime.addDays(-window);
    final t2 = searchCenterTime.addDays(window);
    final tx = search(
        (AstroTime time) => planetShadowSlope(body, planetRadiusKm, time),
        t1,
        t2);
    if (tx == null) {
      throw 'Failed to find peak planet shadow time.';
    }
    return planetShadow(body, planetRadiusKm, tx);
  }

  static ShadowInfo peakLocalMoonShadow(
      AstroTime searchCenterTime, Observer observer) {
    // Search for the time near searchCenterTime that the Moon's shadow comes
    // closest to the given observer.
    final window = 0.2;
    final t1 = searchCenterTime.addDays(-window);
    final t2 = searchCenterTime.addDays(window);

    ShadowInfo shadowfunc(AstroTime time) {
      return localMoonShadow(time, observer);
    }

    final time = search(
        (AstroTime time) => shadowDistanceSlope(shadowfunc, time), t1, t2);
    if (time == null) {
      throw 'PeakLocalMoonShadow: search failure for searchCenterTime = $searchCenterTime';
    }
    return localMoonShadow(time, observer);
  }

  static double shadowSemiDurationMinutes(
      AstroTime centerTime, double radiusLimit, double windowMinutes) {
    // Search backwards and forwards from the center time until shadow axis distance crosses radius limit.
    final window = windowMinutes / (24.0 * 60.0);
    final before = centerTime.addDays(-window);
    final after = centerTime.addDays(window);

    final t1 = search((AstroTime time) => -(earthShadow(time).r - radiusLimit),
        before, centerTime);
    final t2 = search((AstroTime time) => (earthShadow(time).r - radiusLimit),
        centerTime, after);

    if (t1 == null || t2 == null) {
      throw 'Failed to find shadow semi-duration';
    }

    return (t2.ut - t1.ut) *
        ((24.0 * 60.0) /
            2.0); // convert days to minutes and average the semi-durations.
  }

  /// Calculates the boundary of a planet's shadow on the Earth.
  ///
  /// This function computes the distance between the center of the planet's shadow and the center of the Earth.
  /// The direction parameter determines whether the function should return the start or end of the planet's transit.
  ///
  /// @param time The time at which to calculate the planet's shadow boundary.
  /// @param body The planet whose shadow is being calculated.
  /// @param planetRadiusKm The radius of the planet in kilometers.
  /// @param direction The direction of the transit, either positive or negative.
  /// @return The distance between the center of the planet's shadow and the center of the Earth.
  static double planetShadowBoundary(
      AstroTime time, Body body, double planetRadiusKm, double direction) {
    // Call PlanetShadow function with appropriate arguments
    final shadow = planetShadow(body, planetRadiusKm, time);
    return direction * (shadow.r - shadow.p);
  }
}
