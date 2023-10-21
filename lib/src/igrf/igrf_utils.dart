import 'dart:io';
import 'dart:core';

import '../../geoengine.dart';

class IGRF {
  late List<double> time;
  late List<List<double>> coeffs;
  late Map<String, dynamic> parameters;

  IGRF({required this.time, required this.coeffs, required this.parameters});
}

int checkInt(String s) {
  try {
    return int.parse(s);
  } catch (e) {
    throw Exception('Could not convert $s to integer.');
  }
}

double checkFloat(String s) {
  try {
    return double.parse(s);
  } catch (e) {
    throw Exception('Could not convert $s to float.');
  }
}

List<List<double>> synthValues(List<double> coeffs, List<double> radius,
    List<double> theta, List<double> phi,
    {int? nmax, int? nmin, bool? grid}) {
  nmin = nmin ?? 1;
  if (nmin <= 0) {
    throw Exception('Only positive nmin allowed.');
  }

  int nmaxCoeffs = (sqrt(coeffs.length + 1) - 1).toInt();
  nmax = nmax ?? nmaxCoeffs;

  if (nmax <= 0) {
    throw Exception('Only positive nmax allowed.');
  }

  if (nmax > nmaxCoeffs) {
    print(
        'Warning: Supplied nmax = $nmax and nmin = $nmin is incompatible with number of model coefficients. Using nmax = $nmaxCoeffs instead.');
    nmax = nmaxCoeffs;
  }

  if (nmax < nmin) {
    throw Exception('Nothing to compute: nmax < nmin ($nmax < $nmin).');
  }

  grid = grid ?? false;

  if (grid) {
    theta = [...theta, 0]; // append zero
    phi = [0, ...phi]; // prepend zero
  }

  List<double> rN =
      List.filled(radius.length, pow(radius[0] / 6371.2, -(nmin + 2)));

  List<List<double>> Pnm = legendrePoly(nmax, theta);

  List<double> sinth = List.filled(Pnm[0].length, Pnm[1][1]);

  phi = phi.map((p) => toRadians(p)).toList();
  List<List<dynamic>> cmp = [];
  List<List<dynamic>> smp = [];

  for (var m = 0; m <= nmax; m++) {
    cmp.add(phi.map((p) => cos(m * p)).toList());
    smp.add(phi.map((p) => sin(m * p)).toList());
  }

  List<double> BRadius = List.filled(radius.length, 0.0);
  List<double> BTheta = List.filled(theta.length, 0.0);
  List<double> BPhi = List.filled(phi.length, 0.0);

  int num = pow(nmin, 2).toInt() - 1;

  for (var n = nmin; n <= nmax; n++) {
    for (var i = 0; i < radius.length; i++) {
      BRadius[i] += (n + 1) * Pnm[n][0] * rN[i] * coeffs[num];
    }

    for (var i = 0; i < theta.length; i++) {
      BTheta[i] += -Pnm[0][n + 1] * rN[i] * coeffs[num];
    }

    num++;

    for (var m = 1; m <= n; m++) {
      for (var i = 0; i < radius.length; i++) {
        BRadius[i] += (n + 1) *
            Pnm[n][m] *
            rN[i] *
            (coeffs[num] * cmp[m][i] + coeffs[num + 1] * smp[m][i]);
        BTheta[i] += -Pnm[m][n + 1] *
            rN[i] *
            (coeffs[num] * cmp[m][i] + coeffs[num + 1] * smp[m][i]);

        double divPnm;
        if (theta[i] == 0.0) {
          divPnm = Pnm[m][n + 1];
        } else if (theta[i] == 180.0) {
          divPnm = -Pnm[m][n + 1];
        } else {
          divPnm = Pnm[n][m] / sinth[i];
        }

        BPhi[i] += m *
            divPnm *
            rN[i] *
            (coeffs[num] * smp[m][i] - coeffs[num + 1] * cmp[m][i]);
      }

      num += 2;
    }

    for (var i = 0; i < rN.length; i++) {
      rN[i] = rN[i] / radius[i];
    }
  }

  return [BRadius, BTheta, BPhi];
}

