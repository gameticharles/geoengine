part of '../astronomy.dart';

/// @brief The date and time of an astronomical observation.
///
/// Objects of type `AstroTime` are used throughout the internals
/// of the Astronomy library, and are included in certain return objects.
/// Use the constructor or the {@link AstroTime} function to create an `AstroTime` object.
///
/// @property {Date} date
///      The dart Date object for the given date and time.
///      This Date corresponds to the numeric day value stored in the `ut` property.
///
/// @property {number} ut
///      Universal Time (UT1/UTC) in fractional days since the J2000 epoch.
///      Universal Time represents time measured with respect to the Earth's rotation,
///      tracking mean solar days.
///      The Astronomy library approximates UT1 and UTC as being the same thing.
///      This gives sufficient accuracy for the precision requirements of this project.
///
/// @property {number} tt
///      Terrestrial Time in fractional days since the J2000 epoch.
///      TT represents a continuously flowing ephemeris timescale independent of
///      any variations of the Earth's rotation, and is adjusted from UT
///      using a best-fit piecewise polynomial model devised by
///      [Espenak and Meeus](https://eclipse.gsfc.nasa.gov/SEhelp/deltatpoly2004.html).
class AstroTime {
  late DateTime date;
  late double ut;
  late double tt;

  /// @param {dynamic} date
  ///      A Dart Date object, a numeric UTC value expressed in J2000 days, or another AstroTime object.
  AstroTime(dynamic date) {
    if (date is AstroTime) {
      // Construct a clone of the AstroTime passed in.
      this.date = date.date;
      ut = date.ut;
      tt = date.tt;
      return;
    }

    final MillisPerDay = 1000 * 3600 * 24;

    if (date is DateTime) {
      this.date = date;
      ut = (date.millisecondsSinceEpoch - J2000.millisecondsSinceEpoch) /
          MillisPerDay;
      tt = terrestrialTime(ut);
      return;
    }

    if (date is num) {
      this.date = DateTime.fromMillisecondsSinceEpoch(
          J2000.millisecondsSinceEpoch + (date * MillisPerDay).round());
      ut = date.toDouble();
      tt = terrestrialTime(ut);
      return;
    }

    throw 'Argument must be a DateTime object, an AstroTime object, or a numeric UTC Julian date.';
  }

  /// @brief Creates an `AstroTime` value from a Terrestrial Time (TT) day value.
  ///
  /// This function can be used in rare cases where a time must be based
  /// on Terrestrial Time (TT) rather than Universal Time (UT).
  /// Most developers will want to invoke `new AstroTime(ut)` with a universal time
  /// instead of this function, because usually time is based on civil time adjusted
  /// by leap seconds to match the Earth's rotation, rather than the uniformly
  /// flowing TT used to calculate solar system dynamics. In rare cases
  /// where the caller already knows TT, this function is provided to create
  /// an `AstroTime` value that can be passed to Astronomy Engine functions.
  ///
  /// @param {number} tt
  ///      The number of days since the J2000 epoch as expressed in Terrestrial Time.
  ///
  /// @returns {AstroTime}
  ///      An `AstroTime` object for the specified terrestrial time.
  static AstroTime fromTerrestrialTime(double tt) {
    var time = AstroTime(tt);
    for (;;) {
      var err = tt - time.tt;
      if (err.abs() < 1.0e-12) return time;
      time = time.addDays(err);
    }
  }

  /// Formats an `AstroTime` object as an [ISO 8601](https://en.wikipedia.org/wiki/ISO_8601)
  /// date/time string in UTC, to millisecond resolution.
  /// Example: `2018-08-17T17:22:04.050Z`
  /// @returns {string}
  @override
  String toString() {
    return date.toUtc().toIso8601String();
  }

  /// Returns a new `AstroTime` object adjusted by the floating point number of days.
  /// Does NOT modify the original `AstroTime` object.
  ///
  /// @param {number} days
  ///      The floating point number of days by which to adjust the given date and time.
  ///      Positive values adjust the date toward the future, and
  ///      negative values adjust the date toward the past.
  ///
  /// @returns {AstroTime}
  AstroTime addDays(double days) {
    // This is slightly wrong, but the error is tiny.
    // We really should be adding to TT, not to UT.
    // But using TT would require creating an inverse function for DeltaT,
    // which would be quite a bit of extra calculation.
    // I estimate the error is in practice on the order of 10^(-7)
    // times the value of 'days'.
    // This is based on a typical drift of 1 second per year between UT and TT.
    return AstroTime(ut + days);
  }

  static AstroTime interpolateTime(
      AstroTime time1, AstroTime time2, double fraction) {
    return AstroTime(time1.ut + fraction * (time2.ut - time1.ut));
  }
}
