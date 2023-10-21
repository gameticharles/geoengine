part of geoengine;

/// Multiple Regression Equation Params
class MultipleRegressionEquationParams {
  double a00 = 0.0;
  double a10 = 0.0;
  double a01 = 0.0;
  double a20 = 0.0;
  double a11 = 0.0;
  double a02 = 0.0;
  double a30 = 0.0;
  double a21 = 0.0;
  double a12 = 0.0;
  double a03 = 0.0;

  double b00 = 0.0;
  double b10 = 0.0;
  double b01 = 0.0;
  double b20 = 0.0;
  double b11 = 0.0;
  double b02 = 0.0;
  double b30 = 0.0;
  double b21 = 0.0;
  double b12 = 0.0;
  double b03 = 0.0;

  /// Init MRE parameters
  MultipleRegressionEquationParams();

  /// Get 1 by 20 Matrix of the MRE parameters
  List<double> getValues() {
    return [
      a00,
      a10,
      a01,
      a20,
      a11,
      a02,
      a30,
      a21,
      a12,
      a03,
      b00,
      b10,
      b01,
      b20,
      b11,
      b02,
      b30,
      b21,
      b12,
      b03,
    ];
  }

  /// Set MRE parsing matrix containing values
  void setMREParams(List<double> MREParams) {
    if (MREParams.length != 20) {
      throw ArgumentError("MREParams must have exactly 20 elements.");
    }

    a00 = MREParams[0];
    a10 = MREParams[1];
    a01 = MREParams[2];
    a20 = MREParams[3];
    a11 = MREParams[4];
    a02 = MREParams[5];
    a30 = MREParams[6];
    a21 = MREParams[7];
    a12 = MREParams[8];
    a03 = MREParams[9];

    b00 = MREParams[10];
    b10 = MREParams[11];
    b01 = MREParams[12];
    b20 = MREParams[13];
    b11 = MREParams[14];
    b02 = MREParams[15];
    b30 = MREParams[16];
    b21 = MREParams[17];
    b12 = MREParams[18];
    b03 = MREParams[19];
  }

  /// Set MRE parsing all individual values
  void setMREParamsIndividual(
      double a00,
      double a10,
      double a01,
      double a20,
      double a11,
      double a02,
      double a30,
      double a21,
      double a12,
      double a03,
      double b00,
      double b10,
      double b01,
      double b20,
      double b11,
      double b02,
      double b30,
      double b21,
      double b12,
      double b03) {
    a00 = a00;
    a10 = a10;
    a01 = a01;
    a20 = a20;
    a11 = a11;
    a02 = a02;
    a30 = a30;
    a21 = a21;
    a12 = a12;
    a03 = a03;

    b00 = b00;
    b10 = b10;
    b01 = b01;
    b20 = b20;
    b11 = b11;
    b02 = b02;
    b30 = b30;
    b21 = b21;
    b12 = b12;
    b03 = b03;
  }

  /// Ghana Default MRE
  MultipleRegressionEquationParams ghMREParams() {
    setMREParamsIndividual(
      -0.0027329,
      0.00048783,
      0.000011079,
      0.000089722,
      0.000032158,
      0.0000066774,
      -0.000068005,
      0.000013419,
      0.000021219,
      -0.000033315,
      -0.00025597,
      0.000001395,
      -0.00060172,
      0.0000020015,
      -0.000029319,
      -0.0000039382,
      0.0000041771,
      -0.000022493,
      -0.000033315,
      0.000021523,
    );

    return this;
  }
}
