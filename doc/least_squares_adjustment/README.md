# Least Squares Adjustment Module

Least Squares Adjustment (LSA) is a fundamental statistical method used extensively in surveying, geodesy, and other scientific fields. Its primary purpose is to estimate the optimal values of unknown parameters by minimizing the sum of the squares of the differences between observed values and values computed from a mathematical model. This technique is particularly useful for solving overdetermined systems, where there are more observations than necessary to determine the unknowns, allowing for statistical analysis and error propagation.

## `LeastSquaresAdjustment` Class

The `LeastSquaresAdjustment` class in GeoEngine provides a robust framework for performing these computations. It typically relies on matrix operations from a library like `advance_math` or similar.

### Initialization

To begin an LSA computation, you need to initialize the `LeastSquaresAdjustment` class with the following:

- **`A` (Matrix):** The design matrix (or Jacobian matrix). This matrix relates the observations to the unknown parameters. Each row corresponds to an observation, and each column corresponds to an unknown parameter.
- **`B` (ColumnMatrix):** The observation vector (or misclosure vector). This vector contains the differences between observed values and values computed from initial estimates of the parameters (often L - C, where L is observed and C is computed).
- **`W` (DiagonalMatrix, optional):** The weight matrix. This diagonal matrix assigns a weight to each observation, typically inversely proportional to its variance (e.g., `1/variance`). If not provided, a default identity matrix (equal weights) might be assumed.
- **`confidenceLevel` (double, optional):** The confidence level (e.g., 95 for 95%) used for statistical testing, particularly for outlier detection. Defaults to a standard value (e.g., 95%) if not provided.

**Conceptual Example:**
```dart
import 'package:geoengine/geoengine.dart'; 
// Matrix types might come from a dependency like 'package:advance_math/advance_math.dart'
// which geoengine might re-export or use internally.
// import 'package:advance_math/advance_math.dart'; 


// Assuming A, B, and W are already defined instances of Matrix, ColumnMatrix, and DiagonalMatrix
// var A = Matrix([...]);
// var B = ColumnMatrix([...]);
// var W = DiagonalMatrix([...]); // Optional

// var lsa = LeastSquaresAdjustment(A: A, B: B, W: W, confidenceLevel: 95);
```

## Key Properties

Once the LSA is performed (implicitly upon initialization), the `LeastSquaresAdjustment` object provides several properties:

