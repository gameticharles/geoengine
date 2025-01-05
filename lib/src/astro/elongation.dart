part of 'astronomy.dart';

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
///      The elongation is always in the range `(0, 180)`.
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

  ElongationEvent(
      this.time, this.visibility, this.elongation, this.eclipticSeparation);

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
  factory ElongationEvent.elongation(Body body, dynamic date) {
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
  static ElongationEvent searchMaxElongation(Body body, dynamic startDate) {
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
      AstroTime? tx = search(negSlope, t1, t2,
          options:
              SearchOptions(initF1: m1, initF2: m2, dtToleranceSeconds: 10));

      if (tx == null) {
        throw 'SearchMaxElongation: failed search iter $iter (t1=${t1.toString()}, t2=${t2.toString()})';
      }

      if (tx.tt >= startTime.tt) {
        return ElongationEvent.elongation(body, tx);
      }

      // This event is in the past (earlier than startDate).
      // We need to search forward from t2 to find the next possible window.
      // We never need to search more than twice.
      startTime = t2.addDays(1);
    }

    throw 'SearchMaxElongation: failed to find event after 2 tries.';
  }
}
