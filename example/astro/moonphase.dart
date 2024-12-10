/*
    moonphase.dart  -  by Don Cross - 2019-05-13

    Example dart program for Astronomy Engine:
    https://github.com/cosinekitty/astronomy

    This program calculates the Moon's phase for a given date and time,
    or for the computer's current date and time if none is given.
    It also finds the dates and times of the subsequent 10 quarter phase changes.

    To execute, run the command:
    node moonphase [date]
*/

import 'package:geoengine/src/astro/astronomy.dart';
import 'dart:io';

String pad(num number, int width) {
  String s = number.toStringAsFixed(0);
  while (s.length < width) {
    s = '0$s';
  }
  return s;
}

String formatDate(DateTime t) {
  var date = t;
  var year = pad(date.year, 4);
  var month = pad(date.month, 2);
  var day = pad(date.day, 2);
  var hour = pad(date.hour, 2);
  var minute = pad(date.minute, 2);
  var second = pad(date.second, 2);
  var millisecond = pad(date.millisecond, 3);
  return '$year-$month-$day $hour:$minute:$second.$millisecond UTC';
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
  var date = DateTime.now();

  // Calculate the Moon's ecliptic phase angle,
  // which ranges from 0 to 360 degrees.
  //   0 degrees = new moon,
  //  90 degrees = first quarter,
  // 180 degrees = full moon,
  // 270 degrees = third quarter.
  final phase = moonPhase(date);
  print(
      '${formatDate(AstroTime(date).date)} : Moon\'s ecliptic phase angle = ${phase.toStringAsFixed(3)} degrees.');

  // Calculate the fraction of the Moon's disc
  // that appears illuminated, as seen from the Earth.
  final illum = IlluminationInfo.getBodyIllumination(Body.Moon, date);

  print(
      '${formatDate(AstroTime(date).date)} : Moon\'s illuminated fraction = ${(illum.phaseFraction * 100).toStringAsFixed(2)}%.');
  print('');

  // Predict when the next 10 lunar quarter phases will happen.
  print('The next 10 lunar quarters are:');

  MoonQuarter mq = MoonQuarter(1, AstroTime(date));
  for (var i = 0; i < 10; ++i) {
    // Use the previous moon quarter information to find the next quarter phase event.
    mq = MoonQuarter.nextMoonQuarter(mq);
    print('${formatDate(mq.time.date)} : ${mq.quarter}');
  }
}

