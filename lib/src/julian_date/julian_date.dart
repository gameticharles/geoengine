part of '../../geoengine.dart';

/// A utility class to handle conversions between Julian Dates and DateTime objects.
class JulianDate extends DateTime {
  late DateTime referenceDate;

  static const int hoursInDay = 24;
  static const int minutesInHour = 60;
  static const int secondsInMinute = 60;
  static const int millisecondsInSecond = 1000;
  static const int microsecondsInMillisecond = 1000;

  // Common astronomical epochs
  static final DateTime j2000Epoch = DateTime.utc(2000, 1, 1, 12);
  static final DateTime b1950Epoch = DateTime.utc(1949, 12, 31, 22, 9, 0);
  static final DateTime j1900Epoch = DateTime.utc(1899, 12, 31, 12);
  
  // Standard reference date for MJD
  static final DateTime mjdReferenceDate = DateTime.utc(1858, 11, 17, 0, 0, 0);

  /// Returns a DateTime representation of the JulianDate.
  DateTime get dateTime => DateTime(
      year, month, day, hour, minute, second, millisecond, microsecond);

  /// Creates a JulianDate instance from a DateTime object.
  /// Optionally accepts a [referenceDate] for conversion calculations.
  JulianDate(DateTime dateTime, {DateTime? referenceDate})
      : referenceDate = referenceDate ?? DateTime.utc(1858, 11, 17, 0, 0, 0),
        super(
          dateTime.year,
          dateTime.month,
          dateTime.day,
          dateTime.hour,
          dateTime.minute,
          dateTime.second,
          dateTime.millisecond,
          dateTime.microsecond,
        ) {
    _validateDateTimeValues();
  }

  /// Creates a JulianDate instance from individual date and time components.
  /// Optionally accepts a [referenceDate] for conversion calculations.
  JulianDate.fromDate({
    required int year,
    required int month,
    required int day,
    int hour = 0,
    int minute = 0,
    int second = 0,
    int millisecond = 0,
    int microsecond = 0,
    DateTime? referenceDate,
  })  : referenceDate = referenceDate ?? DateTime.utc(1858, 11, 17, 0, 0, 0),
        super(
          year,
          month,
          day,
          hour,
          minute,
          second,
          millisecond,
          microsecond,
        ) {
    _validateDateTimeValues();
  }

  /// Constructs a [JulianDate] instance with current date and time in the local time zone.
  factory JulianDate.now() {
    return JulianDate(DateTime.now());
  }

  /// Constructs a [JulianDate] instance with current date and time in UTC.
  factory JulianDate.nowUtc() {
    return JulianDate(DateTime.now().toUtc());
  }

  /// Creates a JulianDate instance from a Julian Date value relative to J2000 epoch.
  factory JulianDate.fromJ2000(double daysSinceJ2000) {
    double j2000JD = JulianDate(j2000Epoch).toJulianDate();
    return JulianDate.fromJulianDate(j2000JD + daysSinceJ2000);
  }

  /// Creates a JulianDate instance from a Julian Date value relative to B1950 epoch.
  factory JulianDate.fromB1950(double daysSinceB1950) {
    double b1950JD = JulianDate(b1950Epoch).toJulianDate();
    return JulianDate.fromJulianDate(b1950JD + daysSinceB1950);
  }

  /// Creates a JulianDate instance by converting from a reference date and DateTime.
  factory JulianDate.fromReferenceDate(
      {required referenceDate, required DateTime dateTime}) {
    double jdReference = JulianDate(referenceDate).toJulianDate();
    double jd = JulianDate(dateTime).toJulianDate();
    double jdDifference = jd - jdReference;

    JulianDate convertedDate =
        JulianDate.fromJulianDate(jdReference + jdDifference);

    return JulianDate(convertedDate, referenceDate: referenceDate);
  }

