import 'package:geoengine/src/leveling/leveling.dart';

void main() {
  final startingTBM = 100.000;
  final closingTBM = 98.050;
  final data = [
    ['A', 1.751, null, null],
    ['B', null, 0.540, null],
    ['C', 0.300, null, 2.100],
    ['D', null, 1.100, null],
    ['E', null, 1.260, null],
    ['F', 1.500, null, 2.300],
    ['G', null, null, 1.110]
  ];

  final leveling = Levelling(
    startingTBM: startingTBM,
    closingTBM: closingTBM,
    accuracy: 5,
    method: LevellingMethod.riseFall,
    roundDigits: 3,
  );

  // Add data
  for (var entry in data) {
    leveling.addData(entry[0].toString(), entry[1], entry[2], entry[3]);
  }

  leveling.computeReducedLevels();

  print("Rise & Fall:");
  print(leveling.getDataFrame());

  // Calculate reduced levels using Rise & Fall algorithm
  leveling.computeReducedLevels(LevellingMethod.hpc);

  print("\n\nHPC:");
  print(leveling.getDataFrame());
}
