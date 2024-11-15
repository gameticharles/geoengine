part of 'astronomy.dart';

class PascalArray1 {
  int min;
  List<double> array;
  PascalArray1({required this.min, required this.array});
}

class PascalArray2 {
  int min;
  List<PascalArray1> array;
  PascalArray2({required this.min, required this.array});
}

class ComplexValue {
  double x;
  double y;

  ComplexValue(this.x, this.y);
}

typedef ThetaFunc = Function(double real, double imag);

class PlanetInfo {
  final double orbitalPeriod;

  PlanetInfo(this.orbitalPeriod);
}