  /// Creates a JulianDate instance by converting from a Julian Date value.
  /// Optionally accepts a [referenceDate] for the calculation.
  factory JulianDate.fromJulianDate(double jd, {DateTime? referenceDate}) {
    jd += 0.5;

    // Add the reference date
    jd += referenceDate != null ? JulianDate(referenceDate).toJulianDate() : 0;

    int intJd = jd.toInt();
    double fracJd = jd - intJd;

    int l = intJd + 68569;
    int n = (4 * l) ~/ 146097;
    l -= (146097 * n + 3) ~/ 4;
    int i = (4000 * (l + 1)) ~/ 1461001;
    l -= (1461 * i) ~/ 4 - 31;
    int j = (80 * l) ~/ 2447;
    int day = l - (2447 * j) ~/ 80;
    l = j ~/ 11;
    int month = j + 2 - (12 * l);
    int year = 100 * (n - 49) + i + l;

    var hour = (fracJd * hoursInDay).toInt();
    fracJd = fracJd * hoursInDay - hour;
    var minute = (fracJd * minutesInHour).toInt();
    fracJd = fracJd * minutesInHour - minute;
    var second = (fracJd * secondsInMinute).toInt();
    fracJd = fracJd * secondsInMinute - second;
    var millisecond = (fracJd * millisecondsInSecond).toInt();
    fracJd = fracJd * millisecondsInSecond - millisecond;
    var microsecond = (fracJd * microsecondsInMillisecond).toInt();

    return JulianDate.fromDate(
        year: year,
        month: month,
        day: day,
        hour: hour,
        minute: minute,
        second: second,
        millisecond: millisecond,
        microsecond: microsecond);
  }

  /// Converts the Julian Date to Modified Julian Date (MJD).
  ///
  /// The start of Modified Julian days (MJD) is defined as midnight of November, 17th, 1858
  /// but can be modified with the reference date
  ///
  /// Optionally accepts a [referenceDate] for the calculation.
  double toModifiedJulianDate({DateTime? referenceDate}) {
    double jdReference =
        JulianDate(referenceDate ?? this.referenceDate).toJulianDate();
    double jd = toJulianDate();
    return jd == 2400000.5 ? jd : jd - jdReference;
  }

  /// Converts the Julian Date to a numerical Julian Date value.
  double toJulianDate() {
    int a = (14 - month) ~/ 12;
    int y = year + 4800 - a;
    int m = month + 12 * a - 3;

    double jd = day +
        ((153 * m + 2) ~/ 5) +
        365 * y +
        (y ~/ 4) -
        (y ~/ 100) +
        (y ~/ 400) -
        32045;

    // Add fractional part of the day
    jd += ((hour +
            minute / minutesInHour +
            second / secondsInMinute +
            millisecond / millisecondsInSecond +
            microsecond / microsecondsInMillisecond) /
        hoursInDay);

    return jd - 0.5;
  }

  /// Converts the Julian Date to days since J2000 epoch.
  double toDaysSinceJ2000() {
    double j2000JD = JulianDate(j2000Epoch).toJulianDate();
    return toJulianDate() - j2000JD;
  }

  /// Converts the Julian Date to days since B1950 epoch.
  double toDaysSinceB1950() {
    double b1950JD = JulianDate(b1950Epoch).toJulianDate();
    return toJulianDate() - b1950JD;
  }

  /// Converts the Julian Date to Terrestrial Time (TT).
  /// TT is approximately 32.184 seconds ahead of International Atomic Time (TAI).
  /// TAI is approximately 37 seconds ahead of UTC (as of 2023).
  JulianDate toTerrestrialTime() {
    // Approximate conversion - in a real implementation, you'd need a more accurate
    // leap second table and conversion algorithm
    const double ttMinusUtcSeconds = 69.184; // 32.184 + 37 (as of 2023)
    return add(Duration(milliseconds: (ttMinusUtcSeconds * 1000).round()));
  }

  /// Returns the weekday (0 for Sunday, 1 for Monday, etc.) of the JulianDate.
  int get julianWeekday {
    return ((toJulianDate() + 1.5).toInt() % 7);
  }

  /// Adds the specified duration to this JulianDate and returns a new JulianDate.
  @override
  JulianDate add(Duration duration) {
    DateTime newDateTime = dateTime.add(duration);
    return JulianDate(newDateTime, referenceDate: referenceDate);
  }

