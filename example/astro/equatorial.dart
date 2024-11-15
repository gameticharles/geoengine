/*
    equatorial.dart  -  by Don Cross - 2021-03-27

    Example dart program for Astronomy Engine:
    https://github.com/cosinekitty/astronomy

    Given an observer's location on the Earth, a
    date/time, and horizontal coordinates (azimuth, altitude)
    for that observer, this program works backwards
    to figure out the equatorial coordinates for that
    location in the sky. It provides two solutions:
    one that includes atmospheric refraction, another
    that ignores atmospheric refraction.

    To execute, run the command:
    node equatorial latitude longitude azimuth altitude [date]
*/

import 'package:geoengine/src/astro/astronomy.dart';

import 'dart:io';

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

String format(double x, int length, int digits) {
  String s = x.toStringAsFixed(digits);
  while (s.length < length) {
    s = ' $s';
  }
  return s;
}

void solve(bool refract, Observer observer, AstroTime time, double azimuth,
    double altitude) {
  // Convert the angular horizontal coordinates (azimuth, altitude)
  // to a horizontal vector (north, west, zenith).
  final horSphere = Spherical(altitude, azimuth, 1);
  var refractionOption = refract ? 'normal' : null;

  final horVec =
      AstroVector.vectorFromHorizon(horSphere, time, refractionOption);
  print(horVec.x);
  print(horVec.y);
  print(horVec.z);
  print(horVec.time);

  // Make a rotation matrix for this observer and date/time that converts
  // horizontal coordinates (HOR) to equatorial coordinates in the J2000 epoch (EQJ).
  final rotHorEqj = RotationMatrix.rotationHORtoEQJ(time, observer);

  // Use the rotation matrix to convert the horizontal vector to an equatorial vector.
  final eqjVec = AstroVector.rotateVector(rotHorEqj, horVec);

  // Convert the equatorial vector to equatorial angular coordinates (RA, DEC).
  final eqj = EquatorialCoordinates.fromVector(eqjVec);

  // Self-check the answers by converting back to horizontal coordinates,
  // using a different algorithm that has been tested to work.

  // First we need to convert J2000 equatorial (EQJ) to equator-of-date (EQD),
  // because the Horizon function expects EQD.
  final rotEqjEqd = RotationMatrix.rotationEQJtoEQD(time);
  final eqdVec = AstroVector.rotateVector(rotEqjEqd, eqjVec);
  final eqd = EquatorialCoordinates.fromVector(eqdVec);

  final checkHor = HorizontalCoordinates.horizon(
      time, observer, eqd.ra, eqd.dec, refractionOption);
  final altError = (checkHor.altitude - altitude).abs();
  final azError = (checkHor.azimuth - azimuth).abs();

  var line = (refract ? '   yes' : '   no ');
  line += '    ${format(eqj.ra, 10, 4)}';
  line += ' ${format(eqj.dec, 10, 4)}';
  line += ' ${format(eqd.ra, 10, 4)}';
  line += ' ${format(eqd.dec, 10, 4)}';
  line += ' ${format(altError, 10, 6)}';
  line += ' ${format(azError, 10, 6)}';
  print(line);
}

void demo() {
  final arguments = Platform.environment['args']?.split(' ') ?? [];
  if (arguments.length == 6 || arguments.length == 7) {
    final latitude = parseNumber(arguments[2], 'latitude');
    final longitude = parseNumber(arguments[3], 'longitude');
    final observer = Observer(latitude, longitude, 0);
    final azimuth = parseNumber(arguments[4], 'azimuth');
    final altitude = parseNumber(arguments[5], 'altitude');
    final time = AstroTime(
        (arguments.length == 7) ? parseDate(arguments[6]) : DateTime.now());

    print(
        'Refract?    J2000_RA  J2000_DEC  OFDATE_RA OFDATE_DEC  ALT_error   AZ_error');

    solve(false, observer, time, azimuth, altitude);
    solve(true, observer, time, azimuth, altitude);

    exit(0);
  } else {
    print(
        'USAGE: dart equatorial.dart latitude longitude azimuth altitude [date]');
    exit(1);
  }
}

void main() {
  demo();
}
