part of '../leveling.dart';

/// A class representing a levelling survey.
class Levelling {
  /// The starting benchmark (TBM) of the levelling.
  final double startingTBM;

  /// The closing TBM, if available. Nullable for open-ended surveys.
  final double? closingTBM;

  /// The survey accuracy determinate (2,3,5). Default value is 3
  final int accuracy;

  /// Round the digits after computation to value set.
  int roundDigits;

  /// The LevellingMethod currently in use.
  LevellingMethod method;

  Levelling({
    required this.startingTBM,
    this.closingTBM,
    this.accuracy = 3,
    this.roundDigits = 3,
    this.method = LevellingMethod.riseFall,
  });

  // Private properties
  double? _misclose;
  ArithmeticCheckResult? _arithmeticCheckResult;
  List<double>? _adjustedRLs;
  int _numberSTN = 0;
  double? _allowableMisclose;
  List<double> _adjustments = [];

  /// The number of stations used in the survey.
  int get numberSTN =>
      _numberSTN = measurements.where((d) => d.bs != null).length;

  /// The misclosure of the levelling survey, or null if not computed yet.
  double? get misclose => _misclose ??= _computeMisclose();

  /// The correction value.
  double? get correction => misclose == null ? null : -1 * misclose!;

  /// The per-station adjustment for height, calculated as correction divided by number of stations.
  double? get adjustmentPerStation =>
      misclose == null ? null : correction! / numberSTN;

  /// The allowable misclosure for the arithmetic check.
  double get allowableMisclose =>
      _allowableMisclose ??= _getAllowableMisclose();

  /// Indicates whether the work is accepted or not.
  bool? get isWorkAccepted => _isWorkAccepted();

  /// Cached reduced levels computed for the levelling survey.
  List<double>? _reducedLevels;

  /// The list of measurements taken during the levelling.
  List<LevellingMeasurement> measurements = [];

  /// A list of rise values calculated using the Rise and Fall method, or null if HPC method is used.
  List<dynamic> _rise = [];

  /// A list of fall values calculated using the Rise and Fall method, or null if HPC method is used.
  List<dynamic> _fall = [];

  /// A list of HPC (Height of Plane of Collimination) values calculated using the HPC method, or null if Rise and Fall method is used.
  List<dynamic> _hpc = [];

  void addMeasurement(LevellingMeasurement measurement) {
    measurements.add(measurement);
  }

  /// Add a single data to the measurements
  void addData(dynamic station, dynamic bs, dynamic is_, dynamic fs) {
    measurements
        .add(LevellingMeasurement(bs: bs, is_: is_, fs: fs, station: station));

    // Invalidate cached results
    _reducedLevels = null;
  }

  /// Get all the computed Reduced Levels (RL)
  List<double> get reducedLevels => _reducedLevels ??= computeReducedLevels();

  /// Compute the Reduced Levels (RL) based on the method
  ///
  /// Optional (method): Parse the a new method to override the old one.
  List<double> computeReducedLevels([LevellingMethod? method]) {
    this.method = method ?? this.method;

    _reducedLevels = [startingTBM];

    if (this.method == LevellingMethod.riseFall) {
      _rise = [null];
      _fall = [null];
      for (var i = 0; i < measurements.length - 1; i++) {
        var currData = measurements[i];
        var nextData = measurements[i + 1];
        var riseFall = 0.0;

        if (currData.bs != null && nextData.fs != null) {
          riseFall = currData.bs! - nextData.fs!;
        } else if (currData.bs != null && nextData.is_ != null) {
          riseFall = currData.bs! - nextData.is_!;
        } else if (currData.is_ != null && nextData.is_ != null) {
          riseFall = currData.is_! - nextData.is_!;
        } else if (currData.is_ != null && nextData.fs != null) {
          riseFall = currData.is_! - nextData.fs!;
        }

        if (riseFall >= 0) {
          _rise.add(riseFall);
          _fall.add(null);
        } else {
          _fall.add(riseFall);
          _rise.add(null);
        }

        _reducedLevels!.add(_reducedLevels!.last + riseFall);
      }
    } else {
      // HPC method
      _hpc = [];
      var hpc = 0.0;
      for (var i = 0; i < measurements.length; i++) {
        var d = measurements[i];
        if (d.bs != null && d.fs == null) {
          hpc = _reducedLevels![i] + d.bs!;
          _hpc.add(hpc);
        } else if (d.bs != null && d.fs != null) {
          _reducedLevels!.add(hpc - d.fs!);
          hpc = _reducedLevels![i] + d.bs!;
          _hpc.add(hpc);
        } else {
          _reducedLevels!.add(hpc - (d.fs ?? d.is_!));
          _hpc.add(null);
        }
      }
    }

    // Compute the misclose
    _computeMisclose();

    // Adjust the heights
    _adjustHeights();

    return _reducedLevels!;
  }

