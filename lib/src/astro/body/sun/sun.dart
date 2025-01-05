part of '../../astronomy.dart';

class Sun {
  late AstroTime date;

  Sun([dynamic date]) {
    this.date = AstroTime(date ?? DateTime.now());
  }

  /// Calculate the Sun's Rise times
  AstroTime? sunRise(Observer observer) {
    return searchRiseSet(Body.Sun, observer, 1, date, 300);
  }

  /// Calculate the Sun's Set times
  AstroTime? sunSet(Observer observer) {
    return searchRiseSet(Body.Sun, observer, -1, date, 300);
  }

  /// Calculate the position of the Sun
  ({double altitude, double azimuth, double dec, double ra}) sunPosition(
      Observer observer) {
    return bodyPosition(Body.Sun, date, observer);
  }
}
