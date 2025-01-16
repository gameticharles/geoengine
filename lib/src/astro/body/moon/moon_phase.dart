part of '../../astronomy.dart';

/// Determines the moon's phase expressed as an ecliptic longitude.
///
/// @param {FlexibleDateTime} date
///      The date and time for which to calculate the moon's phase.
///
/// @returns {number}
///      A value in the range [0, 360) indicating the difference
///      in ecliptic longitude between the center of the Sun and the
///      center of the Moon, as seen from the center of the Earth.
///      Certain longitude values have conventional meanings:
///
/// * 0 = new moon
/// * 90 = first quarter
/// * 180 = full moon
/// * 270 = third quarter
double moonPhase(dynamic date) {
  return pairLongitude(Body.Moon, Body.Sun, date);
}

/// Searches for the date and time that the Moon reaches a specified phase.
///
/// Lunar phases are defined in terms of geocentric ecliptic longitudes
/// with respect to the Sun.  When the Moon and the Sun have the same ecliptic
/// longitude, that is defined as a new moon. When the two ecliptic longitudes
/// are 180 degrees apart, that is defined as a full moon.
/// To enumerate quarter lunar phases, it is simpler to call {@link SearchMoonQuarter} once, followed by repeatedly calling {@link NextMoonQuarter}. `SearchMoonPhase` is only
/// necessary for finding other lunar phases than the usual quarter phases.
///
/// @param {number} targetLon
///      The difference in geocentric ecliptic longitude between the Sun and Moon
///      that specifies the lunar phase being sought. This can be any value
///      in the range [0, 360). Here are some helpful examples:
///      0 = new moon,
///      90 = first quarter,
///      180 = full moon,
///      270 = third quarter.
///
/// @param {FlexibleDateTime} dateStart
///      The beginning of the window of time in which to search.
///
/// @param {number} limitDays
///      The floating point number of days away from `dateStart`
///      that limits the window of time in which to search.
///      If the value is negative, the search is performed into the past from `startTime`.
///      Otherwise, the search is performed into the future from `startTime`.
///
/// @returns {AstroTime | null}
///      If successful, returns the date and time the moon reaches the phase specified by `targetlon`.
///      This function will return `null` if the phase does not occur within `limitDays` of `startTime`;
///      that is, if the search window is too small.
AstroTime? searchMoonPhase(
    double targetLon, dynamic dateStart, double limitDays) {
  double moonOffset(AstroTime t) {
    double mLon = moonPhase(t);
    return LongitudeOffset(mLon - targetLon);
  }

  verifyNumber(targetLon);
  verifyNumber(limitDays);

  const double uncertainty = 1.5;
  AstroTime ta = AstroTime(dateStart);
  double ya = moonOffset(ta);
  double estDt, dt1, dt2;
  if (limitDays < 0) {
    if (ya < 0) ya += 360;
    estDt = -(MEAN_SYNODIC_MONTH * ya) / 360;
    dt2 = estDt + uncertainty;
    if (dt2 < limitDays) return null;
    dt1 = (limitDays > estDt - uncertainty) ? limitDays : estDt - uncertainty;
  } else {
    if (ya > 0) ya -= 360;
    estDt = -(MEAN_SYNODIC_MONTH * ya) / 360;
    dt1 = estDt - uncertainty;
    if (dt1 > limitDays) return null;
    dt2 = (limitDays < estDt + uncertainty) ? limitDays : estDt + uncertainty;
  }
  AstroTime t1 = ta.addDays(dt1);
  AstroTime t2 = ta.addDays(dt2);
  return search(moonOffset, t1, t2,
      options: SearchOptions(dtToleranceSeconds: 0.1));
}

/// A quarter lunar phase, along with when it occurs.
///
/// @property {number} quarter
///      An integer as follows:
///      0 = new moon,
///      1 = first quarter,
///      2 = full moon,
///      3 = third quarter.
///
/// @property {AstroTime} time
///      The date and time of the quarter lunar phase.
class MoonQuarter {
  final int quarterIndex;
  final AstroTime time;

  MoonQuarter(this.quarterIndex, this.time);

  /// Get the name of the Moon quarter
  String get quarter =>
      ['New Moon', 'First Quarter', 'Full Moon', 'Third Quarter'][quarterIndex];

  /// Finds the first quarter lunar phase after the specified date and time.
  ///
  /// The quarter lunar phases are: new moon, first quarter, full moon, and third quarter.
  /// To enumerate quarter lunar phases, call `SearchMoonQuarter` once,
  /// then pass its return value to {@link NextMoonQuarter} to find the next
  /// `MoonQuarter`. Keep calling `NextMoonQuarter` in a loop,
  /// passing the previous return value as the argument to the next call.
  ///
  /// @param {FlexibleDateTime} dateStart
  ///      The date and time after which to find the first quarter lunar phase.
  ///
  /// @returns {MoonQuarter}
  static MoonQuarter searchMoonQuarter(dynamic dateStart) {
    double phaseStart = moonPhase(dateStart);
    int quarterStart = (phaseStart ~/ 90).floor();
    int quarter = (quarterStart + 1) % 4;
    AstroTime? time = searchMoonPhase(90 * quarter.toDouble(), dateStart, 10);
    if (time == null) {
      throw Exception('Cannot find moon quarter');
    }
    return MoonQuarter(quarter, time);
  }

  /// Finds the next quarter lunar phase in a series.
  ///
  /// Given a {@link MoonQuarter} object, finds the next consecutive
  /// quarter lunar phase. See remarks in {@link SearchMoonQuarter}
  /// for explanation of usage.
  ///
  /// @param {MoonQuarter} mq
  ///      The return value of a prior call to {@link MoonQuarter} or `NextMoonQuarter`.
  ///
  /// @returns {MoonQuarter}
  static MoonQuarter nextMoonQuarter(MoonQuarter mq) {
    DateTime date = mq.time.date.add(Duration(days: 6));
    return searchMoonQuarter(date);
  }
}

double moonMagnitude(double phase, double helioDist, double geoDist) {
  // https://astronomy.stackexchange.com/questions/10246/is-there-a-simple-analytical-formula-for-the-lunar-phase-brightness-curve
  double rad = phase * DEG2RAD;
  double rad2 = rad * rad;
  double rad4 = rad2 * rad2;
  double mag = -12.717 + 1.49 * rad.abs() + 0.0431 * rad4;

  const moonMeanDistanceAU = 385000.6 / KM_PER_AU;
  double geoAU = geoDist / moonMeanDistanceAU;
  mag += 5 * log10(helioDist * geoAU);

  return mag;
}