  /// Get the arithmetic checks
  ArithmeticCheckResult get arithmeticCheckResult =>
      _arithmeticCheckResult ??= () {
        // Check if RL is computed
        if (_reducedLevels == null) {
          computeReducedLevels();
        }

        var bsSum = measurements
            .where((d) => d.bs != null)
            .fold(0.0, (sum, d) => sum + d.bs!);
        var fsSum = measurements
            .where((d) => d.fs != null)
            .fold(0.0, (sum, d) => sum + d.fs!);
        var lastRlMinusFirstRl = _reducedLevels!.last - _reducedLevels!.first;
        bool isCheckPassed = (bsSum - fsSum).toStringAsFixed(roundDigits) ==
            lastRlMinusFirstRl.toStringAsFixed(roundDigits);

        return ArithmeticCheckResult(
          sumBs: bsSum,
          sumFs: fsSum,
          bsMinusFs: bsSum - fsSum,
          firstRl: _reducedLevels!.first,
          lastRl: _reducedLevels!.last,
          lastRlMinusFirstRl: lastRlMinusFirstRl,
          isArithmeticCheckPassed: isCheckPassed,
          roundDigits: roundDigits,
        );
      }();

  /// Perform height adjustment
  void _adjustHeights() {
    if (_misclose == null) {
      return;
    }

    var correction = -1 * _misclose!;
    var adjustmentPerStation = correction / _numberSTN;

    int countBS = 0;
    _adjustedRLs = List.from(_reducedLevels!); // Copy the list
    _adjustments = [0.0];
    double adjustment = 0.0;

    for (var i = 0; i < measurements.length; i++) {
      var d = measurements[i];
      if (d.bs != null) {
        countBS++;
        adjustment = countBS * adjustmentPerStation;
      }

      if (i != 0) {
        _adjustments.add(adjustment);
        _adjustedRLs![i] = _reducedLevels![i] + _adjustments[i];
      }
    }
  }

  /// Calculate the misclose
  double? _computeMisclose() {
    if (closingTBM == null) {
      return null;
    }
    // Check if RL is computed
    if (_reducedLevels == null) {
      computeReducedLevels();
    }

    return _reducedLevels!.last - closingTBM!;
  }

  /// Calculate the allowable misclose
  double _getAllowableMisclose() {
    return accuracy * sqrt(_numberSTN);
  }

  /// Check if work is accepted or not
  bool? _isWorkAccepted() {
    if (_misclose == null) {
      return null;
    }
    return (_misclose!.abs() * 1000) <= allowableMisclose;
  }

  /// Get the table in of the final result
  List<Map<String, dynamic>> getDataFrame([int? roundDigits]) {
    this.roundDigits = roundDigits ?? this.roundDigits;
    if (_reducedLevels == null) {
      throw StateError(
          "computeHeights() must be called before getting the DataFrame.");
    }
    if (_reducedLevels == null) {
      throw Exception(
          "computeHeights() must be called before getting the DataFrame.");
    }

    // Compute the misclose
    _computeMisclose();

    // Adjust the Reduce Levels if misclose is not None
    _adjustHeights();

    final List<Map<String, dynamic>> df = [];
    switch (method) {
      case LevellingMethod.riseFall:
        for (int i = 0; i < measurements.length; i++) {
          df.add(_getDataForRiseFall(i));
        }
        break;
      case LevellingMethod.hpc:
        for (int i = 0; i < measurements.length; i++) {
          df.add(_getDataForHPC(i));
        }
        break;
    }
    return df;
  }

