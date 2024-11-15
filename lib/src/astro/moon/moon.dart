// ignore_for_file: avoid_init_to_null

part of '../astronomy.dart';

class Moon {
  late AstroTime date;
  late double geo_eclip_lon;
  late double geo_eclip_lat;
  late double distance_au;

  // ignore: avoid_init_to_null
  Moon([dynamic date = null]) {
    this.date = AstroTime(date ?? DateTime.now());
    final m = _calcMoon(this.date);
    geo_eclip_lon = m["geo_eclip_lon"]!;
    geo_eclip_lat = m["geo_eclip_lat"]!;
    distance_au = m["distance_au"]!;
  }

  static Map<String, double> _calcMoon(AstroTime time) {
    calcMoonCount++;

    double T = time.tt / 36525;

    PascalArray1 declareArray1(int xmin, int xmax) {
      List<double> array = [];
      for (int i = 0; i <= xmax - xmin; ++i) {
        array.add(0);
      }
      return PascalArray1(min: xmin, array: array);
    }

    PascalArray2 declareArray2(int xmin, int xmax, int ymin, int ymax) {
      List<PascalArray1> array = [];
      for (int i = 0; i <= xmax - xmin; ++i) {
        array.add(declareArray1(ymin, ymax));
      }
      return PascalArray2(min: xmin, array: array);
    }

    double arrayGet2(PascalArray2 a, int x, int y) {
      PascalArray1 m = a.array[x - a.min];
      return m.array[y - m.min];
    }

    void arraySet2(PascalArray2 a, int x, int y, double v) {
      PascalArray1 m = a.array[x - a.min];

      m.array[y - m.min] = v;
    }

    double S,
        MAX,
        ARG,
        FAC,
        I,
        J,
        T2,
        DGAM,
        DLAM,
        N,
        GAM1C,
        SINPI,
        L0,
        L,
        LS,
        F,
        D,
        DL0,
        DL,
        DLS,
        DF,
        DD,
        DS;
    PascalArray2 coArray = declareArray2(-6, 6, 1, 4);
    PascalArray2 siArray = declareArray2(-6, 6, 1, 4);

    double CO(int x, int y) {
      return arrayGet2(coArray, x, y);
    }

    double SI(int x, int y) {
      return arrayGet2(siArray, x, y);
    }

    void SetCO(int x, int y, double v) {
      arraySet2(coArray, x, y, v);
    }

    void SetSI(int x, int y, double v) {
      arraySet2(siArray, x, y, v);
    }

    void AddThe(double c1, double s1, double c2, double s2, ThetaFunc func) {
      func(c1 * c2 - s1 * s2, s1 * c2 + c1 * s2);
    }

    double Sine(double phi) {
      return sin(PI2 * phi);
    }

    T2 = (T * T);
    DLAM = 0;
    DS = 0;
    GAM1C = 0;
    SINPI = 3422.7000;

    var S1 = Sine(0.19833 + 0.05611 * T);
    var S2 = Sine(0.27869 + 0.04508 * T);
    var S3 = Sine(0.16827 - 0.36903 * T);
    var S4 = Sine(0.34734 - 5.37261 * T);
    var S5 = Sine(0.10498 - 5.37899 * T);
    var S6 = Sine(0.42681 - 0.41855 * T);
    var S7 = Sine(0.14943 - 5.37511 * T);

    DL0 =
        0.84 * S1 + 0.31 * S2 + 14.27 * S3 + 7.26 * S4 + 0.28 * S5 + 0.24 * S6;
    DL = 2.94 * S1 + 0.31 * S2 + 14.27 * S3 + 9.34 * S4 + 1.12 * S5 + 0.83 * S6;
    DLS = -6.40 * S1 - 1.89 * S6;
    DF = 0.21 * S1 +
        0.31 * S2 +
        14.27 * S3 -
        88.70 * S4 -
        15.30 * S5 +
        0.24 * S6 -
        1.86 * S7;
    DD = DL0 - DLS;
    DGAM = (-3332E-9 * Sine(0.59734 - 5.37261 * T) -
        539E-9 * Sine(0.35498 - 5.37899 * T) -
        64E-9 * Sine(0.39943 - 5.37511 * T));

    L0 = PI2 * frac(0.60643382 + 1336.85522467 * T - 0.00000313 * T2) +
        DL0 / ARC;
    L = PI2 * frac(0.37489701 + 1325.55240982 * T + 0.00002565 * T2) + DL / ARC;
    LS = PI2 * frac(0.99312619 + 99.99735956 * T - 0.00000044 * T2) + DLS / ARC;
    F = PI2 * frac(0.25909118 + 1342.22782980 * T - 0.00000892 * T2) + DF / ARC;
    D = PI2 * frac(0.82736186 + 1236.85308708 * T - 0.00000397 * T2) + DD / ARC;

    for (int I = 1; I <= 4; ++I) {
      switch (I) {
        case 1:
          ARG = L;
          MAX = 4;
          FAC = 1.000002208;
          break;
        case 2:
          ARG = LS;
          MAX = 3;
          FAC = 0.997504612 - 0.002495388 * T;
          break;
        case 3:
          ARG = F;
          MAX = 4;
          FAC = 1.000002708 + 139.978 * DGAM;
          break;
        case 4:
          ARG = D;
          MAX = 6;
          FAC = 1.0;
          break;
        default:
          throw 'Internal error: I = $I';
      }
      SetCO(0, I, 1);
      SetCO(1, I, cos(ARG) * FAC);
      SetSI(0, I, 0);
      SetSI(1, I, sin(ARG) * FAC);
      for (int J = 2; J <= MAX; ++J) {
        AddThe(CO(J - 1, I), SI(J - 1, I), CO(1, I), SI(1, I), (c, s) {
          SetCO(J, I, c);
          SetSI(J, I, s);
        });
      }
      for (int J = 1; J <= MAX; ++J) {
        SetCO(-J, I, CO(J, I));
        SetSI(-J, I, -SI(J, I));
      }
    }

    // Function to compute Term
    ComplexValue Term(int p, int q, int r, int s) {
      var result = ComplexValue(1, 0);
      var I = [0, p, q, r, s]; // I[0] is not used; it is a placeholder
      for (var k = 1; k <= 4; ++k) {
        if (I[k] != 0) {
          AddThe(result.x, result.y, CO(I[k], k), SI(I[k], k), (c, s) {
            result.x = c;
            result.y = s;
          });
        }
      }
      return result;
    }

// Function to add solutions
    void AddSol(double coeffl, double coeffs, double coeffg, double coeffp,
        int p, int q, int r, int s) {
      var result = Term(p, q, r, s);
      DLAM += coeffl * result.y;
      DS += coeffs * result.y;
      GAM1C += coeffg * result.x;
      SINPI += coeffp * result.x;
    }

    AddSol(13.9020, 14.0600, -0.0010, 0.2607, 0, 0, 0, 4);
    AddSol(0.4030, -4.0100, 0.3940, 0.0023, 0, 0, 0, 3);
    AddSol(2369.9120, 2373.3600, 0.6010, 28.2333, 0, 0, 0, 2);
    AddSol(-125.1540, -112.7900, -0.7250, -0.9781, 0, 0, 0, 1);
    AddSol(1.9790, 6.9800, -0.4450, 0.0433, 1, 0, 0, 4);
    AddSol(191.9530, 192.7200, 0.0290, 3.0861, 1, 0, 0, 2);
    AddSol(-8.4660, -13.5100, 0.4550, -0.1093, 1, 0, 0, 1);
    AddSol(22639.5000, 22609.0700, 0.0790, 186.5398, 1, 0, 0, 0);
    AddSol(18.6090, 3.5900, -0.0940, 0.0118, 1, 0, 0, -1);
    AddSol(-4586.4650, -4578.1300, -0.0770, 34.3117, 1, 0, 0, -2);
    AddSol(3.2150, 5.4400, 0.1920, -0.0386, 1, 0, 0, -3);
    AddSol(-38.4280, -38.6400, 0.0010, 0.6008, 1, 0, 0, -4);
    AddSol(-0.3930, -1.4300, -0.0920, 0.0086, 1, 0, 0, -6);
    AddSol(-0.2890, -1.5900, 0.1230, -0.0053, 0, 1, 0, 4);
    AddSol(-24.4200, -25.1000, 0.0400, -0.3000, 0, 1, 0, 2);
    AddSol(18.0230, 17.9300, 0.0070, 0.1494, 0, 1, 0, 1);
    AddSol(-668.1460, -126.9800, -1.3020, -0.3997, 0, 1, 0, 0);
    AddSol(0.5600, 0.3200, -0.0010, -0.0037, 0, 1, 0, -1);
    AddSol(-165.1450, -165.0600, 0.0540, 1.9178, 0, 1, 0, -2);
    AddSol(-1.8770, -6.4600, -0.4160, 0.0339, 0, 1, 0, -4);
    AddSol(0.2130, 1.0200, -0.0740, 0.0054, 2, 0, 0, 4);
    AddSol(14.3870, 14.7800, -0.0170, 0.2833, 2, 0, 0, 2);
    AddSol(-0.5860, -1.2000, 0.0540, -0.0100, 2, 0, 0, 1);
    AddSol(769.0160, 767.9600, 0.1070, 10.1657, 2, 0, 0, 0);
    AddSol(1.7500, 2.0100, -0.0180, 0.0155, 2, 0, 0, -1);
    AddSol(-211.6560, -152.5300, 5.6790, -0.3039, 2, 0, 0, -2);
    AddSol(1.2250, 0.9100, -0.0300, -0.0088, 2, 0, 0, -3);
    AddSol(-30.7730, -34.0700, -0.3080, 0.3722, 2, 0, 0, -4);
    AddSol(-0.5700, -1.4000, -0.0740, 0.0109, 2, 0, 0, -6);
    AddSol(-2.9210, -11.7500, 0.7870, -0.0484, 1, 1, 0, 2);
    AddSol(1.2670, 1.5200, -0.0220, 0.0164, 1, 1, 0, 1);
    AddSol(-109.6730, -115.1800, 0.4610, -0.9490, 1, 1, 0, 0);
    AddSol(-205.9620, -182.3600, 2.0560, 1.4437, 1, 1, 0, -2);
    AddSol(0.2330, 0.3600, 0.0120, -0.0025, 1, 1, 0, -3);
    AddSol(-4.3910, -9.6600, -0.4710, 0.0673, 1, 1, 0, -4);
    AddSol(0.2830, 1.5300, -0.1110, 0.0060, 1, -1, 0, 4);
    AddSol(14.5770, 31.7000, -1.5400, 0.2302, 1, -1, 0, 2);
    AddSol(147.6870, 138.7600, 0.6790, 1.1528, 1, -1, 0, 0);
    AddSol(-1.0890, 0.5500, 0.0210, 0.0000, 1, -1, 0, -1);
    AddSol(28.4750, 23.5900, -0.4430, -0.2257, 1, -1, 0, -2);
    AddSol(-0.2760, -0.3800, -0.0060, -0.0036, 1, -1, 0, -3);
    AddSol(0.6360, 2.2700, 0.1460, -0.0102, 1, -1, 0, -4);
    AddSol(-0.1890, -1.6800, 0.1310, -0.0028, 0, 2, 0, 2);
    AddSol(-7.4860, -0.6600, -0.0370, -0.0086, 0, 2, 0, 0);
    AddSol(-8.0960, -16.3500, -0.7400, 0.0918, 0, 2, 0, -2);
    AddSol(-5.7410, -0.0400, 0.0000, -0.0009, 0, 0, 2, 2);
    AddSol(0.2550, 0.0000, 0.0000, 0.0000, 0, 0, 2, 1);
    AddSol(-411.6080, -0.2000, 0.0000, -0.0124, 0, 0, 2, 0);
    AddSol(0.5840, 0.8400, 0.0000, 0.0071, 0, 0, 2, -1);
    AddSol(-55.1730, -52.1400, 0.0000, -0.1052, 0, 0, 2, -2);
    AddSol(0.2540, 0.2500, 0.0000, -0.0017, 0, 0, 2, -3);
    AddSol(0.0250, -1.6700, 0.0000, 0.0031, 0, 0, 2, -4);
    AddSol(1.0600, 2.9600, -0.1660, 0.0243, 3, 0, 0, 2);
    AddSol(36.1240, 50.6400, -1.3000, 0.6215, 3, 0, 0, 0);
    AddSol(-13.1930, -16.4000, 0.2580, -0.1187, 3, 0, 0, -2);
    AddSol(-1.1870, -0.7400, 0.0420, 0.0074, 3, 0, 0, -4);
    AddSol(-0.2930, -0.3100, -0.0020, 0.0046, 3, 0, 0, -6);
    AddSol(-0.2900, -1.4500, 0.1160, -0.0051, 2, 1, 0, 2);
    AddSol(-7.6490, -10.5600, 0.2590, -0.1038, 2, 1, 0, 0);
    AddSol(-8.6270, -7.5900, 0.0780, -0.0192, 2, 1, 0, -2);
    AddSol(-2.7400, -2.5400, 0.0220, 0.0324, 2, 1, 0, -4);
    AddSol(1.1810, 3.3200, -0.2120, 0.0213, 2, -1, 0, 2);
    AddSol(9.7030, 11.6700, -0.1510, 0.1268, 2, -1, 0, 0);
    AddSol(-0.3520, -0.3700, 0.0010, -0.0028, 2, -1, 0, -1);
    AddSol(-2.4940, -1.1700, -0.0030, -0.0017, 2, -1, 0, -2);
    AddSol(0.3600, 0.2000, -0.0120, -0.0043, 2, -1, 0, -4);
    AddSol(-1.1670, -1.2500, 0.0080, -0.0106, 1, 2, 0, 0);
    AddSol(-7.4120, -6.1200, 0.1170, 0.0484, 1, 2, 0, -2);
    AddSol(-0.3110, -0.6500, -0.0320, 0.0044, 1, 2, 0, -4);
    AddSol(0.7570, 1.8200, -0.1050, 0.0112, 1, -2, 0, 2);
    AddSol(2.5800, 2.3200, 0.0270, 0.0196, 1, -2, 0, 0);
    AddSol(2.5330, 2.4000, -0.0140, -0.0212, 1, -2, 0, -2);
    AddSol(-0.3440, -0.5700, -0.0250, 0.0036, 0, 3, 0, -2);
    AddSol(-0.9920, -0.0200, 0.0000, 0.0000, 1, 0, 2, 2);
    AddSol(-45.0990, -0.0200, 0.0000, -0.0010, 1, 0, 2, 0);
    AddSol(-0.1790, -9.5200, 0.0000, -0.0833, 1, 0, 2, -2);
    AddSol(-0.3010, -0.3300, 0.0000, 0.0014, 1, 0, 2, -4);
    AddSol(-6.3820, -3.3700, 0.0000, -0.0481, 1, 0, -2, 2);
    AddSol(39.5280, 85.1300, 0.0000, -0.7136, 1, 0, -2, 0);
    AddSol(9.3660, 0.7100, 0.0000, -0.0112, 1, 0, -2, -2);
    AddSol(0.2020, 0.0200, 0.0000, 0.0000, 1, 0, -2, -4);
    AddSol(0.4150, 0.1000, 0.0000, 0.0013, 0, 1, 2, 0);
    AddSol(-2.1520, -2.2600, 0.0000, -0.0066, 0, 1, 2, -2);
    AddSol(-1.4400, -1.3000, 0.0000, 0.0014, 0, 1, -2, 2);
    AddSol(0.3840, -0.0400, 0.0000, 0.0000, 0, 1, -2, -2);
    AddSol(1.9380, 3.6000, -0.1450, 0.0401, 4, 0, 0, 0);
    AddSol(-0.9520, -1.5800, 0.0520, -0.0130, 4, 0, 0, -2);
    AddSol(-0.5510, -0.9400, 0.0320, -0.0097, 3, 1, 0, 0);
    AddSol(-0.4820, -0.5700, 0.0050, -0.0045, 3, 1, 0, -2);
    AddSol(0.6810, 0.9600, -0.0260, 0.0115, 3, -1, 0, 0);
    AddSol(-0.2970, -0.2700, 0.0020, -0.0009, 2, 2, 0, -2);
    AddSol(0.2540, 0.2100, -0.0030, 0.0000, 2, -2, 0, -2);
    AddSol(-0.2500, -0.2200, 0.0040, 0.0014, 1, 3, 0, -2);
    AddSol(-3.9960, 0.0000, 0.0000, 0.0004, 2, 0, 2, 0);
    AddSol(0.5570, -0.7500, 0.0000, -0.0090, 2, 0, 2, -2);
    AddSol(-0.4590, -0.3800, 0.0000, -0.0053, 2, 0, -2, 2);
    AddSol(-1.2980, 0.7400, 0.0000, 0.0004, 2, 0, -2, 0);
    AddSol(0.5380, 1.1400, 0.0000, -0.0141, 2, 0, -2, -2);
    AddSol(0.2630, 0.0200, 0.0000, 0.0000, 1, 1, 2, 0);
    AddSol(0.4260, 0.0700, 0.0000, -0.0006, 1, 1, -2, -2);
    AddSol(-0.3040, 0.0300, 0.0000, 0.0003, 1, -1, 2, 0);
    AddSol(-0.3720, -0.1900, 0.0000, -0.0027, 1, -1, -2, 2);
    AddSol(0.4180, 0.0000, 0.0000, 0.0000, 0, 0, 4, 0);
    AddSol(-0.3300, -0.0400, 0.0000, 0.0000, 3, 0, 2, 0);

    // Function to compute and return the sum of a coefficient multiplied by the imaginary part of a term
    double ADDN(double coeffn, int p, int q, int r, int s) {
      return coeffn * Term(p, q, r, s).y;
    }

    // Calculating N by summing up coefficients multiplied by the imaginary parts of terms
    N = 0;
    N += ADDN(-526.069, 0, 0, 1, -2);
    N += ADDN(-3.352, 0, 0, 1, -4);
    N += ADDN(44.297, 1, 0, 1, -2);
    N += ADDN(-6.000, 1, 0, 1, -4);
    N += ADDN(20.599, -1, 0, 1, 0);
    N += ADDN(-30.598, -1, 0, 1, -2);
    N += ADDN(-24.649, -2, 0, 1, 0);
    N += ADDN(-2.000, -2, 0, 1, -2);
    N += ADDN(-22.571, 0, 1, 1, -2);
    N += ADDN(10.985, 0, -1, 1, -2);

    DLAM += (0.82 * Sine(0.7736 - 62.5512 * T) +
        0.31 * Sine(0.0466 - 125.1025 * T) +
        0.35 * Sine(0.5785 - 25.1042 * T) +
        0.66 * Sine(0.4591 + 1335.8075 * T) +
        0.64 * Sine(0.3130 - 91.5680 * T) +
        1.14 * Sine(0.1480 + 1331.2898 * T) +
        0.21 * Sine(0.5918 + 1056.5859 * T) +
        0.44 * Sine(0.5784 + 1322.8595 * T) +
        0.24 * Sine(0.2275 - 5.7374 * T) +
        0.28 * Sine(0.2965 + 2.6929 * T) +
        0.33 * Sine(0.3132 + 6.3368 * T));

    S = F + DS / ARC;

    final latSeconds =
        (1.000002708 + 139.978 * DGAM) * (18518.511 + 1.189 * GAM1C) * sin(S) -
            6.24 * sin(3 * S) +
            N;

    return {
      "geo_eclip_lon": PI2 * frac((L0 + DLAM / ARC) / PI2),
      "geo_eclip_lat": (pi / (180 * 3600)) * latSeconds,
      "distance_au": (ARC * EARTH_EQUATORIAL_RADIUS_AU) / (0.999953253 * SINPI),
    };
  }

