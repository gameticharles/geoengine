/*
    equator_of_date.dart  -  by Don Cross  -  2021-07-06

    Example dart program for Astronomy Engine:
    https://github.com/cosinekitty/astronomy
*/
import 'package:geoengine/src/astro/astronomy.dart';
import 'dart:io';

const usageText = """
USAGE:  dart equator_of_date.js [a|n] ra dec [yyyy-mm-ddThh:mm:ssZ]

Converts J2000 equatorial coordinates to
equator-of-date coordinates.

[a|n] = aberration correction / no aberration correction
ra  = J2000 Right ascension in sidereal hours (0 .. 24).
dec = J2000 Declination in degrees (-90 .. +90).
yyyy-mm-ddThh:mm:ssZ = Optional date and time in UTC.
(If omitted, the current date and time are used.)

This program prints out the right ascension and declination
of the same point in the sky, but expressed in the Earth's
equator at the given date and time.
""";

double parseNumber(String name, String text,
    {double? minValue, double? maxValue}) {
  final x = double.tryParse(text);
  if (x == null ||
      !(x.isFinite) ||
      (minValue != null && x < minValue) ||
      (maxValue != null && x > maxValue)) {
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

void main() {
  final arguments = Platform.environment['args']?.split(' ') ?? [];
  if (arguments.length < 5 || arguments.length > 6) {
    stderr.writeln('UsageText');
    exit(1);
  } else {
    // Parse the command line arguments.
    final correctAberration = (arguments[2] == 'a');
    final ra = parseNumber('RA', arguments[3], minValue: 0, maxValue: 24);
    final dec = parseNumber('DEC', arguments[4], minValue: -90, maxValue: 90);
    final date =
        (arguments.length > 5) ? parseDate(arguments[5]) : DateTime.now();
    final time = AstroTime(date);
    print('time = $time');

    // Create a rotation matrix that converts J2000 equatorial (EQJ)
    // orientation to equator-of-date (EQD) orientation.
    final rot = RotationMatrix.rotationEQJtoEQD(time);

    // Convert the spherical angular EQJ coordinates to vector.
    // Multiply ra by 15 to convert sidereal hours to degrees.
    // Scale the vector by the speed of light so that we can optionally
    // apply an aberration correction below.
    final eqjSphere = Spherical(dec, 15 * ra, C_AUDAY);
    var eqjVec = AstroVector.vectorFromSphere(eqjSphere, time);

    if (correctAberration) {
      // Use non-relativistic approximation: add barycentric Earth velocity vector
      // to the light ray vector. The direction of the light vector points toward the star,
      // which is opposite to the direction light actually travels.
      // The result is the aberration-corrected apparent position of the star in EQJ.
      final eqjEarth = baryState(Body.Earth, time);
      eqjVec.x += eqjEarth.vx;
      eqjVec.y += eqjEarth.vy;
      eqjVec.z += eqjEarth.vz;
    }

    // Use the rotation matrix to re-orient the EQJ vector to an EQD vector.
    final eqdVec = AstroVector.rotateVector(rot, eqjVec);

    // Convert the EQD vector back to spherical angular coordinates.
    final eqdSphere = Spherical.sphereFromVector(eqdVec);

    // Print out the converted angular coordinates.
    final eqdRA = eqdSphere.lon / 15; // convert degrees to sidereal hours
    final eqdDec = eqdSphere.lat;
    print(
        'Equator-of-date coordinates: RA=${eqdRA.toStringAsFixed(6)}, DEC=${eqdDec.toStringAsFixed(6)}');

    // Success!
    exit(0);
  }
}
