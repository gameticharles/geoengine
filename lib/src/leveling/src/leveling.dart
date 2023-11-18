part of leveling;

class Levelling {
  final double startingTBM;
  final double? closingTBM;
  final int k;
  final int roundDigits;

  final List<Measurement> measurements = [];
  List<double>? _reducedLevels;

  List<dynamic> _rise = [];
  List<dynamic> _fall = [];
  List<dynamic> _hpc = [];
  LevellingMethod method;

  Levelling(
      {required this.startingTBM,
      this.closingTBM,
      this.k = 3,
      this.roundDigits = 4,
      this.method = LevellingMethod.riseFall});

  // // Named constructor for creating an instance from a file
  // Levelling.fromFile(this.startingTBM, String filePath,
  //     {this.method = LevellingMethod.RiseFall})
  //     : closingTBM = null,
  //       k = 3,
  //       roundDigits = 4 {
  //   readFromFile(filePath);
  // }

  // Private properties
  double? _misclose;
  List<double>? _adjustedRLs;
  int _numberSTN = 0;
  List<double> _adjustments = [];

  int get numberSTN => _numberSTN;
  double? get misclose => _misclose;
  double? get correction => misclose == null ? null : 1 * misclose!;
  double? get adjustmentPerStation =>
      misclose == null ? null : correction! / numberSTN;

  // Future<void> readFromFile(String filePath) async {
  //   final file = File(filePath);
  //   if (!await file.exists()) {
  //     throw Exception('File not found.');
  //   }

  //   final lines = file.readAsLinesSync();
  //   for (var line in lines) {
  //     final parts = line.split(' ');
  //     if (parts.length == 4) {
  //       addData(parts[0], double.parse(parts[1]), double.parse(parts[2]),
  //           double.parse(parts[3]));
  //     }
  //   }
  // }

  void addMeasurement(Measurement measurement) {
    measurements.add(measurement);
  }

  void addData(String station, dynamic bs, dynamic is_, dynamic fs) {
    measurements.add(Measurement(station: station, bs: bs, is_: is_, fs: fs));

    // Invalidate cached results
    _reducedLevels = null;
  }

  List<double> get reducedLevels => _reducedLevels ??= computeReducedLevels();

  List<double> computeReducedLevels([var method = LevellingMethod.riseFall]) {
    _reducedLevels = [startingTBM];
    _numberSTN = measurements.where((d) => d.bs != null).length;
    this.method = method;

    if (method == LevellingMethod.riseFall) {
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
    computeMisclose();

    adjustHeights();

    return _reducedLevels!;
  }

  ArithmeticCheckResult arithmeticCheck() {
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
      allowableMisclose: allowableMisclose(),
      misclose: _misclose,
      workStatus: isWorkAccepted(),
    );
  }

  void adjustHeights() {
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

  void computeMisclose() {
    if (closingTBM == null) {
      return;
    }
    _misclose = _reducedLevels!.last - closingTBM!;
  }

  double allowableMisclose() {
    return k * sqrt(_numberSTN);
  }

  bool? isWorkAccepted() {
    if (_misclose == null) {
      return null;
    }
    return (_misclose!.abs() * 1000) <= allowableMisclose();
  }

  List<Map<String, dynamic>> getDataFrame([int roundDigits = 4]) {
    if (_reducedLevels == null) {
      throw StateError(
          "computeHeights() must be called before getting the DataFrame.");
    }
    if (_reducedLevels == null) {
      throw Exception(
          "computeHeights() must be called before getting the DataFrame.");
    }

    // Compute the misclose
    computeMisclose();

    // Adjust the Reduce Levels if misclose is not None
    adjustHeights();

    final List<Map<String, dynamic>> df = [];
    switch (method) {
      case LevellingMethod.riseFall:
        for (int i = 0; i < measurements.length; i++) {
          df.add(_getDataForRiseFall(i, roundDigits));
        }
        break;
      case LevellingMethod.hpc:
        for (int i = 0; i < measurements.length; i++) {
          df.add(_getDataForHPC(i, roundDigits));
        }
        break;
    }
    return df;
  }

  Map<String, dynamic> _getDataForRiseFall(int index, int roundDigits) {
    return {
      'Remarks': measurements[index].station,
      'BS': measurements[index].bs,
      'IS': measurements[index].is_,
      'FS': measurements[index].fs,
      'Rise': _rise[index]?.toStringAsFixed(roundDigits),
      'Fall': _fall[index]?.toStringAsFixed(roundDigits),
      'Reduced Level (RL)': _reducedLevels![index].toStringAsFixed(roundDigits),
      if (_misclose != null)
        'Adjustment': _adjustments[index].toStringAsFixed(roundDigits),
      if (_misclose != null)
        'Adjusted RL': _adjustedRLs![index].toStringAsFixed(roundDigits),
    };
  }

  Map<String, dynamic> _getDataForHPC(int index, int roundDigits) {
    var hpc = _hpc[index];
    return {
      'Remarks': measurements[index].station,
      'BS': measurements[index].bs,
      'IS': measurements[index].is_,
      'FS': measurements[index].fs,
      'HPC': hpc?.toStringAsFixed(roundDigits) ?? '',
      'Reduced Level (RL)': _reducedLevels![index].toStringAsFixed(roundDigits),
      if (_misclose != null)
        'Adjustment': _adjustments[index].toStringAsFixed(roundDigits),
      if (_misclose != null)
        'Adjusted RL': _adjustedRLs![index].toStringAsFixed(roundDigits),
    };
  }

  @override
  String toString() {
    return measurements.toString();
  }
}