  double moonEclipticLatitudeDegrees() {
    return RAD2DEG * geo_eclip_lat;
  }

  /// Calculate the Moon's ecliptic phase angle,
  /// which ranges from 0 to 360 degrees.
  ///   0 degrees = new moon,
  ///  90 degrees = first quarter,
  /// 180 degrees = full moon,
  /// 270 degrees = third quarter.
  ({double phaseAngle, String phaseName}) moonPhase() {
    var phase = pairLongitude(Body.Moon, Body.Sun, date);

    return (phaseAngle: phase, phaseName: 'phaseName');
  }

  /// Calculate the fraction of the Moon's disc
  /// that appears illuminated, as seen from the Earth.
  IlluminationInfo illumination() {
    return IlluminationInfo.getBodyIllumination(Body.Moon, date);
  }

  /// A quarter lunar phase, along with when it occurs.
  ///
  /// @property {number} quarter
  ///      An integer as follows:
  ///      0 = new moon,
  ///      1 = first quarter,
  ///      2 = full moon,
  ///      3 = third quarter.
  ///
  /// @property {String} quarterNAme
  ///
  /// @property {AstroTime} time
  ///      The date and time of the quarter lunar phase.
  MoonQuarter moonQuarter() {
    return MoonQuarter.searchMoonQuarter(date);
  }

