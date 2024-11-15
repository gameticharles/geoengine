/*
    lunar_eclipse.dart  -  by Don Cross - 2020-05-17

    Example dart program for Astronomy Engine:
    https://github.com/cosinekitty/astronomy

    Searches for the next 10 partial/total lunar eclipses after
    the current date, or a date specified on the command line.

    To execute, run the command:
    node lunar_eclipse [date]
*/

import 'package:geoengine/src/astro/astronomy.dart';
import 'dart:io';
String pad(num number, int width) {
  String s = number.toStringAsFixed(0);
  while (s.length < width) {
    s = '0' + s;
  }
  return s;
}

String formatDate(AstroTime t) {
  var date = t.date;
  var year = pad(date.year, 4);
  var month = pad(date.month, 2);
  var day = pad(date.day, 2);
  var hour = pad(date.hour, 2);
  var minute = pad(date.minute, 2);
  var second = pad(date.second, 2);
  var millisecond = pad(date.millisecond, 3);
  return '$year-$month-$day $hour:$minute:$second.$millisecond UTC';
}


void printEclipse(LunarEclipseInfo e) {
  // Calculate beginning/ending of different phases
  // of an eclipse by subtracting/adding the peak time
  // with the number of minutes indicated by the "semi-duration"
  // fields sd_partial and sd_total.
  const MINUTES_PER_DAY = 24 * 60;

  var p1 = e.peak.addDays(-e.sdPartial / MINUTES_PER_DAY);
  print('${formatDate(p1)} - Partial eclipse begins.');

  if (e.sdTotal > 0) {
    var t1 = e.peak.addDays(-e.sdTotal / MINUTES_PER_DAY);
    print('${formatDate(t1)} - Total eclipse begins.');
  }

  print('${formatDate(e.peak)} - Peak of ${e.kind} eclipse.');

  if (e.sdTotal > 0) {
    var t2 = e.peak.addDays(e.sdTotal / MINUTES_PER_DAY);
    print('${formatDate(t2)} - Total eclipse ends.');
  }

  var p2 = e.peak.addDays(e.sdPartial / MINUTES_PER_DAY);
  print('${formatDate(p2)} - Partial eclipse ends.');
  print('');
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
  var args = Platform.environment['args']?.split(' ') ?? [];

  var date = (args.length == 3) ? parseDate(args[2]) : DateTime.now();
  var count = 0;
  var eclipse = searchLunarEclipse(date);

  for (;;) {
    if (eclipse.kind != EclipseKind.Penumbral) {
      printEclipse(eclipse);
      if (++count == 10) {
        break;
      }
    }
    eclipse = nextLunarEclipse(eclipse.peak);
  }

  exit(0);
}


void main(){
    demo();
}