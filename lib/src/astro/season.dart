part of 'astronomy.dart';

/// When the seasons change for a given calendar year.
///
/// Represents the dates and times of the two solstices
/// and the two equinoxes in a given calendar year.
/// These four events define the changing of the seasons on the Earth.
///
/// @property {AstroTime} mar_equinox
///      The date and time of the March equinox in the given calendar year.
///      This is the moment in March that the plane of the Earth's equator passes
///      through the center of the Sun; thus the Sun's declination
///      changes from a negative number to a positive number.
///      The March equinox defines
///      the beginning of spring in the northern hemisphere and
///      the beginning of autumn in the southern hemisphere.
///
/// @property {AstroTime} jun_solstice
///      The date and time of the June solstice in the given calendar year.
///      This is the moment in June that the Sun reaches its most positive
///      declination value.
///      At this moment the Earth's north pole is most tilted most toward the Sun.
///      The June solstice defines
///      the beginning of summer in the northern hemisphere and
///      the beginning of winter in the southern hemisphere.
///
/// @property {AstroTime} sep_equinox
///      The date and time of the September equinox in the given calendar year.
///      This is the moment in September that the plane of the Earth's equator passes
///      through the center of the Sun; thus the Sun's declination
///      changes from a positive number to a negative number.
///      The September equinox defines
///      the beginning of autumn in the northern hemisphere and
///      the beginning of spring in the southern hemisphere.
///
/// @property {AstroTime} dec_solstice
///      The date and time of the December solstice in the given calendar year.
///      This is the moment in December that the Sun reaches its most negative
///      declination value.
///      At this moment the Earth's south pole is tilted most toward the Sun.
///      The December solstice defines
///      the beginning of winter in the northern hemisphere and
///      the beginning of summer in the southern hemisphere.
class SeasonInfo {
  AstroTime marEquinox;
  AstroTime junSolstice;
  AstroTime sepEquinox;
  AstroTime decSolstice;

  SeasonInfo(
    this.marEquinox,
    this.junSolstice,
    this.sepEquinox,
    this.decSolstice,
  );

  /// Finds the equinoxes and solstices for a given calendar year.
  ///
  /// @param {number | AstroTime} year
  ///      The integer value or `AstroTime` object that specifies
  ///      the UTC calendar year for which to find equinoxes and solstices.
  ///
  /// @returns {SeasonInfo}
  static SeasonInfo seasons(dynamic year) {
    AstroTime find(double targetLon, int month, int day) {
      final startDate = DateTime.utc(year, month, day);
      final time = searchSunLongitude(targetLon, startDate, 20);
      if (time == null) {
        throw Exception(
            "Cannot find season change near ${startDate.toIso8601String()}");
      }
      return time;
    }

    if (year is DateTime && year.isUtc) {
      year = year.year;
    }

    if (year is! int || year < -9007199254740991 || year > 9007199254740991) {
      throw Exception(
          "Cannot calculate seasons because year argument $year is neither a DateTime nor a safe integer.");
    }

    final marEquinox = find(0, 3, 10);
    final junSolstice = find(90, 6, 10);
    final sepEquinox = find(180, 9, 10);
    final decSolstice = find(270, 12, 10);

    return SeasonInfo(marEquinox, junSolstice, sepEquinox, decSolstice);
  }
}