  /// Subtracts the specified duration from this JulianDate and returns a new JulianDate.
  @override
  JulianDate subtract(Duration duration) {
    DateTime newDateTime = dateTime.subtract(duration);
    return JulianDate(newDateTime, referenceDate: referenceDate);
  }

  /// Adds the specified number of days to this JulianDate and returns a new JulianDate.
  JulianDate addDays(double days) {
    double newJD = toJulianDate() + days;
    return JulianDate.fromJulianDate(newJD, referenceDate: referenceDate);
  }

  /// Formats the Julian Date as a string in standard astronomical notation.
  /// Format: JD XXXXXXX.XXXXX
  String formatJD({int decimals = 5}) {
    return 'JD ${toJulianDate().toStringAsFixed(decimals)}';
  }

  /// Formats the Modified Julian Date as a string.
  /// Format: MJD XXXXX.XXXXX
  String formatMJD({int decimals = 5}) {
    return 'MJD ${toModifiedJulianDate().toStringAsFixed(decimals)}';
  }

  /// Converts this JulianDate to UTC if it's in local time.
  JulianDate toUtc() {
    if (isUtc) return this;
    return JulianDate(dateTime.toUtc(), referenceDate: referenceDate);
  }

  /// Converts this JulianDate to local time if it's in UTC.
  JulianDate toLocal() {
    if (!isUtc) return this;
    return JulianDate(dateTime.toLocal(), referenceDate: referenceDate);
  }

  /// Validates the correctness of the month and day values
  void _validateDateTimeValues() {
    if (month < 1 || month > 12) {
      throw ArgumentError('Month must be between 1 and 12.');
    }

    if (day < 1 || day > _daysInMonth(year, month)) {
      throw ArgumentError('Day is out of range for the given month and year.');
    }
  }

  /// Returns the number of days in the specified month and year.
  int _daysInMonth(int year, int month) {
    if (month == 2) {
      return isLeapYear() ? 29 : 28;
    }
    const daysInMonth = [0, 31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];
    return daysInMonth[month];
  }

  /// Checks if the year is a leap year.
  bool isLeapYear() {
    return (year % 4 == 0) && ((year % 100 != 0) || (year % 400 == 0));
  }

  // Calculates the difference between two JulianDates in days.
  int differenceInDays(JulianDate other) {
    return (toJulianDate() - other.toJulianDate()).toInt();
  }

  // Calculates the difference between two JulianDates in hours.
  double differenceInHours(JulianDate other) {
    return (toJulianDate() - other.toJulianDate()) * hoursInDay;
  }

  // Calculates the difference between two JulianDates in minutes.
  double differenceInMinutes(JulianDate other) {
    return (toJulianDate() - other.toJulianDate()) * hoursInDay * minutesInHour;
  }

  // Calculates the difference between two JulianDates in seconds.
  double differenceInSeconds(JulianDate other) {
    return (toJulianDate() - other.toJulianDate()) *
        hoursInDay *
        minutesInHour *
        secondsInMinute;
  }

  // // Returns the weekday (0 for Sunday, 1 for Monday, etc.) of the JulianDate.
  // int get weekday {
  //   return (toJulianDate() + 1.5).toInt() % 7;
  // }

  // Implement the equality operator (==).
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is! JulianDate) return false;
    return toJulianDate() == other.toJulianDate();
  }

  // Implement the less than operator (<).
  bool operator <(JulianDate other) {
    return toJulianDate() < other.toJulianDate();
  }

  // Implement the less than or equal operator (<=).
  bool operator <=(JulianDate other) {
    return toJulianDate() <= other.toJulianDate();
  }

  // Implement the greater than operator (>).
  bool operator >(JulianDate other) {
    return toJulianDate() > other.toJulianDate();
  }

  // Implement the greater than or equal operator (>=).
  bool operator >=(JulianDate other) {
    return toJulianDate() >= other.toJulianDate();
  }

  @override
  int get hashCode {
    return DateTime(
      year,
      month,
      day,
      hour,
      minute,
      second,
      millisecond,
      microsecond,
    ).hashCode;
  }
}
