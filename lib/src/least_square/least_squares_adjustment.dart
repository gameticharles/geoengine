// ignore_for_file: non_constant_identifier_names

part of '../../geoengine.dart';

/// `LeastSquaresAdjustment` class provides methods for performing a least squares adjustment.
///
/// The class accepts the design matrix [A], the observation vector [B], and an optional weight matrix [W].
/// If [W] is not provided, a diagonal matrix of ones is used, giving equal weight to all observations.
/// The optional confidence level can be provided to adjust the rejection criterion for outlier detection.
///
/// Example:
/// ```dart
/// var A = Matrix([
///   [-1, 0, 0, 0],
///   [-1, 1, 0, 0],
///   [0, -1, 1, 0],
///   [0, 0, -1, 0],
///   [0, 0, -1, 1],
///   [0, 0, 0, -1],
///   [1, 0, 0, -1],
/// ]);
/// var B = ColumnMatrix([0, 0, 0.13, 0, 0, -0.32, -0.53]);
/// var W = DiagonalMatrix([1 / 16, 1 / 9, 1 / 49, 1 / 36, 1 / 16, 1 / 9, 1 / 25]);
///
/// var lsa = LeastSquaresAdjustment(A: A, B: B);
/// print(lsa.x); // Output: [values]
/// ```
class LeastSquaresAdjustment {
  final Matrix A;
  final ColumnMatrix B;
  final double confidenceLevel;
  DiagonalMatrix W;

  Matrix? _nInv;
  Matrix? _qxx;
  Matrix? _x;
  Matrix? _v;
  double? _uv;
  Matrix? _cx;
  Matrix? _cv;
  Matrix? _cl;
  double? _standardDeviation;
  EquationMethod method;
  late final LinearSystemMethod _linear;
  late final DecompositionMethod _decomposition;

  /// Constructs a `LeastSquaresAdjustment` object.
  ///
  /// [A] is the design matrix,
  /// [B] is the observation vector,
  /// [W] is the optional weight matrix, and
  /// [confidenceLevel] is the optional confidence level in percentage.
  LeastSquaresAdjustment({
    required this.A,
    required this.B,
    DiagonalMatrix? W,
    this.confidenceLevel = 99.9,
    this.method = EquationMethod.linear,
    LinearSystemMethod linear = LinearSystemMethod.leastSquares,
    DecompositionMethod decomposition = DecompositionMethod.cholesky,
    ScalingMethod scalingMethod = ScalingMethod.none,
  })  : W = W ?? DiagonalMatrix(List.filled(A.rowCount, 1.0)),
        _linear = linear,
        _decomposition = decomposition {
    // 1. Check for dimension mismatch between A and B
    if (A.rowCount != B.rowCount) {
      throw ArgumentError(
          'The number of rows in matrix A must be equal to the number of rows in vector B.');
    }

    // // Apply scaling first, based on the method chosen
    // switch (scalingMethod) {
    //   case ScalingMethod.minMax:
    //     A = minMaxScale(A);
    //     B = minMaxScale(B);
    //     W = uniformWeights(A); // You could define your own logic for weights
    //     break;
    //   case ScalingMethod.standardization:
    //     A = standardize(A);
    //     B = standardize(B);
    //     W = uniformWeights(A); // You could define your own logic for weights
    //     break;
    //   case ScalingMethod.unitVector:
    //     A = unitVectorScale(A);
    //     B = unitVectorScale(B);
    //     W = uniformWeights(A); // You could define your own logic for weights
    //     break;
    //   case ScalingMethod.uniformWeights:
    //     W = uniformWeights(A);
    //     break;
    //   case ScalingMethod.inverseVariance:
    //     W = inverseVariance(A); // You'd have to define this method
    //     break;
    //   case ScalingMethod.logTransformation:
    //     A = logTransformation(A);
    //     B = logTransformation(B);
    //     W = uniformWeights(A); // You could define your own logic for weights
    //     break;
    //   case ScalingMethod.none:
    //   default:
    //     // Do nothing, use the matrices as they are
    //     break;
    // }
  }

  /// Normal matrix
  Matrix get N => (A.transpose() * W * A);

  /// Inverse of the normal matrix.
  Matrix get nInv => _nInv ??= N.inverse();

  /// Misclosure matrix.
  Matrix get qxx => _qxx ??= (W.inverse() - (A * nInv * A.transpose()));

  /// Unknown parameters.
  Matrix get x {
    //_x ??= nInv * (A.transpose() * W * B);
    var matAtWb = (A.transpose() * W * B);

    return _x ??= method == EquationMethod.linear
        ? N.linear.solve(matAtWb, method: _linear)
        : N.decomposition.solve(matAtWb, method: _decomposition);
  }

