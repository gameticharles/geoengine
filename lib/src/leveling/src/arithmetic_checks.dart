part of '../leveling.dart';

/// A class representing the results of an arithmetic check in surveying.
class ArithmeticCheckResult {
  /// The sum of all backward sight distances (BS).
  double sumBs;

  /// The sum of all forward sight distances (FS).
  double sumFs;

  /// Difference between the sum of BS and the sum of FS.
  double bsMinusFs;

  /// The first reduced level (Rl) value.
  double firstRl;

  /// The last reduced level (Rl) value.
  double lastRl;

  /// Difference between the first and last Rl values.
  double lastRlMinusFirstRl;

  /// Indicates whether the arithmetic check passed or failed.
  bool isArithmeticCheckPassed;

  /// Round the digits after computation to value set.
  final int roundDigits;

  /// Creates a new instance of ArithmeticCheckResult with all properties set.
  ArithmeticCheckResult({
    required this.sumBs,
    required this.sumFs,
    required this.bsMinusFs,
    required this.firstRl,
    required this.lastRl,
    required this.lastRlMinusFirstRl,
    required this.isArithmeticCheckPassed,
    this.roundDigits = 3,
  });

  /// Returns a string representation of the object containing all properties.
  @override
  String toString() {
    String res = '';
    res += "Arithmetic Checks:\n";
    res += "Sum of BS = ${sumBs.toStringAsFixed(roundDigits)}\n";
    res += "Sum of FS = ${sumFs.toStringAsFixed(roundDigits)}\n";
    res += "First RL = ${firstRl.toStringAsFixed(roundDigits)}\n";
    res += "Last RL = ${lastRl.toStringAsFixed(roundDigits)}\n";
    res +=
        "Sum of BS - Sum of FS = ${bsMinusFs.toStringAsFixed(roundDigits)}\n";
    res +=
        "Last RL - First RL = ${lastRlMinusFirstRl.toStringAsFixed(roundDigits)}\n";

    if (isArithmeticCheckPassed) {
      res += "Arithmetic Checks are OK.\n\n";
    } else {
      final diff = bsMinusFs - lastRlMinusFirstRl;
      res += "Arithmetic Checks failed with $diff differences\n\n";
    }

    return res;
  }
}