List<List<double>> legendrePoly(int nmax, List<double> theta) {
  var costh = theta.map((t) => cos(toRadians(t))).toList();
  var sinth = costh.map((cth) => sqrt(1 - pow(cth, 2))).toList();

  List<List<double>> Pnm =
      List.generate(nmax + 1, (i) => List.filled(nmax + 2, 0.0));
  Pnm[0][0] = 1.0;
  Pnm[1][1] = sinth[0];

  var rootn = List.generate(
      2 * (pow(nmax, 2) as num).toInt() + 1, (i) => sqrt(i.toDouble()));

  for (var m = 0; m < nmax; m++) {
    double PnmTmp = rootn[2 * m + 1] * Pnm[m][m];
    Pnm[m + 1][m] = costh[0] * PnmTmp;

    if (m > 0) {
      Pnm[m + 1][m + 1] = sinth[0] * PnmTmp / rootn[2 * m + 2];
    }

    for (var n = m + 2; n <= nmax; n++) {
      double d = pow(n, 2).toDouble() - pow(m, 2).toDouble();
      double e = 2 * n - 1;
      Pnm[n][m] = (e * costh[0] * Pnm[n - 1][m] -
              rootn[(d - e).toInt()] * Pnm[n - 2][m]) /
          rootn[d.toInt()];
    }
  }

  Pnm[0][2] = -Pnm[1][1];
  Pnm[1][2] = Pnm[1][0];

  for (var n = 2; n <= nmax; n++) {
    Pnm[0][n + 1] = -sqrt((pow(n, 2).toDouble() + n) / 2) * Pnm[n][1];
    Pnm[1][n + 1] = (sqrt(2 * (pow(n, 2).toDouble() + n)) * Pnm[n][0] -
            sqrt((pow(n, 2).toDouble() + n - 2)) * Pnm[n][2]) /
        2;

    for (var m = 2; m < n; m++) {
      Pnm[m][n + 1] = 0.5 *
          (sqrt((n + m) * (n - m + 1)) * Pnm[n][m - 1] -
              sqrt((n + m + 1) * (n - m)) * Pnm[n][m + 1]);
    }

    Pnm[n][n + 1] = sqrt(2 * n) * Pnm[n][n - 1] / 2;
  }

  return Pnm;
}

IGRF loadSHCFile(String filePath, {bool? leapYear}) {
  leapYear = leapYear ?? true;

  List<double> data = [];
  Map<String, dynamic> parameters = {};

  List<String> lines = File(filePath).readAsLinesSync();

  for (String line in lines) {
    if (line.startsWith('#')) continue;

    List<String> parts =
        line.split(' ').where((part) => part.isNotEmpty).toList();

    if (parts.length == 7) {
      String name = filePath.split('/').last; // Get file name
      parameters = {
        'SHC': name,
        'nmin': int.parse(parts[0]),
        'nmax': int.parse(parts[1]),
        'N': int.parse(parts[2]),
        'order': int.parse(parts[3]),
        'step': int.parse(parts[4]),
        'start_year': double.parse(parts[5]),
        'end_year': double.parse(parts[6]),
      };
    } else {
      data.addAll(parts.map((part) => double.parse(part)));
    }
  }

  List<double> time = data.sublist(0, parameters['N']);
  List<List<double>> coeffs =
      data.sublist(parameters['N']).chunked(parameters['N'] + 2).toList();

  for (int i = 0; i < coeffs.length; i++) {
    coeffs[i] = coeffs[i].sublist(2); // discard columns with n and m
  }

  return IGRF(time: time, coeffs: coeffs, parameters: parameters);
}

({double lat, double lon}) checkLatLonBounds(
    num latd, num latm, num lond, num lonm) {
  if (latd < -90 || latd > 90 || latm < -60 || latm > 60) {
    throw Exception('Latitude $latd or $latm out of bounds.');
  }
  if (lond < -360 || lond > 360 || lonm < -60 || lonm > 60) {
    throw Exception('Longitude $lond or $lonm out of bounds.');
  }
  if (latm < 0 && lond != 0) {
    throw Exception('Lat mins $latm and $lond out of bounds.');
  }
  if (lonm < 0 && lond != 0) {
    throw Exception('Longitude mins $lonm and $lond out of bounds.');
  }

  // Convert to decimal toDegrees
  if (latd < 0) {
    latm = -latm;
  }
  double lat = latd + latm / 60.0;

  if (lond < 0) {
    lonm = -lonm;
  }
  double lon = lond + lonm / 60.0;

  return (lat: lat, lon: lon);
}