  /// Residuals.
  Matrix get v => _v ??= (A * x) - B;

  /// Unit variance.
  double get uv =>
      _uv ??= ((v.transpose() * W * v) / (A.rowCount - A.columnCount))[0][0];

  /// Variance-Covariance of the Adjusted Heights
  Matrix get cx => _cx ??= nInv * uv;

  /// Variance-Covariance of the Residuals
  Matrix get cv => _cv ??= qxx * uv;

  /// Variance-Covariance of the Observations
  Matrix get cl => _cl ??= A * cx * A.transpose();

  /// Standard deviation.
  double get standardDeviation => _standardDeviation ??= sqrt(uv);

  /// Compute standard error of the mean, which is the standard deviation
  /// divided by the square root of the number of observations.
  double get standardError => standardDeviation / sqrt(A.rowCount);

  /// Standard errors of the unknowns.
  List<dynamic> get standardErrorsOfUnknowns =>
      cx.diagonal().map((e) => sqrt(e)).toList();

  /// Standard errors of the residuals.
  List<dynamic> get standardErrorsOfResiduals =>
      cv.diagonal().map((e) => sqrt(e)).toList();

  /// Standard errors of the observations.
  List<dynamic> get standardErrorsOfObservations =>
      cl.diagonal().map((e) => sqrt(e)).toList();

  /// Chi-squared (χ²) value for the least squares adjustment.
  double get chiSquared => (v.transpose() * W * v)[0][0];

  /// Performs a Chi-Square goodness-of-fit test.
  ///
  /// The method calculates the Chi-Square statistic and the degrees of freedom,
  /// and returns a tuple containing these values.
  ///
  /// Example:
  /// ```dart
  /// var lsa = LeastSquaresAdjustment(A: A, B: B);
  /// var chiSquareTest = lsa.chiSquareTest();
  /// print('Chi-Square Statistic: ${chiSquareTest.chiSquared}');
  /// print('Degrees of Freedom: ${chiSquareTest.degreesOfFreedom}');
  /// ```
  ///
  /// @return A tuple containing the Chi-Square statistic and the degrees of freedom.
  ({double chiSquared, int degreesOfFreedom}) chiSquareTest() {
    // Calculate the Chi-Square statistic
    double chiSquared = (v.transpose() * W * v)[0][0];

    // Calculate the degrees of freedom
    int degreesOfFreedom = A.rowCount - A.columnCount;

    return (chiSquared: chiSquared, degreesOfFreedom: degreesOfFreedom);
  }

  /// Compute covariance matrix either of the coefficients or of the residuals.
  Matrix covariance([bool isOnDesignMatrix = true]) {
    if (isOnDesignMatrix) {
      // Compute the covariance matrix of the coefficients
      return nInv * uv;
    } else {
      // Compute the covariance matrix of the residuals
      Matrix centered = v - v.mean();
      return (centered.transpose() * centered) / (A.rowCount - 1);
    }
  }

  /// Compute error ellipse parameters using eigenvalue decomposition on the covariance matrix.
  Eigen errorEllipse() {
    // Get covariance matrix
    Matrix cov = covariance();
    // Perform Eigenvalue decomposition on covariance matrix
    Eigen eig = cov.eigen();
    return eig;
  }

  /// Rejection criterion for outlier detection, using the specified confidence level.
  dynamic get rejectionCriterion {
    // Convert confidence level to z-value using the standard normal distribution
    double zValue = ZScore.computeZScore(confidenceLevel);
    return zValue * standardDeviation;
  }

  /// List of boolean values indicating whether each observation is an outlier (true) or not (false).
  List<bool> get outliers {
    var qxxDiag = qxx.diagonal();
    var results = List<bool>.filled(qxxDiag.length, false);
    for (var i = 0; i < qxxDiag.length; i++) {
      results[i] = v[i][0] / qxxDiag[i] > rejectionCriterion;
    }
    return results;
  }

