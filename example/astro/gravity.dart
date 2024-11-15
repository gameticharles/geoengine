/*
    dart -  by Don Cross  -  2021-07-19

    Example Node.js program for Astronomy Engine:
    https://github.com/cosinekitty/astronomy
*/

import 'package:geoengine/src/astro/astronomy.dart';
import 'dart:io';

const String usageText = '''
    USAGE:

    dart gravity.dart latitude height

    Calculates the gravitational acceleration experienced
    by an observer on the surface of the Earth at the specified
    latitude (degrees north of the equator) and height
    (meters above sea level).
    The output is the gravitational acceleration in m/s².
''';

double parseNumber(String name, String text, double minValue, double maxValue) {
  final x = double.tryParse(text);
  if (x == null || x.isNaN || x < minValue || x > maxValue) {
    stderr.writeln('ERROR: Not a valid numeric value for $name: "$text".');
    stderr.writeln('Must be in the range $minValue .. $maxValue.');
    exit(1);
  }
  return x;
}

String format(double x, int length, int digits) {
  String s = x.toStringAsFixed(digits);
  while (s.length < length) {
    s = ' ' + s;
  }
  return s;
}

void demo() {
  final arguments = Platform.environment['args']?.split(' ') ?? [];
  if (arguments.length != 4) {
    print(usageText);
    exit(1);
  } else {
    final latitude = parseNumber('latitude', arguments[2], -90, 90);
    final height = parseNumber('height', arguments[3], 0, 100000);
    final gravity = observerGravity(latitude, height);
    print(
        'latitude = ${format(latitude, 8, 4)},  height = ${format(height, 6, 0)},  gravity = ${format(gravity, 8, 6)}');
    exit(0);
  }
}

void main(List<String> args) {
  demo();
}