  /// Calculate the next Moon quarters
  /// and return a list of them.
  ///
  /// The default is to return the next 4 quarters.
  List<MoonQuarter> nextMoonQuarter([int nextCounts = 4]) {
    List<MoonQuarter> moonQuarters = [];
    MoonQuarter mq = moonQuarter();
    for (var i = 0; i < nextCounts; ++i) {
      // Use the previous moon quarter information to find the next quarter phase event.
      mq = MoonQuarter.nextMoonQuarter(mq);
      moonQuarters.add(mq);
      //print('${formatDate(mq.time.date)} : ${quarterName[mq.quarter]}');
    }

    return moonQuarters;
  }

  /// Finds the next perigee or apogee of the Moon.
  ///
  /// Finds the next perigee (closest approach) or apogee (farthest remove) of the Moon
  /// that occurs after the specified date and time.
  ///
  /// @param {FlexibleDateTime} startDate
  ///      The date and time after which to find the next perigee or apogee.
  ///
  /// @returns {Apsis}
  Apsis searchLunarApsis([dynamic startDate = null]) {
    const dt = 0.001;
    final time = AstroTime(startDate ?? date);

    double distanceSlope(AstroTime t) {
      AstroTime t1 = t.addDays(-dt / 2);
      AstroTime t2 = t.addDays(dt / 2);

      double r1 = Moon(t1).distance_au;
      double r2 = Moon(t2).distance_au;

      return (r2 - r1) / dt;
    }

    double negativeDistanceSlope(AstroTime t) => -distanceSlope(t);

    // Check the rate of change of the distance dr/dt at the start time.
    // If it is positive, the Moon is currently getting farther away,
    // so start looking for apogee.
    // Conversely, if dr/dt < 0, start looking for perigee.
    // Either way, the polarity of the slope will change, so the product will be negative.
    // Handle the crazy corner case of exactly touching zero by checking for m1*m2 <= 0.

    AstroTime t1 = AstroTime(time);
    double m1 = distanceSlope(t1);
    const increment = 5.0; // Number of days to skip in each iteration

    for (var iter = 0; iter * increment < 2 * MEAN_SYNODIC_MONTH; ++iter) {
      AstroTime t2 = t1.addDays(increment);
      double m2 = distanceSlope(t2);

      if (m1 * m2 <= 0) {
        // Time range [t1, t2] contains an apsis
        if (m1 < 0 || m2 > 0) {
          // Perigee search
          AstroTime? tx = search(distanceSlope, t1, t2,
              options: SearchOptions(initF1: m1, initF2: m2));

          if (tx == null) {
            throw 'SearchLunarApsis INTERNAL ERROR: perigee search failed!';
          }
          double dist = Moon(tx).distance_au;
          return Apsis(tx, ApsisKind.Pericenter, dist);
        }

        if (m1 > 0 || m2 < 0) {
          // Apogee search
          AstroTime? tx = search(negativeDistanceSlope, t1, t2,
              options: SearchOptions(initF1: -m1, initF2: -m2));

          if (tx == null) {
            throw 'SearchLunarApsis INTERNAL ERROR: apogee search failed!';
          }
          double dist = Moon(tx).distance_au;
          return Apsis(tx, ApsisKind.Apocenter, dist);
        }

        // This should never happen
        throw 'SearchLunarApsis INTERNAL ERROR: cannot classify apsis event!';
      }

      t1 = t2;
      m1 = m2;
    }

    // It should not be possible to fail to find an apsis within 2 synodic months
    throw 'SearchLunarApsis INTERNAL ERROR: could not find apsis within 2 synodic months of start date.';
  }

