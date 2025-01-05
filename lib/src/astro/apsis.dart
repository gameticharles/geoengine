part of 'astronomy.dart';

/// @brief A closest or farthest point in a body's orbit around its primary.
///
/// For a planet orbiting the Sun, apsis is a perihelion or aphelion, respectively.
/// For the Moon orbiting the Earth, apsis is a perigee or apogee, respectively.
///
/// @property {AstroTime} time
///      The date and time of the apsis.
///
/// @property {ApsisKind} kind
///      For a closest approach (perigee or perihelion), `kind` is `ApsisKind.Pericenter`.
///      For a farthest distance event (apogee or aphelion), `kind` is `ApsisKind.Apocenter`.
///
/// @property {number} dist_au
///      The distance between the centers of the two bodies in astronomical units (AU).
///
/// @property {number} dist_km
///      The distance between the centers of the two bodies in kilometers.
///
/// @see {@link SearchLunarApsis}
/// @see {@link NextLunarApsis}
/// @see {@link SearchPlanetApsis}
/// @see {@link NextPlanetApsis}
class Apsis {
  late double distKM;

  AstroTime time;
  ApsisKind kind;
  double distAU;

  Apsis(this.time, this.kind, this.distAU) {
    distKM = distAU * KM_PER_AU;
  }

  /// Finds the closest or farthest point in a body's orbit around its primary.
  ///
  /// This method uses a brute-force algorithm to search for the apsis (perihelion or aphelion for planets, perigee or apogee for the Moon) by sampling the heliocentric distance at multiple points along the orbit and finding the minimum or maximum distance.
  ///
  /// @param body The celestial body to search for the apsis.
  /// @param kind The type of apsis to search for (perihelion/aphelion or perigee/apogee).
  /// @param startTime The starting time for the search.
  /// @param daySpan The number of days to search around the starting time.
  /// @return An [Apsis] object containing the details of the found apsis.
  static Apsis planetExtreme(
      Body body, ApsisKind kind, AstroTime startTime, double daySpan) {
    final direction = (kind == ApsisKind.Apocenter) ? 1.0 : -1.0;
    const nPoints = 10;

    while (true) {
      final interval = daySpan / (nPoints - 1);

      // Iterate until uncertainty is less than one minute
      if (interval < 1.0 / 1440.0) {
        final apsisTime = startTime.addDays(interval / 2.0);
        final distAu = HelioDistance(body, apsisTime);
        return Apsis(apsisTime, kind, distAu);
      }

      int bestI = -1;
      double bestDist = 0.0;
      for (int i = 0; i < nPoints; ++i) {
        final time = startTime.addDays(i * interval);
        final dist = direction * HelioDistance(body, time);
        if (i == 0 || dist > bestDist) {
          bestI = i;
          bestDist = dist;
        }
      }

      // Narrow in on the extreme point
      startTime = startTime.addDays((bestI - 1) * interval);
      daySpan = 2.0 * interval;
    }
  }

  /// Finds the next perihelion or aphelion of a planet using a brute-force algorithm.
  ///
  /// This method is used for planets with nearly circular orbits, such as Neptune, where the standard slope-based algorithm cannot be used to reliably determine the apsides.
  ///
  /// The method samples the heliocentric distance of the planet at multiple points along the orbit and finds the minimum and maximum distances, which correspond to the perihelion and aphelion, respectively.
  ///
  /// @param body The planet for which to find the next perihelion or aphelion.
  /// @param startTime The starting time for the search.
  /// @return An [Apsis] object containing the details of the found apsis.
  static Apsis bruteSearchPlanetApsis(Body body, AstroTime startTime) {
    /*
    Neptune is a special case for two reasons:
    1. Its orbit is nearly circular (low orbital eccentricity).
    2. It is so distant from the Sun that the orbital period is very long.
    Put together, this causes wobbling of the Sun around the Solar System Barycenter (SSB)
    to be so significant that there are 3 local minima in the distance-vs-time curve
    near each apsis. Therefore, unlike for other planets, we can't use an optimized
    algorithm for finding dr/dt = 0.
    Instead, we use a dumb, brute-force algorithm of sampling and finding min/max
    heliocentric distance.

    There is a similar problem in the TOP2013 model for Pluto:
    Its position vector has high-frequency oscillations that confuse the
    slope-based determination of apsides.
  */

    /*
    Rewind approximately 30 degrees in the orbit,
    then search forward for 270 degrees.
    This is a very cautious way to prevent missing an apsis.
    Typically we will find two apsides, and we pick whichever
    apsis is earlier, but after startTime.
    Sample points around this orbital arc and find when the distance
    is greatest and smallest.
  */
    const nPoints = 100;
    final t1 =
        startTime.addDays(planetTable[body.name]!.orbitalPeriod * (-30 / 360));
    final t2 =
        startTime.addDays(planetTable[body.name]!.orbitalPeriod * (270 / 360));
    var tMin = t1;
    var tMax = t1;
    var minDist = -1.0;
    var maxDist = -1.0;
    final interval = (t2.ut - t1.ut) / (nPoints - 1);

    for (var i = 0; i < nPoints; ++i) {
      final time = t1.addDays(i * interval);
      final dist = HelioDistance(body, time);
      if (i == 0) {
        maxDist = minDist = dist;
      } else {
        if (dist > maxDist) {
          maxDist = dist;
          tMax = time;
        }
        if (dist < minDist) {
          minDist = dist;
          tMin = time;
        }
      }
    }

    final perihelion = planetExtreme(
        body, ApsisKind.Pericenter, tMin.addDays(-2 * interval), 4 * interval);
    final aphelion = planetExtreme(
        body, ApsisKind.Apocenter, tMax.addDays(-2 * interval), 4 * interval);
    if (perihelion.time.tt >= startTime.tt) {
      if (aphelion.time.tt >= startTime.tt &&
          aphelion.time.tt < perihelion.time.tt) {
        return aphelion;
      }
      return perihelion;
    }
    if (aphelion.time.tt >= startTime.tt) {
      return aphelion;
    }
    throw 'Internal error: failed to find Neptune apsis.';
  }

