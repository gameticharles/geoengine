/*
    riseset.js  -  by Don Cross - 2019-06-15

    Example Node.js program for Astronomy Engine:
    https://github.com/cosinekitty/astronomy

    This program calculates the time of the next
    sunrise, sunset, moonrise, and moonset.

    To execute, run the command:
    node riseset latitude longitude [date]
*/

import 'package:geoengine/src/astro/astronomy.dart';

void displayEvent(String name, AstroTime? evt) {
  var text = evt != null ? evt.date.toString() : '';
  print('${name.padRight(8)} : $text');
}

void main() {
  final latitude = 6.56784;
  final longitude = -1.5674;
  final observer = Observer(latitude, longitude, 0);
  final date = DateTime.now().subtract(Duration(hours: 0)).toUtc();

  AstroTime? sunrise = searchRiseSet(Body.Sun, observer, 1, date, 300);
  AstroTime? sunset = searchRiseSet(Body.Sun, observer, -1, date, 300);
  AstroTime? moonrise = searchRiseSet(Body.Moon, observer, 1, date, 300);
  AstroTime? moonset = searchRiseSet(Body.Moon, observer, -1, date, 300);

  print('search   : ${date.toString()}');
  displayEvent('sunrise', sunrise);
  displayEvent('sunset', sunset);
  displayEvent('moonrise', moonrise);
  displayEvent('moonset', moonset);
}
