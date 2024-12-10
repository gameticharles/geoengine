/*
    dart -  by Don Cross  -  2021-07-19

    Example Node.js program for Astronomy Engine:
    https://github.com/cosinekitty/astronomy
*/

import 'package:geoengine/src/astro/astronomy.dart';

const String usageText = '''
    USAGE:

    dart gravity.dart latitude height

    Calculates the gravitational acceleration experienced
    by an observer on the surface of the Earth at the specified
    latitude (degrees north of the equator) and height
    (meters above sea level).
    The output is the gravitational acceleration in m/s².
''';

String format(double x, int length, int digits) {
  String s = x.toStringAsFixed(digits);
  while (s.length < length) {
    s = ' $s';
  }
  return s;
}

void main(List<String> args) {
  final latitude = 6.56784;
  // final longitude = -1.5674;
  final height = 230.0;
  final gravity = observerGravity(latitude, 230);
  print(
      'latitude = ${format(latitude, 8, 4)},  height = ${format(height, 6, 0)},  gravity = ${format(gravity, 8, 6)}');
}
