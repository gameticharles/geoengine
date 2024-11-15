/*
    positions.dart  -  by Don Cross - 2019-06-12

    Example dart program for Astronomy Engine:
    https://github.com/cosinekitty/astronomy

    This program calculates the equatorial and horizontal coordinates
    of the Sun, Moon, and planets, as seen by an observer at a specified
    location on the Earth.

    To execute, run the command:

        node positions.dart latitude longitude [date]

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

String format(double x) {
  return x.toStringAsFixed(2).padLeft(8);
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

double parseNumber(String text, String name) {
  final x = double.tryParse(text);
  if (x == null || x.isNaN) {
    stderr.writeln('ERROR: Not a valid numeric value for $name: "$text"');
    exit(1);
  }
  return x;
}

void demo() {
  var args = Platform.environment['args']?.split(' ') ?? [];

  if (args.length == 4 || args.length == 5) {
    var latitude = parseNumber(args[2], 'latitude');
    var longitude = parseNumber(args[3], 'longitude');
    var observer = Observer(latitude, longitude, 0);
    var date = (args.length == 5) ? parseDate(args[4]) : DateTime.now().toUtc();

    print('UTC date = ${date.toIso8601String()}');
    print('');
    print(
        '${'BODY'.padRight(8)} ${'RA'.padLeft(8)} ${'DEC'.padLeft(8)} ${'AZ'.padLeft(8)} ${'ALT'.padLeft(8)}');

    var bodies = [
      Body.Sun,
      Body.Moon,
      Body.Mercury,
      Body.Venus,
      Body.Mars,
      Body.Jupiter,
      Body.Saturn,
      Body.Uranus,
      Body.Neptune,
      Body.Pluto
    ];

    for (var body in bodies) {
      var equ2000 = equator(body, date, observer, false, true);
      var equOfDate = equator(body, date, observer, true, true);
      var hor = HorizontalCoordinates.horizon(
          date, observer, equOfDate.ra, equOfDate.dec, 'normal');

      print(
          '${body.toString().split('.').last.padRight(8)} ${format(equ2000.ra)} ${format(equ2000.dec)} ${format(hor.azimuth)} ${format(hor.altitude)}');
    }

    exit(0);
  } else {
    print('USAGE: dart run positions.dart latitude longitude [date]');
    exit(1);
  }
}

void demo1() {
  final latitude = 6.56784;
  final longitude = -1.5674;
  final observer = Observer(latitude, longitude, 0);
  final date = DateTime.now().toUtc();

  print('UTC date = ${date.toIso8601String()}');
  print('');
  print(
      '${'BODY'.padRight(8)} ${'RA'.padLeft(8)} ${'DEC'.padLeft(8)} ${'AZ'.padLeft(8)} ${'ALT'.padLeft(8)}');

  var bodies = [
    Body.Sun,
    Body.Moon,
    Body.Mercury,
    Body.Venus,
    Body.Mars,
    Body.Jupiter,
    Body.Saturn,
    Body.Uranus,
    Body.Neptune,
    Body.Pluto
  ];

  for (var body in bodies) {
    var equ2000 = equator(body, date, observer, false, true);
    var equOfDate = equator(body, date, observer, true, true);
    var hor = HorizontalCoordinates.horizon(
        date, observer, equOfDate.ra, equOfDate.dec, 'normal');

    print(
        '${body.toString().split('.').last.padRight(8)} ${format(equ2000.ra)} ${format(equ2000.dec)} ${format(hor.azimuth)} ${format(hor.altitude)}');
  }

  exit(0);
}

void main() {
  demo1();
}
