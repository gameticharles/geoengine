/*
    lunar_eclipse.dart  -  by Don Cross - 2020-05-17

    Example dart program for Astronomy Engine:
    https://github.com/cosinekitty/astronomy

    Searches for the next 10 partial/total lunar eclipses after
    the current date, or a date specified on the command line.

    To execute, run the command:
    node lunar_eclipse [date]
*/

import 'package:advance_math/advance_math.dart';
import 'package:geoengine/src/astro/astronomy.dart';

void main(List<String> args) {
  var date = DateTime.now();
  final latitude = 6.56784;
  final longitude = -1.5674;

  final observer = Observer(latitude, longitude, 230);
  List<EclipseInfo> eclipses = Eclipse.search(startTime: date, eclipses: Eclipses.all);

  for (var eclipse in eclipses) {
    print(eclipse);
    printLine();
  }
}
