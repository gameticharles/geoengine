import 'package:advance_math/advance_math.dart';
import 'package:geoengine/geoengine.dart';

void main(List<String> args) {
  var p = Polygon(vertices: [
    Point(591.4, 432.59),
    Point(542.7, 625.4),
    Point(612.8, 896.2),
    Point(756.0, 685.9),
    Point(632.6, 562.5)
  ]);

  print(p.shoelace());
  print(p.trapezoidal());


}
