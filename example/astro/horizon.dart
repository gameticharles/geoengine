/*
    horizon.js  -  Don Cross  -  2019-12-14

    Example Node.js program for Astronomy Engine:
    https://github.com/cosinekitty/astronomy

    This is a more advanced example. It shows how to use coordinate
    transforms and a binary search to find the two azimuths where the
    ecliptic intersects with an observer's horizon at a given date and time.

    node horizon.js latitude longitude [date]
*/
import 'dart:io';
import 'package:geoengine/src/astro/astronomy.dart';

final NUM_SAMPLES = 4;

double eclipLon(int i) {
  return (360 * i) / NUM_SAMPLES;
}

Spherical horizontalCoords(
    double eclipticLongitude, AstroTime time, RotationMatrix rotEclHor) {
  final eclip = Spherical(
      0.0, eclipticLongitude, 1.0); // Assuming the third parameter is distance.

  final eclVec = AstroVector.vectorFromSphere(eclip, time);
  final horVec = AstroVector.rotateVector(rotEclHor, eclVec);
  var g = Spherical.fromVector(horVec, 'normal');

  return Spherical.fromVector(horVec, 'normal');
}

Map<String, dynamic> _search(
    AstroTime time, RotationMatrix rotEclHor, double e1, double e2) {
  const tolerance = 1.0e-6; // One-millionth of a degree tolerance

  while (true) {
    final e3 = (e1 + e2) / 2.0;
    final h3 = horizontalCoords(e3, time, rotEclHor);

    if ((e2 - e1).abs() < tolerance) {
      // Found the horizon crossing within tolerable limits
      return {"ex": e3, "h": h3};
    }

    if (h3.lat < 0.0) {
      e1 = e3;
    } else {
      e2 = e3;
    }
  }
}

void findEclipticCrossings(Observer observer, AstroTime time) {
  // Calculate rotation matrix from J2000 ecliptic to horizontal coordinates
  final rot = RotationMatrix.rotationECLtoHOR(time, observer);

  // Sample several points around the ecliptic and store horizontal coordinates
  List<Spherical> hor = [];
  for (var i = 0; i < NUM_SAMPLES; ++i) {
    hor.add(horizontalCoords(eclipLon(i), time, rot));
  }

  // Check for crossings where horizontal altitude ascends through zero
  for (var i = 0; i < NUM_SAMPLES; ++i) {
    var f = hor[i];

    final a1 = hor[i].lat;

    final a2 = hor[(i + 1) % NUM_SAMPLES].lat;
    final e1 = eclipLon(i);
    final e2 = eclipLon(i + 1);

    if (a1 * a2 <= 0) {
      Map<String, dynamic> s;
      if (a2 > a1) {
        s = _search(time, rot, e1, e2);
      } else {
        s = _search(time, rot, e2, e1);
        print(s);
      }

      String direction =
          (s["h"]!.lon > 0 && s["h"]!.lon < 180) ? 'ascends' : 'descends';

      print(
          'Ecliptic longitude ${s["ex"]!.toStringAsFixed(4)} $direction through horizon at azimuth ${s["h"]!.lon.toStringAsFixed(4)}');

      if ((s["h"]!.lat.abs()) > 5.0e-7) {
        stderr.writeln(
            'FindEclipticCrossing: excessive altitude = ${s["h"]!.lat}');
        exit(1);
      }
    }
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

DateTime parseDate(String text) {
  try {
    final d = DateTime.parse(text);
    return d;
  } catch (e) {
    stderr.writeln('ERROR: Not a valid date: "$text"');
    exit(1);
  }
}

void demo() {
  final args = Platform.environment['args']?.split(' ') ?? [];
  if (args.length == 4 || args.length == 5) {
    final latitude = parseNumber(args[2], '');
    final longitude = parseNumber(args[3], '');
    final observer = Observer(latitude, longitude, 0.0);

    final time = (args.length == 5)
        ? AstroTime(parseDate(args[4]))
        : AstroTime(DateTime.now());

    findEclipticCrossings(observer, time);
    exit(0);
  } else {
    print('USAGE: dart horizon.dart latitude longitude [date]');
    exit(1);
  }
}

void main() {
  demo();
}