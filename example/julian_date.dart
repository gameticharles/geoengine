import 'package:geoengine/geoengine.dart';

void main() {
  // Example 1: Create a JulianDate from the current date and time
  final now = JulianDate.now();
  print('Current date and time: ${now.dateTime}');
  print('Current Julian Date: ${now.toJulianDate()}');
  print('Current Modified Julian Date: ${now.toModifiedJulianDate()}');
  print('');

  // Example 2: Create a JulianDate from a specific date and time
  final specificDate = JulianDate.fromDate(
    year: 2023,
    month: 10,
    day: 15,
    hour: 12,
    minute: 30,
    second: 45,
  );
  print('Specific date: ${specificDate.dateTime}');
  print('Julian Date: ${specificDate.toJulianDate()}');
  print('Modified Julian Date: ${specificDate.toModifiedJulianDate()}');
  print('');

  // Example 3: Convert from Julian Date to DateTime
  final jd = 2460232.5; // Julian Date for 2023-10-15 at noon
  final fromJD = JulianDate.fromJulianDate(jd);
  print('Date from Julian Date $jd: ${fromJD.dateTime}');
  print('');

  // Example 4: Using a custom reference date
  final customReference = DateTime.utc(2000, 1, 1);
  final dateWithCustomRef =
      JulianDate(DateTime.now(), referenceDate: customReference);
  print('Date with custom reference: ${dateWithCustomRef.dateTime}');
  print(
      'Modified Julian Date (custom reference): ${dateWithCustomRef.toModifiedJulianDate(referenceDate: customReference)}');
  print('');

  // Example 5: Date calculations and comparisons
  final date1 = JulianDate.fromDate(year: 2023, month: 10, day: 15);
  final date2 = JulianDate.fromDate(year: 2023, month: 10, day: 20);

  print('Date 1: ${date1.dateTime}');
  print('Date 2: ${date2.dateTime}');
  print('Difference in days: ${date2.differenceInDays(date1)}');
  print('Difference in hours: ${date2.differenceInHours(date1)}');
  print('Difference in minutes: ${date2.differenceInMinutes(date1)}');
  print('Difference in seconds: ${date2.differenceInSeconds(date1)}');
  print('');

  // Example 6: Date comparisons
  print('date1 == date2: ${date1 == date2}');
  print('date1 < date2: ${date1 < date2}');
  print('date1 <= date2: ${date1 <= date2}');
  print('date1 > date2: ${date1 > date2}');
  print('date1 >= date2: ${date1 >= date2}');
  print('');

  // Example 7: Astronomical applications
  final j2000 = JulianDate.fromDate(year: 2000, month: 1, day: 1, hour: 12);
  print('J2000 epoch: ${j2000.dateTime}');
  print('J2000 Julian Date: ${j2000.toJulianDate()}');

  // Calculate days since J2000 epoch
  final daysSinceJ2000 = now.differenceInDays(j2000);
  print('Days since J2000 epoch: $daysSinceJ2000');
  print('');

  // Example 8: Creating from reference date
  final referenceDate = DateTime.utc(1858, 11, 17);
  final targetDate = DateTime.utc(2023, 10, 15);
  final fromReference = JulianDate.fromReferenceDate(
    referenceDate: referenceDate,
    dateTime: targetDate,
  );
  print('Date from reference conversion: ${fromReference.dateTime}');
  print('MJD: ${fromReference.toModifiedJulianDate()}');
  print('');

  // Example 9: Leap year check
  final leapYearDate = JulianDate.fromDate(year: 2024, month: 2, day: 29);
  final nonLeapYearDate = JulianDate.fromDate(year: 2023, month: 2, day: 28);
  print('2024 is leap year: ${leapYearDate.isLeapYear()}');
  print('2023 is leap year: ${nonLeapYearDate.isLeapYear()}');

  print(DateTime.now());
  print(JulianDate.now().subtract(Duration(days: 1)));
  print(JulianDate.now().subtract(Duration(days: 1)));
}
