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
import 'dart:io';

String f(int x, int n) {
  String s = x.toString();
  while (s.length < n) {
    s = '0' + s;
  }
  return s;
}

double parseNumber(String text, String name) {
  final x = double.tryParse(text);
  if (x == null || x.isNaN) {
    stderr.writeln('ERROR: Not a valid numeric value for $name: "$text"');
    exit(1);
  }
  return x;
}

DateTime parseDate(String text) {
  try {
    final d = DateTime.parse(text);
    return d;
  } catch (e) {
    stderr.writeln('ERROR: Not a valid date: "$text"');
    exit(1);
  }
}




void Demo() {
    final latitude = 6.56784;
    final longitude = -1.5674;
    final observer = Observer(latitude, longitude, 0);
    final date = DateTime.now().toUtc();

    var _hourAngle = hourAngle(Body.Sun, date, observer);
    var solarTimeHours = (_hourAngle + 12) % 24;

    var milli = (solarTimeHours * 3.6e+6).round();
    var second = milli ~/ 1000;
    milli %= 1000;
    var minute = second ~/ 60;
    second %= 60;
    var hour = minute ~/ 60;
    minute %= 60;
    hour %= 24;

    print('True solar time = ${solarTimeHours.toStringAsFixed(4)} hours (${f(hour, 2)}:${f(minute, 2)}:${f(second, 2)}.${f(milli, 3)})');

}


void main(){
  Demo();
}
