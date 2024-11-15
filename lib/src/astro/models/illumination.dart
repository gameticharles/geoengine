part of '../astronomy.dart';

/// @brief Information about the apparent brightness and sunlit phase of a celestial object.
///
/// @property {AstroTime} time
///      The date and time pertaining to the other calculated values in this object.
///
/// @property {number} mag
///      The <a href="https://en.wikipedia.org/wiki/Apparent_magnitude">apparent visual magnitude</a> of the celestial body.
///
/// @property {number} phase_angle
///      The angle in degrees as seen from the center of the celestial body between the Sun and the Earth.
///      The value is always in the range 0 to 180.
///      The phase angle provides a measure of what fraction of the body's face appears
///      illuminated by the Sun as seen from the Earth.
///      When the observed body is the Sun, the `phase` property is set to 0,
///      although this has no physical meaning because the Sun emits, rather than reflects, light.
///      When the phase is near 0 degrees, the body appears "full".
///      When it is 90 degrees, the body appears "half full".
///      And when it is 180 degrees, the body appears "new" and is very difficult to see
///      because it is both dim and lost in the Sun's glare as seen from the Earth.
///
/// @property {number} phase_fraction
///      The fraction of the body's face that is illuminated by the Sun, as seen from the Earth.
///      Calculated from `phase_angle` for convenience.
///      This value ranges from 0 to 1.
///
/// @property {number} helio_dist
///      The distance between the center of the Sun and the center of the body in
///      <a href="https://en.wikipedia.org/wiki/Astronomical_unit">astronomical units</a> (AU).
///
/// @property {number} geo_dist
///      The distance between the center of the Earth and the center of the body in AU.
///
/// @property {Vector} gc
///      Geocentric coordinates: the 3D vector from the center of the Earth to the center of the body.
///      The components are in expressed in AU and are oriented with respect to the J2000 equatorial plane.
///
/// @property {Vector} hc
///      Heliocentric coordinates: The 3D vector from the center of the Sun to the center of the body.
///      Like `gc`, `hc` is expressed in AU and oriented with respect
///      to the J2000 equatorial plane.
///
/// @property {number | undefined} ring_tilt
///      For Saturn, this is the angular tilt of the planet's rings in degrees away
///      from the line of sight from the Earth. When the value is near 0, the rings
///      appear edge-on from the Earth and are therefore difficult to see.
///      When `ring_tilt` approaches its maximum value (about 27 degrees),
///      the rings appear widest and brightest from the Earth.
///      Unlike the <a href="https://ssd.jpl.nasa.gov/horizons.cgi">JPL Horizons</a> online tool,
///      this library includes the effect of the ring tilt angle in the calculated value
///      for Saturn's visual magnitude.
///      For all bodies other than Saturn, the value of `ring_tilt` is `undefined`.
class IlluminationInfo {
  AstroTime time;
  double mag;
  double phaseAngle;
  double helioDist;
  double geoDist;
  AstroVector gc;
  AstroVector hc;
  double? ringTilt;
  double phaseFraction;

  IlluminationInfo({
    required this.time,
    required this.mag,
    required this.phaseAngle,
    required this.helioDist,
    required this.geoDist,
    required this.gc,
    required this.hc,
    this.ringTilt,
  }) : phaseFraction = (1 + cos(DEG2RAD * phaseAngle)) / 2;

  /// @brief Calculates visual magnitude and related information about a body.
  ///
  /// Calculates the phase angle, visual magnitude,
  /// and other values relating to the body's illumination
  /// at the given date and time, as seen from the Earth.
  ///
  /// @param {Body} body
  ///      The name of the celestial body being observed.
  ///      Not allowed to be `Body.Earth`.
  ///
  /// @param {FlexibleDateTime} date
  ///      The date and time for which to calculate the illumination data for the given body.
  ///
  /// @returns {IlluminationInfo}
  static IlluminationInfo getBodyIllumination(Body body, dynamic date) {
    if (body == Body.Earth) {
      throw Exception('The illumination of the Earth is not defined.');
    }

    final time = AstroTime(date);
    final earth = calcVsop(vsopTable["Earth"]!, time);
    double
        phase; // phase angle in degrees between Earth and Sun as seen from body
    AstroVector hc; // vector from Sun to body
    AstroVector gc; // vector from Earth to body
    double mag; // visual magnitude

    if (body == Body.Sun) {
      gc = AstroVector(-earth.x, -earth.y, -earth.z, time);
      hc = AstroVector(0, 0, 0, time);
      phase =
          0; // a placeholder value; the Sun does not have an illumination phase because it emits, rather than reflects, light.
    } else {
      if (body == Body.Moon) {
        // For extra numeric precision, use geocentric moon formula directly.
        gc = Moon(time).geoMoon();
        hc = AstroVector(earth.x + gc.x, earth.y + gc.y, earth.z + gc.z, time);
      } else {
        // For planets, heliocentric vector is most direct to calculate.
        hc = helioVector(body, date);
        gc = AstroVector(hc.x - earth.x, hc.y - earth.y, hc.z - earth.z, time);
      }
      phase = angleBetween(gc, hc);
    }

    final geoDist = gc.length(); // distance from body to center of Earth
    final helioDist = hc.length(); // distance from body to center of Sun
    double? ringTilt; // only reported for Saturn

    if (body == Body.Sun) {
      mag = SUN_MAG_1AU + 5 * log10(geoDist);
      // print("This is the sun");
    } else if (body == Body.Moon) {
      // print("This is the Moon");
      mag = moonMagnitude(phase, helioDist, geoDist);
    } else if (body == Body.Saturn) {
      final saturn = saturnMagnitude(phase, helioDist, geoDist, gc, time);
      // print("This is the Saturn");
      mag = saturn.mag;
      ringTilt = saturn.ringTilt;
    } else {
      // print("This is any other body");
      mag = visualMagnitude(body, phase, helioDist, geoDist);
    }
    // print(time);
    // print(mag);
    // print(phase);
    // print(helioDist);
    // print(geoDist);
    // print(gc);
    // print(hc);
    // print(ringTilt);
    return IlluminationInfo(
      time: time,
      mag: mag,
      phaseAngle: phase,
      helioDist: helioDist,
      geoDist: geoDist,
      gc: gc,
      hc: hc,
      ringTilt: ringTilt,
    );
  }

