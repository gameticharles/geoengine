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
  var refractionOption =
      refract ? RefractionType.normal : RefractionType.airless;

  final horVec =
      AstroVector.vectorFromHorizon(horSphere, time, refractionOption);
  // print(horVec.x);
  // print(horVec.y);
  // print(horVec.z);
  // print(horVec.time);

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

void main() {
  final azimuth = 180.0;
  final altitude = 230.0;

  final latitude = 6.56784;
  final longitude = -1.5674;
  final observer = Observer(latitude, longitude, 230);
  final time = AstroTime(DateTime.now());

  print(
      'Refract?    J2000_RA  J2000_DEC  OFDATE_RA OFDATE_DEC  ALT_error   AZ_error');

  solve(false, observer, time, azimuth, altitude);
  solve(true, observer, time, azimuth, altitude);
}
