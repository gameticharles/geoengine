/*
    seasons.dart  -  by Don Cross - 2019-06-16

    Example dart program for Astronomy Engine:
    https://github.com/cosinekitty/astronomy

    This program calculates the time of the next
    sunrise, sunset, moonrise, and moonset.

    To execute, run the command:
    dart riseset latitude longitude [date]
*/
import 'package:geoengine/src/astro/astronomy.dart';
import 'dart:io';

void displayEvent(String name, AstroTime? evt) {
  var text = evt != null ? evt.date.toIso8601String() : '';
  print('${name.padRight(17)} : $text');
}

bool isSafeInteger(int? value) {
  const int minSafeInteger = -9007199254740991; // -(2^53 - 1)
  const int maxSafeInteger = 9007199254740991; // 2^53 - 1

  // Check if the value is within the safe integer range
  if (value != null) {
    return value >= minSafeInteger && value <= maxSafeInteger;
  }
  return false;
}

void main() {
  var year = 2024;

  if (!isSafeInteger(year)) {
    print('ERROR: Not a valid year: "$year"');
    exit(1);
  }

  var seasons = SeasonInfo.seasons(year);
  displayEvent('March equinox', seasons.marEquinox);
  displayEvent('June solstice', seasons.junSolstice);
  displayEvent('September equinox', seasons.sepEquinox);
  displayEvent('December solstice', seasons.decSolstice);
}
