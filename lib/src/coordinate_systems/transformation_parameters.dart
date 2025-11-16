part of 'coordinate_reference_systems.dart';

/// Transformation Parameters for datum transformations.
class TransformationParameters {
  /// Delta X (Meter).
  double dx;

  /// Delta Y (Meter).
  double dy;

  /// Delta Z (Meter).
  double dz;

  /// Rotation X (seconds).
  double rx;

  /// Rotation Y (seconds).
  double ry;

  /// Rotation Z (seconds).
  double rz;

  /// Scale (ppm).
  double scale;

  /// Cartesian Center X (Meter).
  double xm;

  /// Cartesian Center Y (Meter).
  double ym;

  /// Cartesian Center Z (Meter).
  double zm;

  /// Initializes transformation parameters with default values (all zeros).
  TransformationParameters()
      : dx = 0,
        dy = 0,
        dz = 0,
        rx = 0,
        ry = 0,
        rz = 0,
        scale = 0,
        xm = 0,
        ym = 0,
        zm = 0;

  /// Initializes transformation parameters with specified values.
  TransformationParameters.withValues(
    this.dx,
    this.dy,
    this.dz,
    this.rx,
    this.ry,
    this.rz,
    this.scale,
    this.xm,
    this.ym,
    this.zm,
  );

  /// Get 1 by 10 Matrix of the transformation parameters.
  List<double> getValues() {
    return [dx, dy, dz, rx, ry, rz, scale, xm, ym, zm];
  }

  /// Set transformation Parameters from a list.
  void setTransParams(List<double> params) {
    if (params.length != 10) {
      throw ArgumentError('TransParams must contain exactly 10 values');
    }
    dx = params[0];
    dy = params[1];
    dz = params[2];
    rx = params[3];
    ry = params[4];
    rz = params[5];
    scale = params[6];
    xm = params[7];
    ym = params[8];
    zm = params[9];
  }

  /// Ghana Default 10 transformation parameters.
  static TransformationParameters gh10TransParams() {
    return TransformationParameters.withValues(
      -196.557,
      33.385,
      322.452,
      0.0368,
      -0.00799,
      -0.0119,
      -6,
      6339239.29,
      -120750.511,
      686012.361,
    );
  }

  /// Ghana Default 7 transformation parameters.
  static TransformationParameters gh7TransParams() {
    return TransformationParameters.withValues(
      -158.635,
      32.174,
      326.783,
      0.0368,
      -0.00799,
      -0.0119,
      -7.6,
      0,
      0,
      0,
    );
  }

  /// Ghana Default 3 transformation parameters.
  static TransformationParameters gh3TransParams() {
    return TransformationParameters.withValues(
      -196.58,
      33.383,
      322.552,
      0,
      0,
      0,
      0,
      0,
      0,
      0,
    );
  }

  @override
  String toString() {
    return 'TransformationParameters(dx: $dx, dy: $dy, dz: $dz, '
        'rx: $rx, ry: $ry, rz: $rz, scale: $scale, '
        'xm: $xm, ym: $ym, zm: $zm)';
  }
}
