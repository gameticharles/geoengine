import 'package:geoengine/geoengine.dart';

void main() {
  /// Example usage of the ErrorEllipse class.
  var ellipse = ErrorEllipse(
    sigmaX2: 3.036546e-04,
    sigmaY2: 2.723551e-04,
    sigmaXY: -1.173078e-04,
  );

  print(ellipse.generateEllipsePoints(100, centerX: 100.0, centerY: 100.0));

  print(ellipse);
}