({double rad, double thc, double sd, double cd}) ggToGeo(
    double h, double gdcolat) {
  final eqrad = 6378.137; // equatorial radius
  final flat = 1 / 298.257223563;
  final plrad = eqrad * (1 - flat); // polar radius

  final ctgd = cos(toRadians(gdcolat));
  final stgd = sin(toRadians(gdcolat));
  final a2 = eqrad * eqrad;
  final a4 = a2 * a2;
  final b2 = plrad * plrad;
  final b4 = b2 * b2;
  final c2 = ctgd * ctgd;
  final s2 = 1 - c2;
  final rho = sqrt(a2 * s2 + b2 * c2);

  final rad = sqrt(h * (h + 2 * rho) + (a4 * s2 + b4 * c2) / (rho * rho));
  final cd = (h + rho) / rad;
  final sd = (a2 - b2) * ctgd * stgd / (rho * rad);
  final cthc = ctgd * cd - stgd * sd;
  final thc = toDegrees(acos(cthc));

  return (rad: rad, thc: thc, sd: sd, cd: cd);
}

(double, double) geoToGg(double radius, double theta) {
  final a = 6378.137; // equatorial radius
  final b = 6356.752; // polar radius

  final a2 = a * a;
  final b2 = b * b;

  final e2 = (a2 - b2) / a2; // squared eccentricity
  final e4 = e2 * e2;
  final ep2 = (a2 - b2) / b2; // squared primed eccentricity

  final r = radius * sin(toRadians(theta));
  final z = radius * cos(toRadians(theta));

  final r2 = r * r;
  final z2 = z * z;

  final F = 54 * b2 * z2;
  final G = r2 + (1 - e2) * z2 - e2 * (a2 - b2);

  final c = e4 * F * r2 / pow(G, 3);

  final s = pow((1 + c + sqrt(c * c + 2 * c)), (1 / 3));
  final P = F / (3 * pow((s + 1 / s + 1), 2) * G * G);
  final Q = sqrt(1 + 2 * e4 * P);

  final r0 = -P * e2 * r / (1 + Q) +
      sqrt(0.5 * a2 * (1 + 1 / Q) -
          P * (1 - e2) * z2 / (Q * (1 + Q)) -
          0.5 * P * r2);
  final U = sqrt(pow((r - e2 * r0), 2) + z2);
  final V = sqrt(pow((r - e2 * r0), 2) + (1 - e2) * z2);

  final z0 = b2 * z / (a * V);
  final height = U * (1 - b2 / (a * V));
  final beta = 90 - toDegrees(atan2(z + ep2 * z0, r));

  return (height, beta);
}

List<double> xyz2dhif(double x, double y, double z) {
  double hsq = x * x + y * y;
  double hoz = sqrt(hsq);
  double eff = sqrt(hsq + z * z);
  double dec = atan2(y, x);
  double inc = atan2(z, hoz);

  return [toDegrees(dec), hoz, toDegrees(inc), eff];
}

List<double> xyz2dhifSv(
    double x, double y, double z, double xdot, double ydot, double zdot) {
  double h2 = x * x + y * y;
  double h = sqrt(h2);
  double f2 = h2 + z * z;
  double hdot = (x * xdot + y * ydot) / h;
  double fdot = (x * xdot + y * ydot + z * zdot) / sqrt(f2);
  double ddot = toDegrees((xdot * y - ydot * x) / h2) * 60;
  double idot = toDegrees((hdot * z - h * zdot) / f2) * 60;

  return [ddot, hdot, idot, fdot];
}

extension ListUtils<E> on List<E> {
  // Function to chunk a list into smaller lists of size 'size'
  List<List<E>> chunked(int size) {
    List<List<E>> chunks = [];
    for (int i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }
}