  /// Function helper to create a table for Rise and Fall
  Map<String, dynamic> _getDataForRiseFall(int index) {
    return {
      'BS': measurements[index].bs,
      'IS': measurements[index].is_,
      'FS': measurements[index].fs,
      'Rise': _rise[index]?.toStringAsFixed(roundDigits) ?? '',
      'Fall': _fall[index]?.toStringAsFixed(roundDigits) ?? '',
      'Reduced Level (RL)': _reducedLevels![index].toStringAsFixed(roundDigits),
      if (_misclose != null)
        'Adjustment': _adjustments[index].toStringAsFixed(roundDigits),
      if (_misclose != null)
        'Adjusted RL': _adjustedRLs![index].toStringAsFixed(roundDigits),
      'Remarks': measurements[index].station,
    };
  }

  /// Function helper to create a table for HPC
  Map<String, dynamic> _getDataForHPC(int index) {
    var hpc = _hpc[index];
    return {
      'BS': measurements[index].bs,
      'IS': measurements[index].is_,
      'FS': measurements[index].fs,
      'HPC': hpc?.toStringAsFixed(roundDigits) ?? '',
      'Reduced Level (RL)': _reducedLevels![index].toStringAsFixed(roundDigits),
      if (_misclose != null)
        'Adjustment': _adjustments[index].toStringAsFixed(roundDigits),
      if (_misclose != null)
        'Adjusted RL': _adjustedRLs![index].toStringAsFixed(roundDigits),
      'Remarks': measurements[index].station,
    };
  }

  String printTable({String separator = '\t', String alignment = 'right'}) {
    var df = getDataFrame();
    List<int> columnWidths = List.generate(df[1].length, (_) => 0);

    var header = df[1].keys.join(separator);

    // Get the column width using the column length
    df[1].keys.toList(growable: false).asMap().forEach((index, value) {
      columnWidths[index] =
          max(columnWidths[index], value.toString().length).toInt();
    });

    // Get the column width using the data length
    df.map((row) => row.values
        .toList(growable: false)
        .asMap()
        .forEach((index, value) => columnWidths[index] = max(
                columnWidths[index],
                value == null
                    ? 0
                    : value.runtimeType == String
                        ? value.toString().length
                        : (value as double).toStringAsFixed(roundDigits).length)
            .toInt()));

    // Get all data to match column width
    List<String> rows = [];
    int i = -1;

    rows = df.map((row) {
      i = -1;
      return row.values.toList().map((value) {
        i++;
        String e = value == null
            ? ''
            : value.runtimeType == String
                ? value
                : (value as double).toStringAsFixed(roundDigits);
        return alignment == 'left'
            ? e.padRight(columnWidths[i])
            : e.padLeft(columnWidths[i]);
      }).join(separator);
    }).toList();

    // Calculate the number of dashes needed
    int numDashes = header.length;
    String dashes = ''.padRight(
        numDashes + 1, '-'); // Add enough dashes to match header length

    return '$header\n$dashes\n${rows.sublist(0, df.length).map((row) => row).join('\n')}';
  }

  @override
  String toString() {
    String res = '------ Levelling Summary -------\n\n';
    res += "Total measurements = ${measurements.length}\n";
    res += "Number of instrument stations = $numberSTN\n";

    if (closingTBM != null) {
      res += "Starting TBM = $startingTBM\n";
      res += "Closing TBM = $closingTBM\n\n";
    } else {
      res += "Starting TBM = $startingTBM\n\n";
    }

    if (misclose != null) {
      res +=
          "Allowable misclose = ${allowableMisclose.toStringAsFixed(roundDigits)} mm\n";
      res +=
          "Misclose = ${misclose!.toStringAsFixed(roundDigits)} m (${(misclose! * 1000).toStringAsFixed(roundDigits)} mm)\n";
      res += "Correction = ${correction?.toStringAsFixed(roundDigits)}\n";
      res +=
          "Adjustment per station = ${adjustmentPerStation?.toStringAsFixed(roundDigits)}\n";
      res +=
          "Leveling Status: ${isWorkAccepted == null ? "Was not reduced" : isWorkAccepted! ? 'Work is accepted' : 'Work is not accepted'}.\n\n";
    } else {
      res +=
          "Allowable misclose = ${allowableMisclose.toStringAsFixed(roundDigits)} mm\n\n";
    }

    res += arithmeticCheckResult.toString();

    res += printTable();
    return res;
  }
}
