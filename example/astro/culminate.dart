/*
    culminate.dart  -  by Don Cross - 2019-06-17

    Example dart program for Astronomy Engine:
    https://github.com/cosinekitty/astronomy

    This example program shows how to calculate the time
    the Sun, Moon, and planets will next reach their highest point in the sky
    as seen by an observer at a given location on the Earth.
    This is called culmination, and is found by finding when
    each body's "hour angle" is 0.

    Having an hour angle of 0 is another way of saying that the body is
    crossing the meridian, the imaginary semicircle in the sky that passes
    from due north on the horizon, through the zenith (straight up),
    toward due south on the horizon. At this moment the body appears to
    have an azimuth of either 180 degrees (due south) or 0 (due north).

    To execute, run the command:
    node culminate latitude longitude [date]
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

void displayEvent(String name, HourAngleEvent evt) {
  String text;
  if (evt != null) {
    DateTime dateTime = evt.time.date;
    double altitude = evt.hor.altitude;
    double azimuth = evt.hor.azimuth;

    text = dateTime.toIso8601String() +
        '  altitude=' +
        altitude.toStringAsFixed(2).padLeft(6) +
        '  azimuth=' +
        azimuth.toStringAsFixed(2).padLeft(7);
  } else {
    text = '(not found)';
  }
  print(name.padRight(8) + ' : ' + text);
}

void demo() {
  final arguments = Platform.executableArguments;
  print(arguments);
  if (arguments.length == 4 || arguments.length == 5) {
    final bodyList = [
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
    final latitude = parseNumber(arguments[2], 'latitude');
    final longitude = parseNumber(arguments[3], 'longitude');
    final observer = Observer(latitude, longitude, 0);
    final date =
        (arguments.length == 5) ? parseDate(arguments[4]) : DateTime.now();
    print('search   : ' + date.toIso8601String());

    for (var body in bodyList) {
      var culm = searchHourAngle(body, observer, 0,
          date); // Replace with actual method to search hour angle.
      displayEvent(body.toString().split('.').last, culm);
    }

    exit(0);
  } else {
    print('USAGE: dart culminate.dart latitude longitude [date]');
    exit(1);
  }
}

void demo1() {
  final bodyList = [
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
  final latitude = 6.56784;
  final longitude = -1.5674;
  final observer = Observer(latitude, longitude, 0);
  final date = DateTime.now();

  print('search   : ' + date.toIso8601String());

  for (var body in bodyList) {
    var culm = searchHourAngle(body, observer, 0,
        date); // Replace with actual method to search hour angle.
    displayEvent(body.toString().split('.').last, culm);
  }

  exit(0);
}

void main() {
  demo1();
}