  /// @brief Finds the next lunar apsis (perigee or apogee) in a series.
  ///
  /// Given a lunar apsis returned by an initial call to {@link SearchLunarApsis},
  /// or a previous call to `NextLunarApsis`, finds the next lunar apsis.
  /// If the given apsis is a perigee, this function finds the next apogee, and vice versa.
  ///
  /// @param {Apsis} apsis
  ///      A lunar perigee or apogee event.
  ///
  /// @returns {Apsis}
  ///      The successor apogee for the given perigee, or the successor perigee for the given apogee.
  Apsis nextLunarApsis([Apsis? apsis]) {
    apsis ??= searchLunarApsis();
    const skip =
        11.0; // Number of days to skip to start looking for the next apsis event
    var next = searchLunarApsis(apsis.time.addDays(skip));

    // Check if the kind of the next apsis event alternates with the kind of the current apsis event
    if ((next.kind.index + apsis.kind.index) != 1) {
      throw 'NextLunarApsis INTERNAL ERROR: did not find alternating apogee/perigee: '
          'prev=${apsis.kind} @ ${apsis.time.toString()}, next=${next.kind} @ ${next.time.toString()}';
    }

    return next;
  }

  /// @brief Calculates equatorial geocentric Cartesian coordinates for the Moon.
  ///
  /// Given a time of observation, calculates the Moon's position as a vector.
  /// The vector gives the location of the Moon's center relative to the Earth's center
  /// with x-, y-, and z-components measured in astronomical units.
  /// The coordinates are oriented with respect to the Earth's equator at the J2000 epoch.
  /// In Astronomy Engine, this orientation is called EQJ.
  /// Based on the Nautical Almanac Office's <i>Improved Lunar Ephemeris</i> of 1954,
  /// which in turn derives from E. W. Brown's lunar theories.
  /// Adapted from Turbo Pascal code from the book
  /// <a href="https://www.springer.com/us/book/9783540672210">Astronomy on the Personal Computer</a>
  /// by Montenbruck and Pfleger.
  ///
  /// @param {FlexibleDateTime} date
  ///      The date and time for which to calculate the Moon's geocentric position.
  ///
  /// @returns {Vector}
  AstroVector geoMoon() {
    // Convert geocentric ecliptic spherical coords to cartesian coords.
    final distCosLat = distance_au * cos(geo_eclip_lat);
    final gepos = [
      distCosLat * cos(geo_eclip_lon),
      distCosLat * sin(geo_eclip_lon),
      distance_au * sin(geo_eclip_lat)
    ];

    // Convert ecliptic coordinates to equatorial coordinates, both in mean equinox of date.
    final mpos1 = ecl2equVec(date, gepos);

    // Convert from mean equinox of date to J2000...
    final mpos2 = precession(mpos1, date, PrecessDirection.Into2000);

    return AstroVector(mpos2[0], mpos2[1], mpos2[2], date);
  }