-   **`x` (ColumnMatrix):** The vector of estimated unknown parameters (solution vector).
-   **`v` (ColumnMatrix):** The vector of residuals (differences between observed and model-predicted values using adjusted parameters).
-   **`uv` (double):** The unit variance (a posteriori variance factor, σ₀²). A measure of the overall fit of the adjustment.
-   **`N` (Matrix):** The normal matrix (`A^T * W * A`).
-   **`qxx` (Matrix):** The cofactor matrix of the unknown parameters (`N^-1`).
-   **`cx` (Matrix):** The variance-covariance matrix of the adjusted parameters (`qxx * uv`). (The main README's mention of "Adjusted Heights" suggests an application, but this is general for any parameters).
-   **`cv` (Matrix):** The variance-covariance matrix of the residuals.
-   **`cl` (Matrix):** The variance-covariance matrix of the (adjusted) observations.
-   **`standardDeviation` (double):** The a posteriori standard deviation of an observation of unit weight (√uv).
-   **`standardError` (double):** Often refers to `standardDeviation` (σ₀). More specific standard errors are below.
-   **`standardErrorsOfUnknowns` (List<double>):** Standard errors (standard deviations) of each estimated unknown parameter (square roots of diagonal elements of `cx`).
-   **`standardErrorsOfResiduals` (List<double>):** Standard errors of the residuals.
-   **`standardErrorsOfObservations` (List<double>):** Standard errors of the adjusted observations.
-   **`chiSquared` (double):** Calculated Chi-squared (χ²) statistic for goodness-of-fit testing.
-   **`rejectionCriterion` (double):** Threshold for outlier detection, based on `confidenceLevel`.
-   **`outliers` (List<bool>):** Indicates if each observation is an outlier (`true` if outlier).

## Methods

### `chiSquareTest()`

**Purpose:** Performs a Chi-Square (χ²) goodness-of-fit test. This assesses if the unit variance (`uv`) is statistically consistent with an expected variance.
**Returns:** An object or map, typically `(chiSquared: value, degreesOfFreedom: df)`.

### `covariance()`

**Purpose:** Computes and returns a specific covariance matrix. Contextually, this often refers to `cx` (variance-covariance of adjusted parameters), but could also be `cv` or `cl`.
**Returns:** `Matrix`

### `errorEllipse()`

**Purpose:** Computes parameters for error ellipses, usually for 2D coordinate unknowns, representing the uncertainty of an adjusted point.
**Returns:** A list or object with ellipse parameters (e.g., semi-major/minor axes, orientation).

### `removeOutliersIteratively()`

**Purpose:** Automatically identifies and removes outliers and re-runs the adjustment, potentially iteratively.
**Returns:** A new `LeastSquaresAdjustment` object after outlier removal.

### `computeConfidenceIntervals()`

**Purpose:** Computes confidence intervals for the estimated unknown parameters, indicating the range where true values likely lie.
**Returns:** A list of tuples/objects, each with lower/upper bounds for an unknown parameter.

### `customAutoScale()`

**Purpose:** Allows custom scaling/normalization of input matrices (`A`, `B`, `W`) for numerical stability or specific needs.
**Parameters:** Functions for normalizing `Matrix`, `ColumnMatrix`, `DiagonalMatrix`.
**Returns:** A new `LeastSquaresAdjustment` object with scaled matrices.

## Comprehensive Example

The following example (from the main `README.md`) demonstrates initialization and basic usage:

```dart
// Ensure necessary imports for Matrix types, e.g., from 'package:advance_math/advance_math.dart'
// if they are not directly part of geoengine's public API.
import 'package:advance_math/advance_math.dart'; 
import 'package:geoengine/geoengine.dart'; 


void main() {
  // Define the design matrix A
  var A = Matrix([
    [-1, 0, 0, 0],
    [-1, 1, 0, 0],
    [0, -1, 1, 0],
    [0, 0, -1, 0],
    [0, 0, -1, 1],
    [0, 0, 0, -1],
    [1, 0, 0, -1],
  ]);

  // Define the weight matrix W (typically inverse of variances of observations)
  var W = DiagonalMatrix([1 / 16, 1 / 9, 1 / 49, 1 / 36, 1 / 16, 1 / 9, 1 / 25]);
  
  // Define the observation vector B (differences: observed - computed)
  var B = ColumnMatrix([0, 0, 0.13, 0, 0, -0.32, -0.53]);

  // Initialize LeastSquaresAdjustment
  // A confidenceLevel of 40% is unusual but used in the example.
  var lsa = LeastSquaresAdjustment(A: A, B: B, W: W, confidenceLevel: 40);

  // Perform and print Chi-Square test results
  var chiTestResult = lsa.chiSquareTest();
  print('Chi-Square Test: $chiTestResult'); 
  // Example Output: Chi-Square Test: (chiSquared: 0.00340817748488164, degreesOfFreedom: 3)

  // Print the full LSA results (properties)
  // The `toString()` method of LeastSquaresAdjustment is formatted to show many key results.
  print(lsa); 
  
  // Accessing specific properties after adjustment:
  print('\\nSelected Results:');
  print('Unknown Parameters (x):\\n${lsa.x}');
  print('Residuals (v):\\n${lsa.v}');
  print('Unit Variance (uv): ${lsa.uv}');
  print('Standard Errors of Unknowns: ${lsa.standardErrorsOfUnknowns}');
  print('Outliers: ${lsa.outliers}');
}
```

---
*Note: For detailed mathematical formulas and derivations behind Least Squares Adjustment, please consult geodetic or statistical textbooks. The matrix operations depend on a suitable math library.*
```yaml
dependencies:
  geoengine: any # Replace with the desired version
  advance_math: any # Or your chosen matrix math library
```
