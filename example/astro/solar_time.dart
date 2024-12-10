/*
    solar_time.dart  -  by Don Cross - 2023-02-12

    Example dart program for Astronomy Engine:
    https://github.com/cosinekitty/astronomy

    This program calculates the true solar time for
    a given observer and UTC time.

    To execute, run the command:

        node solar_time.dart latitude longitude [date]

    where

        latitude = geographic latitude of the observer (-90 to +90).
        longitude = geographic longitude of the observer (-180 to +180).
        date = optional date and time string.

    If date is omitted, this program uses the computer's current date and time.
    If date is present, date is any string that Node.js can parse as a date and time,
    for example the ISO 8601 UTC format "yyyy-mm-ddThh:mm:ssZ".
*/

import 'package:geoengine/src/astro/astronomy.dart';

void main() {
  final latitude = 6.56784;
  final longitude = -1.5674;

  final observer = Observer(latitude, longitude, 0);
  final date = DateTime.now().toUtc();
  print(date);
  print(trueSolarTime(observer, date));
}