  @override
  String toString() {
    var results = StringBuffer();

    results.writeln('Least Squares Adjustment Results:');
    results.writeln('---------------------------------');
    results.writeln('Normal (N):\n$N\n');
    results.writeln('Unknown Parameters (x):\n$x\n');
    results.writeln('Residuals (v):\n$v\n');
    results.writeln('Unit Variance (σ²): $uv\n');
    results.writeln('Standard Deviation (σ): $standardDeviation\n');
    results.writeln('Chi-squared Test (Goodness-of-fit Test):');
    var cst = chiSquareTest();
    results.writeln('Chi-squared value(χ²): ${cst.chiSquared}');
    results.writeln('Degrees of Freedom: ${cst.degreesOfFreedom}\n');
    results.writeln(
        'Standard Errors of Unknowns (Cx): \n$standardErrorsOfUnknowns\n');
    results.writeln(
        'Standard Errors of Residuals (Cv): \n$standardErrorsOfResiduals\n');
    results.writeln(
        'Standard Errors of Observations (Cl): \n$standardErrorsOfObservations\n');
    results.writeln(
        'Rejection Criterion (Confidence Level $confidenceLevel): $rejectionCriterion\n');
    results.writeln(
        'Outliers (false = accepted, true = rejected): \n${outliers.toString()}\n');
    results.writeln('Error Ellipse: \n${errorEllipse().values}\n');
    results.writeln('---------------------------------');

    return results.toString();
  }

  /// Perform batch least squares adjustments.
  ///
  /// Takes a list of design matrices [As] and a list of observation vectors [Bs].
  /// Optionally, a list of weight matrices [Ws] and confidence levels [confidenceLevels] can be provided.
  ///
  /// Returns a list of LeastSquaresAdjustment objects.
  ///
  /// Example:
  /// ```dart
  /// var batchResults = LeastSquaresAdjustment.batchAdjust(
  ///   As: [A1, A2],
  ///   Bs: [B1, B2],
  ///   Ws: [W1, W2],
  ///   confidenceLevels: [99, 95]
  /// );
  /// ```
  static List<LeastSquaresAdjustment> batchAdjust({
    required List<Matrix> As,
    required List<ColumnMatrix> Bs,
    List<DiagonalMatrix>? Ws,
    List<double>? confidenceLevels,
  }) {
    if (As.length != Bs.length) {
      throw ArgumentError(
          'The number of design matrices must match the number of observation vectors.');
    }

    if (Ws != null && As.length != Ws.length) {
      throw ArgumentError(
          'The number of weight matrices must match the number of design matrices.');
    }

    if (confidenceLevels != null && As.length != confidenceLevels.length) {
      throw ArgumentError(
          'The number of confidence levels must match the number of design matrices.');
    }

    List<LeastSquaresAdjustment> batchResults = [];

    for (int i = 0; i < As.length; i++) {
      batchResults.add(LeastSquaresAdjustment(
        A: As[i],
        B: Bs[i],
        W: Ws != null ? Ws[i] : null,
        confidenceLevel: confidenceLevels != null ? confidenceLevels[i] : 99.9,
      ));
    }

    return batchResults;
  }

  /// Performs an iterative least squares adjustment to automatically remove outliers.
  ///
  /// The method iteratively performs least squares adjustments, identifies outliers,
  /// removes them, and re-runs the adjustment until no more outliers are found.
  ///
  /// Example:
  /// ```dart
  /// var lsa = LeastSquaresAdjustment(A: A, B: B);
  /// var newLsa = lsa.removeOutliersIteratively();
  /// print(newLsa.getResults());
  /// ```
  ///
  /// @return A new LeastSquaresAdjustment object with outliers removed.
  LeastSquaresAdjustment removeOutliersIteratively() {
    LeastSquaresAdjustment currentLsa = this;
    List<bool> currentOutliers;

    do {
      // Perform the least squares adjustment
      // (this is implicitly done when accessing properties like `outliers`)

      // Get the current list of outliers
      currentOutliers = currentLsa.outliers;

      // Check if there are any outliers
      if (currentOutliers.any((element) => element)) {
        // Remove the outliers and get a new LeastSquaresAdjustment object
        currentLsa = currentLsa._removeDataPoints(currentOutliers);
      }
    } while (currentOutliers.any((element) => element));

    return currentLsa;
  }

  /// Removes data points that are marked as outliers and returns a new LeastSquaresAdjustment object.
  ///
  /// @param toRemove List of booleans indicating which rows to remove.
  /// @return A new LeastSquaresAdjustment object with the specified rows removed.
  LeastSquaresAdjustment _removeDataPoints(List<bool> toRemove) {
    // Collect indices of rows to keep
    List<int> indicesToRemove = [];
    for (int i = 0; i < toRemove.length; i++) {
      if (toRemove[i]) {
        indicesToRemove.add(i);
      }
    }

    // Create new matrices and vectors with rows removed
    Matrix newA = A.removeRows(indicesToRemove);
    ColumnMatrix newB = B.removeRows(indicesToRemove).column(0);
    DiagonalMatrix newW =
        DiagonalMatrix(W.removeRows(indicesToRemove).diagonal());

    // Create a new LeastSquaresAdjustment object with the modified data
    return LeastSquaresAdjustment(
      A: newA,
      B: newB,
      W: newW,
      confidenceLevel: confidenceLevel,
      method: method,
      decomposition: _decomposition,
      linear: _linear,
    );
  }