  /// @brief Searches for the date and time Venus will next appear brightest as seen from the Earth.
  ///
  /// @param {Body} body
  ///      Currently only `Body.Venus` is supported.
  ///      Mercury's peak magnitude occurs at superior conjunction, when it is impossible to see from Earth,
  ///      so peak magnitude events have little practical value for that planet.
  ///      The Moon reaches peak magnitude very close to full moon, which can be found using
  ///      {@link SearchMoonQuarter} or {@link SearchMoonPhase}.
  ///      The other planets reach peak magnitude very close to opposition,
  ///      which can be found using {@link SearchRelativeLongitude}.
  ///
  /// @param {FlexibleDateTime} startDate
  ///      The date and time after which to find the next peak magnitude event.
  ///
  /// @returns {IlluminationInfo}
  static IlluminationInfo searchPeakMagnitude(Body body, dynamic startDate) {
    if (body != Body.Venus) {
      throw 'SearchPeakMagnitude currently works for Venus only.';
    }

  const double dt = 0.01;

  double slope(AstroTime t) {
    // The Search() function finds a transition from negative to positive values.
    // The derivative of magnitude y with respect to time t (dy/dt)
    // is negative as an object gets brighter, because the magnitude numbers
    // get smaller. At peak magnitude dy/dt = 0, then as the object gets dimmer,
    // dy/dt > 0.
    AstroTime t1 = t.addDays(-dt / 2);
    AstroTime t2 = t.addDays(dt / 2);
    double y1 = IlluminationInfo.getBodyIllumination(body, t1).mag; // Replace with your actual method to get magnitude
    double y2 = IlluminationInfo.getBodyIllumination(body, t2).mag; // Replace with your actual method to get magnitude
    double m = (y2 - y1) / dt;
    return m;
  }

  AstroTime startTime = AstroTime(startDate);

  // s1 and s2 are relative longitudes within which peak magnitude of Venus can occur.
  const double s1 = 10.0;
  const double s2 = 30.0;

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
    if (rlon >= -s1 && rlon < s1) {
      // Seek to the window [+s1, +s2].
      adjustDays = 0;
      // Search forward for the time t1 when rel lon = +s1.
      rlonLo = s1;
      // Search forward for the time t2 when rel lon = +s2.
      rlonHi = s2;
    } else if (rlon >= s2 || rlon < -s2) {
      // Seek to the next search window at [-s2, -s1].
      adjustDays = 0;
      // Search forward for the time t1 when rel lon = -s2.
      rlonLo = -s2;
      // Search forward for the time t2 when rel lon = -s1.
      rlonHi = -s1;
    } else if (rlon >= 0) {
      // rlon must be in the middle of the window [+s1, +s2].
      // Search BACKWARD for the time t1 when rel lon = +s1.
      adjustDays = -synodicPeriod(body) / 4;
      rlonLo = s1;
      // Search forward from t1 to find t2 such that rel lon = +s2.
      rlonHi = s2;
    } else {
      // rlon must be in the middle of the window [-s2, -s1].
      // Search BACKWARD for the time t1 when rel lon = -s2.
      adjustDays = -synodicPeriod(body) / 4;
      rlonLo = -s2;
      // Search forward from t1 to find t2 such that rel lon = -s1.
      rlonHi = -s1;
    }

    AstroTime tStart = startTime.addDays(adjustDays);
    AstroTime t1 = searchRelativeLongitude(body, rlonLo, tStart);
    AstroTime t2 = searchRelativeLongitude(body, rlonHi, t1);

    // Now we have a time range [t1,t2] that brackets a maximum magnitude event.
    // Confirm the bracketing.
    double m1 = slope(t1);
    if (m1 >= 0) {
      throw 'SearchPeakMagnitude: internal error: m1 = $m1';
    }

    double m2 = slope(t2);
    if (m2 <= 0) {
      throw 'SearchPeakMagnitude: internal error: m2 = $m2';
    }

    // Use the generic search algorithm to home in on where the slope crosses from negative to positive.
    AstroTime? tx = search(slope, t1, t2, options: SearchOptions(initF1: m1, initF2: m2, dtToleranceSeconds: 10));
    
    if (tx == null) {
      throw 'SearchPeakMagnitude: failed search iter $iter (t1=${t1.toString()}, t2=${t2.toString()})';
    }

    if (tx.tt >= startTime.tt) {
      return IlluminationInfo.getBodyIllumination(body, tx); // Replace with your actual method to get IlluminationInfo
    }

    // This event is in the past (earlier than startDate).
    // We need to search forward from t2 to find the next possible window.
    // We never need to search more than twice.
    startTime = t2.addDays(1);
  }

  throw 'SearchPeakMagnitude: failed to find event after 2 tries.';
}

}
