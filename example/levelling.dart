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
    ['G', null, null, 1.100]
  ];

  final leveling =
      Levelling(startingTBM: startingTBM, closingTBM: closingTBM, k: 5);

  // Add data
  for (var entry in data) {
    leveling.addData(entry[0].toString(), entry[1], entry[2], entry[3]);
  }

  // Calculate reduced levels using HPC algorithm
  leveling.computeReducedLevels(LevellingMethod.hpc);
  print("Number of instrument station = ${leveling.numberSTN}\n");

  // Perform arithmetic checks
  final arithmeticResults = leveling.arithmeticCheck();

  print("\nArithmetic Checks:");
  print("Sum of BS = ${arithmeticResults.sumBs.toStringAsFixed(3)}");
  print("Sum of FS = ${arithmeticResults.sumFs.toStringAsFixed(3)}");
  print("First RL = ${arithmeticResults.firstRl.toStringAsFixed(3)}");
  print("Last RL = ${arithmeticResults.lastRl.toStringAsFixed(3)}");
  print(
      "Sum of BS - Sum of FS = ${arithmeticResults.bsMinusFs.toStringAsFixed(4)}");
  print(
      "Last RL - First RL = ${arithmeticResults.lastRlMinusFirstRl.toStringAsFixed(4)}");

  if (arithmeticResults.isArithmeticCheckPassed) {
    print("Arithmetic Checks are OK.");
  } else {
    final diff =
        arithmeticResults.bsMinusFs - arithmeticResults.lastRlMinusFirstRl;
    print("Arithmetic Checks failed with $diff differences");
  }

  print(
      "\nAllowable misclose = ${leveling.allowableMisclose().toStringAsFixed(4)} mm");
  if (leveling.misclose != null) {
    print(
        "Misclose = ${leveling.misclose!.toStringAsFixed(4)} m (${(leveling.misclose! * 1000).toStringAsFixed(4)} mm)");
    print(
        "Leveling Status: ${leveling.isWorkAccepted() == null ? "Was not reduced" : leveling.isWorkAccepted()! ? 'Work is accepted' : 'Work is not accepted'}.\n");

    print("Correction = ${leveling.correction?.toStringAsFixed(5)}");
    print(
        "Correction per station = ${leveling.adjustmentPerStation?.toStringAsFixed(5)}\n");
  }

  // Print HPC table
  print("HPC:");
  print(leveling.getDataFrame());

  // Calculate reduced levels using Rise & Fall algorithm
  leveling.computeReducedLevels(LevellingMethod.riseFall);

  print("\n\nRise & Fall:");
  print(leveling.getDataFrame());
}