  /// @brief Calculates equatorial geocentric position and velocity of the Moon at a given time.
  ///
  /// Given a time of observation, calculates the Moon's position and velocity vectors.
  /// The position and velocity are of the Moon's center relative to the Earth's center.
  /// The position (x, y, z) components are expressed in AU (astronomical units).
  /// The velocity (vx, vy, vz) components are expressed in AU/day.
  /// The coordinates are oriented with respect to the Earth's equator at the J2000 epoch.
  /// In Astronomy Engine, this orientation is called EQJ.
  /// If you need the Moon's position only, and not its velocity,
  /// it is much more efficient to use {@link GeoMoon} instead.
  ///
  /// @param {FlexibleDateTime} date
  ///      The date and time for which to calculate the Moon's geocentric state.
  ///
  /// @returns {StateVector}
  static StateVector geoMoonState(dynamic date) {
    final time = AstroTime(date);
    final dt = 1.0e-5; // 0.864 seconds

    final t1 = date; // Replace with actual date calculation: time.AddDays(-dt);
    final t2 = date; // Replace with actual date calculation: time.AddDays(+dt);
    final r1 = Moon(t1).geoMoon();
    final r2 = Moon(t2).geoMoon();

    return StateVector(
      (r1.x + r2.x) / 2,
      (r1.y + r2.y) / 2,
      (r1.z + r2.z) / 2,
      (r2.x - r1.x) / (2 * dt),
      (r2.y - r1.y) / (2 * dt),
      (r2.z - r1.z) / (2 * dt),
      time,
    );
  }

  /// @brief Calculates the geocentric position and velocity of the Earth/Moon barycenter.
  ///
  /// Given a time of observation, calculates the geocentric position and velocity vectors
  /// of the Earth/Moon barycenter (EMB).
  /// The position (x, y, z) components are expressed in AU (astronomical units).
  /// The velocity (vx, vy, vz) components are expressed in AU/day.
  ///
  /// @param {FlexibleDateTime} date
  ///      The date and time for which to calculate the EMB's geocentric state.
  ///
  /// @returns {StateVector}
  static StateVector geoEmbState(dynamic date) {
    final s = geoMoonState(date);
    final d = 1.0 + EARTH_MOON_MASS_RATIO;
    return StateVector(
        s.x / d, s.y / d, s.z / d, s.vx / d, s.vy / d, s.vz / d, s.t);
  }
}