  /// Computes the confidence intervals for the unknown parameters.
  ///
  /// The method computes confidence intervals based on the standard errors of the unknowns
  /// and the specified confidence level.
  ///
  /// Returns a list of tuples, each containing the lower and upper bounds of the confidence interval for each unknown parameter.
  ///
  /// Example:
  /// ```dart
  /// var lsa = LeastSquaresAdjustment(A: A, B: B);
  /// var intervals = lsa.computeConfidenceIntervals();
  /// print(intervals);  // Output: [(lower1, upper1), (lower2, upper2), ...]
  /// ```
  ///
  /// @return A list of tuples containing the lower and upper bounds of the confidence intervals.
  List<(double, double)> computeConfidenceIntervals() {
    // Convert confidence level to z-value using the standard normal distribution
    double zValue = ZScore.computeZScore(confidenceLevel);

    // Get the standard errors for the unknown parameters
    List<double> standardErrors =
        standardErrorsOfUnknowns.map((e) => e as double).toList();

    // Compute confidence intervals
    List<(double, double)> intervals = [];
    for (int i = 0; i < x.rowCount; i++) {
      double theta = x[i][0];
      double errorMargin = zValue * standardErrors[i];
      intervals.add((theta - errorMargin, theta + errorMargin));
    }

    return intervals;
  }

  /// Automatically scales or normalizes the design matrix A and observation vector B and
  /// weight based on custom functions.
  ///
  /// The method takes a normalization function for the design matrix A and the observation vector B.
  ///
  /// Example:
  /// ```dart
  /// var lsa = LeastSquaresAdjustment(A: A, B: B);
  /// var scaledLsa = lsa.customAutoScale(
  ///   matrixNormalizationFunction: (Matrix A) => A.normalize(),
  ///   columnNormalizationFunction: (ColumnMatrix B) => B.normalize(),
  ///   diagonalNormalizationFunction: (DiagonalMatrix W) => W.normalize()
  /// );
  /// ```
  ///
  /// @return A new LeastSquaresAdjustment object with scaled A and B matrices.
  LeastSquaresAdjustment customAutoScale({
    required MatrixNormalizationFunction matrixNormalizationFunction,
    required ColumnNormalizationFunction columnNormalizationFunction,
    required DiagonalNormalizationFunction diagonalNormalizationFunction,
  }) {
    // Apply the custom normalization functions to A and B
    Matrix newA = matrixNormalizationFunction(A);
    ColumnMatrix newB = columnNormalizationFunction(B);
    DiagonalMatrix newW = diagonalNormalizationFunction(W);

    // Create a new LeastSquaresAdjustment object with the normalized data
    return LeastSquaresAdjustment(
      A: newA,
      B: newB,
      W: newW,
      confidenceLevel: confidenceLevel,
      method: method,
    );
  }
}

/// A typedef for a function that takes a [Matrix] object and returns a new,
/// normalized [Matrix] object.
///
/// This is used for customizing the normalization behavior of the design matrix
/// in a [LeastSquaresAdjustment] object.
///
/// Example:
/// ```dart
/// Matrix myNormalizationFunction(Matrix A) {
///   // Perform custom normalization on A and return a new Matrix
///   return A;  // Replace with actual normalization logic
/// }
/// ```
typedef MatrixNormalizationFunction = Matrix Function(Matrix matrix);

/// A typedef for a function that takes a [ColumnMatrix] object and returns a new,
/// normalized [ColumnMatrix] object.
///
/// This is used for customizing the normalization behavior of the observation vector
/// in a [LeastSquaresAdjustment] object.
///
/// Example:
/// ```dart
/// ColumnMatrix myNormalizationFunction(ColumnMatrix B) {
///   // Perform custom normalization on B and return a new Column
///   return B;  // Replace with actual normalization logic
/// }
/// ```
typedef ColumnNormalizationFunction = ColumnMatrix Function(
    ColumnMatrix column);

/// A typedef for a function that takes a [DiagonalMatrix] object and returns a new,
/// normalized [DiagonalMatrix] object.
///
/// This is used for customizing the normalization behavior of the weight matrix
/// in a [LeastSquaresAdjustment] object.
///
/// Example:
/// ```dart
/// DiagonalMatrix myNormalizationFunction(DiagonalMatrix W) {
///   // Perform custom normalization on W and return a new Diagonal
///   return W;  // Replace with actual normalization logic
/// }
/// ```
typedef DiagonalNormalizationFunction = DiagonalMatrix Function(
    DiagonalMatrix diagonal);
