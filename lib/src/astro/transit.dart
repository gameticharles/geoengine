part of 'astronomy.dart';

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

  /// @brief Searches for the first transit of Mercury or Venus after a given date.
  ///
  /// Finds the first transit of Mercury or Venus after a specified date.
  /// A transit is when an inferior planet passes between the Sun and the Earth
  /// so that the silhouette of the planet is visible against the Sun in the background.
  /// To continue the search, pass the `finish` time in the returned structure to {@link NextTransit}.
  ///
  /// @param {Body} body
  ///      The planet whose transit is to be found. Must be `Body.Mercury` or `Body.Venus`.
  ///
  /// @param {FlexibleDateTime} startTime
  ///      The date and time for starting the search for a transit.
  ///
  /// @returns {TransitInfo}
  static TransitInfo searchTransit(Body body, dynamic startTime) {
    startTime = AstroTime(startTime);
    const double thresholdAngle =
        0.4; // maximum angular separation to attempt transit calculation
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
        final shadow = ShadowInfo.peakPlanetShadow(body, planetRadiusKm, conj);

        if (shadow.r < shadow.p) {
          // does the planet's penumbra touch the Earth's center?
          // Find the beginning and end of the penumbral contact.
          final timeBefore = shadow.time.addDays(-dtDays);
          final start = planetTransitBoundary(
              body, planetRadiusKm, timeBefore, shadow.time, -1.0);
          final timeAfter = shadow.time.addDays(dtDays);
          final finish = planetTransitBoundary(
              body, planetRadiusKm, shadow.time, timeAfter, 1.0);
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
  static TransitInfo nextTransit(Body body, dynamic prevTransitTime) {
    prevTransitTime = AstroTime(prevTransitTime);
    final startTime = prevTransitTime.addDays(100.0);
    return searchTransit(body, startTime);
  }

  static AstroTime planetTransitBoundary(Body body, double planetRadiusKm,
      AstroTime t1, AstroTime t2, double direction) {
    // Search for the time the planet's penumbra begins/ends making contact with the center of the Earth.
    final tx = search(
        (AstroTime time) => ShadowInfo.planetShadowBoundary(
            time, body, planetRadiusKm, direction),
        t1,
        t2);
    if (tx == null) {
      throw 'Planet transit boundary search failed';
    }
    return tx;
  }
}