  /// @brief Finds the next perihelion or aphelion of a planet.
  ///
  /// Finds the date and time of a planet's perihelion (closest approach to the Sun)
  /// or aphelion (farthest distance from the Sun) after a given time.
  ///
  /// Given a date and time to start the search in `startTime`, this function finds the
  /// next date and time that the center of the specified planet reaches the closest or farthest point
  /// in its orbit with respect to the center of the Sun, whichever comes first
  /// after `startTime`.
  ///
  /// The closest point is called *perihelion* and the farthest point is called *aphelion*.
  /// The word *apsis* refers to either event.
  ///
  /// To iterate through consecutive alternating perihelion and aphelion events,
  /// call `SearchPlanetApsis` once, then use the return value to call {@link NextPlanetApsis}. After that, keep feeding the previous return value
  /// from `NextPlanetApsis` into another call of `NextPlanetApsis`
  /// as many times as desired.
  ///
  /// @param {Body} body
  ///      The planet for which to find the next perihelion/aphelion event.
  ///      Not allowed to be `Body.Sun` or `Body.Moon`.
  ///
  /// @param {FlexibleDateTime} startTime
  ///      The date and time at which to start searching for the next perihelion or aphelion.
  ///
  /// @returns {Apsis}
  ///      The next perihelion or aphelion that occurs after `startTime`.
  static Apsis searchPlanetApsis(Body body, dynamic startTime) {
    startTime = AstroTime(startTime);
    if (body == Body.Neptune || body == Body.Pluto) {
      return bruteSearchPlanetApsis(body, startTime);
    }

    double positiveSlope(AstroTime t) {
      const dt = 0.001;
      final t1 = t.addDays(-dt / 2);
      final t2 = t.addDays(dt / 2);
      final r1 = HelioDistance(body, t1);
      final r2 = HelioDistance(body, t2);
      final m = (r2 - r1) / dt;
      return m;
    }

    double negativeSlope(AstroTime t) {
      return -positiveSlope(t);
    }

    final orbitPeriodDays = planetTable[body.name]!.orbitalPeriod;
    final increment = orbitPeriodDays / 6.0;
    var t1 = startTime;
    var m1 = positiveSlope(t1);

    for (var iter = 0; iter * increment < 2.0 * orbitPeriodDays; ++iter) {
      final t2 = t1.addDays(increment);
      final m2 = positiveSlope(t2);

      if (m1 * m2 <= 0.0) {
        // There is a change of slope polarity within the time range [t1, t2].
        // Therefore, this time range contains an apsis.
        // Figure out whether it is perihelion or aphelion.

        dynamic slopeFunc;
        ApsisKind kind;

        if (m1 < 0.0 || m2 > 0.0) {
          // We found a minimum-distance event: perihelion.
          // Search the time range for the time when the slope goes from negative to positive.
          slopeFunc = positiveSlope;
          kind = ApsisKind.Pericenter;
        } else if (m1 > 0.0 || m2 < 0.0) {
          // We found a maximum-distance event: aphelion.
          // Search the time range for the time when the slope goes from positive to negative.
          slopeFunc = negativeSlope;
          kind = ApsisKind.Apocenter;
        } else {
          // This should never happen. It should not be possible for both slopes to be zero.
          throw "Internal error with slopes in SearchPlanetApsis";
        }

        final searchResult = search(slopeFunc, t1, t2);
        if (searchResult == null) {
          throw "Failed to find slope transition in planetary apsis search.";
        }

        final dist = HelioDistance(body, searchResult);
        return Apsis(searchResult, kind, dist);
      }

      // We have not yet found a slope polarity change. Keep searching.
      t1 = t2;
      m1 = m2;
    }

    throw "Internal error: should have found planetary apsis within 2 orbital periods.";
  }

  /// @brief Finds the next planetary perihelion or aphelion event in a series.
  ///
  /// This function requires an {@link Apsis} value obtained from a call
  /// to {@link SearchPlanetApsis} or `NextPlanetApsis`.
  /// Given an aphelion event, this function finds the next perihelion event, and vice versa.
  /// See {@link SearchPlanetApsis} for more details.
  ///
  /// @param {Body} body
  ///      The planet for which to find the next perihelion/aphelion event.
  ///      Not allowed to be `Body.Sun` or `Body.Moon`.
  ///      Must match the body passed into the call that produced the `apsis` parameter.
  ///
  /// @param {Apsis} apsis
  ///      An apsis event obtained from a call to {@link SearchPlanetApsis} or `NextPlanetApsis`.
  ///
  /// @returns {Apsis}
  ///      Same as the return value for {@link SearchPlanetApsis}.
  static Apsis nextPlanetApsis(Body body, Apsis apsis) {
    if (apsis.kind != ApsisKind.Pericenter &&
        apsis.kind != ApsisKind.Apocenter) {
      throw "Invalid apsis kind: ${apsis.kind}";
    }

    // Skip 1/4 of an orbit before starting the search again
    final skip = 0.25 * planetTable[body.name]!.orbitalPeriod;
    final time = apsis.time.addDays(skip);
    final next = searchPlanetApsis(body, time);

    // Verify that we found the opposite apsis from the previous one
    if (next.kind.index + apsis.kind.index != 1) {
      throw "Internal error: previous apsis was ${apsis.kind}, but found ${next.kind} for next apsis.";
    }

    return next;
  }
}
