import 'package:geoengine/geoengine.dart';

void main(List<String> arguments) {
  var center = Point(0, 0);
  var circle = Circle(center, 5);
  print(circle.area()); // Expected output: 78.53981633974483
  print(circle.circumference()); // Expected output: 31.41592653589793
  print(circle.isPointInside(Point(3, 4))); // Expected output: true

  // Define a spherical triangle with one angle-side pair
  var triangle = SphericalTriangle.fromAllSides(
      Angle(rad: pi / 2), Angle(rad: pi / 3), Angle(rad: pi / 4));

  // Angles
  print(
      'AngleA: ${triangle.angleA} '); // AngleA: Angle: 35.26438968275524° or 0.6154797086703871 rad or [35, 15, 51.802857918852396]
  print(
      'AngleB: ${triangle.angleB} '); // AngleB: Angle: 125.26438968275677° or 2.186276035465284 rad or [125, 15, 51.80285792437758]
  print(
      'AngleC: ${triangle.angleC}'); // AngleC: Angle: 45.00000000000074° or 0.785398163397448 rad or [45, 0, 2.660272002685815e-9]

  // Sides
  print(
      'SideA: ${triangle.sideA}'); // SideA: Angle: 90.00000000000152° or 1.5707963267948966 rad or [90, 0, 5.474021236295812e-9]
  print(
      'SideB: ${triangle.sideB}'); // SideB: Angle: 60.00000000000101° or 1.0471975511965976 rad or [60, 0, 3.632294465205632e-9]
  print(
      'SideC: ${triangle.sideC} '); // SideC: Angle: 45.00000000000076° or 0.7853981633974483 rad or [45, 0, 2.737010618147906e-9]

  print(
      'Area: ${triangle.area} ≈ ${triangle.areaPercentage} % of unit sphere surface area'); // Area: 0.445561253943326 ≈ 3.545663800765179 % of unit sphere surface area
  print(
      'Perimeter: ${triangle.perimeter} ≈ ${triangle.perimeterPercentage} % of unit sphere circumference'); // Perimeter: 3.4033920413889422 ≈ 54.166666666666664 % of unit sphere circumference
  print(
      'isValidTriangle: ${triangle.isValidTriangle()}'); // isValidTriangle: true
}
