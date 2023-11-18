part of leveling;

class ArithmeticCheckResult {
  double sumBs;
  double sumFs;
  double bsMinusFs;
  double firstRl;
  double lastRl;
  double lastRlMinusFirstRl;
  bool isArithmeticCheckPassed;
  double allowableMisclose;
  double? misclose;
  bool? workStatus;

  ArithmeticCheckResult({
    required this.sumBs,
    required this.sumFs,
    required this.bsMinusFs,
    required this.firstRl,
    required this.lastRl,
    required this.lastRlMinusFirstRl,
    required this.isArithmeticCheckPassed,
    required this.allowableMisclose,
    this.misclose,
    this.workStatus,
  });

  @override
  String toString() {
    return 'Sum of BS: $sumBs, Sum of FS: $sumFs, ...'; // You can expand this for all properties
  }
}
