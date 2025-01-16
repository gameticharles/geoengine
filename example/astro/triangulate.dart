/*
    triangulate.js  -  by Don Cross - 2021-06-22

    Example Node.js program for Astronomy Engine:
    https://github.com/cosinekitty/astronomy
*/
import 'package:geoengine/src/astro/astronomy.dart';

import 'dart:io';

const usageText = """
USAGE:  node triangulate.js  lat1 lon1 elv1 az1 alt1  lat2 lon2 elv2 az2 alt2

Calculate the best-fit location of a point as observed
from two different locations on or near the Earth's surface.

lat1, lat2 = Geographic latitudes in degrees north of the equator.
lon1, lon2 = Geographic longitudes in degrees east of the prime meridian.
elv1, elv2 = Elevations above sea level in meters.
az1,  az2  = Azimuths toward observed object in degrees clockwise from north.
alt1, alt2 = Altitude angles toward observed object in degrees above horizon.

This program extrapolates lines in the given directions from the two
geographic locations and finds the location in space where they
come closest to intersecting. It then prints out the coordinates
of that triangulation point, along with the error radius in meters.
""";

double parseNumber(String text, String name) {
  final x = double.tryParse(text);
  if (x == null || x.isNaN) {
    stderr.writeln('ERROR: Not a valid numeric value for $name: "$text"');
    exit(1);
  }
  return x;
}

double dotProduct(AstroVector a, AstroVector b) {
  return a.x * b.x + a.y * b.y + a.z * b.z;
}

AstroVector addScale(double sa, AstroVector va, double sb, AstroVector vb) {
  return AstroVector(sa * va.x + sb * vb.x, sa * va.y + sb * vb.y,
      sa * va.z + sb * vb.z, va.time);
}

AstroVector directionVector(
    dynamic time, Observer observer, double altitude, double azimuth) {
  // Convert horizontal angles to a horizontal unit vector.
  final hor = Spherical(altitude, azimuth, 1.0);
  final hvec = AstroVector.vectorFromHorizon(hor, time, RefractionType.airless);

  // Find the rotation matrix that converts horizontal vectors to equatorial vectors.
  final rot = RotationMatrix.rotationHORtoEQD(time, observer);

  // Rotate the horizontal (HOR) vector to an equator-of-date (EQD) vector.
  final evec = AstroVector.rotateVector(rot, hvec);

  return evec;
}

void intersect(
    AstroVector pos1, AstroVector dir1, AstroVector pos2, AstroVector dir2) {
  final F = dotProduct(dir1, dir2);
  final amb = addScale(1, pos1, -1, pos2); // amb = pos1 - pos2
  final E = dotProduct(dir1, amb);
  final G = dotProduct(dir2, amb);
  final denom = 1 - F * F;

  if (denom == 0.0) {
    print('ERROR: Cannot solve because directions are parallel.');
    return;
  }

  final u = (F * G - E) / denom;
  final v = G + F * u;

  if (u < 0.0 || v < 0.0) {
    print('ERROR: Lines of sight do not converge.');
    return;
  }

  final a = addScale(1, pos1, u, dir1); // a = pos1 + u*dir1
  final b = addScale(1, pos2, v, dir2); // b = pos2 + v*dir2
  final c = addScale(0.5, a, 0.5, b); // c = (a+b)/2
  final miss = addScale(1, a, -1, b); // miss = a-b

  final dist = (KM_PER_AU * 1000 / 2) * miss.length(); // error radius in meters
  final obs = Observer.vectorObserver(c, true);

  print(
      'Solution: lat = ${obs.latitude.toStringAsFixed(6)}, lon = ${obs.longitude.toStringAsFixed(6)}, elv = ${obs.height.toStringAsFixed(3)} meters; error = ${dist.toStringAsFixed(3)} meters');
}

void main() {
  final arguments = Platform.environment['args']?.split(' ') ?? [];

  if (arguments.length == 12) {
    // Validate and parse command line arguments.
    var lat1 = parseNumber(arguments[2], "lat1");
    var lon1 = parseNumber(arguments[3], "lon1");
    var elv1 = parseNumber(arguments[4], "elv1");
    var az1 = parseNumber(arguments[5], "az1");
    var alt1 = parseNumber(arguments[6], "alt1");
    var lat2 = parseNumber(arguments[7], "lat2");
    var lon2 = parseNumber(arguments[8], "lon2");
    var elv2 = parseNumber(arguments[9], "elv2");
    var az2 = parseNumber(arguments[10], "az2");
    var alt2 = parseNumber(arguments[11], "alt2");

    var obs1 = Observer(lat1, lon1, elv1);
    var obs2 = Observer(lat2, lon2, elv2);

    // Use an arbitrary but consistent time for the Earth's rotation.
    var time = AstroTime(0.0);

    // Convert geographic coordinates of the observers to vectors.
    var pos1 = Observer.observerVector(time, obs1, true);
    var pos2 = Observer.observerVector(time, obs2, true);

    // Convert horizontal coordinates into unit direction vectors.
    var dir1 = directionVector(time, obs1, alt1, az1);
    var dir2 = directionVector(time, obs2, alt2, az2);

    // Find the closest point between the skew lines.
    intersect(pos1, dir1, pos2, dir2);
    exit(0);
  } else {
    print(
        'Usage: dart demo.dart lat1 lon1 elv1 az1 alt1 lat2 lon2 elv2 az2 alt2');
    exit(1);
  }
}
