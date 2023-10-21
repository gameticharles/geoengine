import 'dart:io';

import 'igrf_utils.dart';

final degreeSign = '\u00B0';

List<dynamic> option1() {
  int idm;
  while (true) {
    print('Enter value for format of latitudes and longitudes: ');
    print('1 - in degrees & minutes');
    print('2 - in decimal degrees');
    // idm = int.parse(stdin.readLineSync()!);
    idm = 2;
    if (idm < 1 || idm > 2) {
      continue;
    } else {
      break;
    }
  }

  int itype;
  while (true) {
    print('Enter value for coordinate system:');
    print('1 - geodetic (shape of Earth using the WGS-84 ellipsoid)');
    print('2 - geocentric (shape of Earth is approximated by a sphere)');
    //itype = int.parse(stdin.readLineSync()!);
    itype = 1;
    if (itype < 1 || itype > 2) {
      continue;
    } else {
      break;
    }
  }

  double lat, lon, colat;
  if (idm == 1) {
    print('Enter latitude & longitude in degrees & minutes');
    print(
        '(if either latitude or longitude is between -1 and 0 degrees, enter the minutes as negative).');
    print('Enter integers for degrees, floats for the minutes if needed');
    var inputValues = stdin.readLineSync()!.split(' ');
    var latd = int.parse(inputValues[0]);
    var latm = double.parse(inputValues[1]);
    var lond = int.parse(inputValues[2]);
    var lonm = double.parse(inputValues[3]);

    var result = checkLatLonBounds(latd, latm, lond, lonm);
    lat = result.lat;
    lon = result.lon;
    colat = 90 - lat;
  } else {
    print('Enter latitude & longitude in decimal degrees');
    //var inputValues = stdin.readLineSync()!.split(' ');
    var inputValues = ['6.56423', '-1.56243'];
    var latd = double.parse(inputValues[0]);
    var lond = double.parse(inputValues[1]);

    var result = checkLatLonBounds(latd, 0, lond, 0);
    lat = result.lat;
    lon = result.lon;
    colat = 90 - lat;
  }

  double alt, sd = 0, cd = 0;
  while (true) {
    if (itype == 1) {
      print('Enter altitude in km: ');
      // alt = double.parse(stdin.readLineSync()!);
      alt = 0.203;
      var result = ggToGeo(alt, colat);
      alt = result.rad;
      colat = result.thc;
      sd = result.sd;
      cd = result.cd;
    } else {
      print('Enter radial distance in km (>3485 km): ');
      alt = double.parse(stdin.readLineSync()!);
    }

    if (itype == 2 && alt < 3485) {
      print('Alt must be greater than CMB radius (3485 km)');
      continue;
    } else {
      break;
    }
  }

  double date;
  while (true) {
    print('Enter decimal date in years 1900-2030: ');
    // date = double.parse(stdin.readLineSync()!);
    date = 2023.0;
    if (date < 1900 || date > 2030) {
      continue;
    } else {
      break;
    }
  }

  return [date, alt, lat, colat, lon, itype, sd, cd];
}

List<dynamic> option2() {
  int idm;
  while (true) {
    print('Enter value for format of latitudes and longitudes: ');
    print('1 - in degrees & minutes');
    print('2 - in decimal degrees');
    idm = int.parse(stdin.readLineSync()!.trim());
    if (idm < 1 || idm > 2) {
      continue;
    } else {
      break;
    }
  }

  int itype;
  while (true) {
    print('Enter value for coordinate system:');
    print('1 - geodetic (shape of Earth using the WGS-84 ellipsoid)');
    print('2 - geocentric (shape of Earth is approximated by a sphere)');
    itype = int.parse(stdin.readLineSync()!.trim());
    if (itype < 1 || itype > 2) {
      continue;
    } else {
      break;
    }
  }

  double lat, lon, colat;
  if (idm == 1) {
    print('Enter latitude & longitude in degrees & minutes');
    print(
        '(if either latitude or longitude is between -1 and 0 degrees, enter the minutes as negative).');
    print('Enter 4 integers');
    var inputValues = stdin.readLineSync()!.split(' ');
    var latd = int.parse(inputValues[0]);
    var latm = double.parse(inputValues[1]);
    var lond = int.parse(inputValues[2]);
    var lonm = double.parse(inputValues[3]);

    var result = checkLatLonBounds(latd, latm, lond, lonm);
    lat = result.lat;
    lon = result.lon;
    colat = 90 - lat;
  } else {
    print('Enter latitude & longitude in decimal degrees');
    var inputValues = stdin.readLineSync()!.split(' ');
    var latd = double.parse(inputValues[0]);
    var lond = double.parse(inputValues[1]);

    var result = checkLatLonBounds(latd, 0, lond, 0);
    lat = result.lat;
    lon = result.lon;
    colat = 90 - lat;
  }

  double alt, sd = 0, cd = 0;
  while (true) {
    if (itype == 1) {
      print('Enter altitude in km: ');
      alt = double.parse(stdin.readLineSync()!);
      var result = ggToGeo(alt, colat);
      alt = result.rad;
      colat = result.thc;
      sd = result.sd;
      cd = result.cd;
    } else {
      print('Enter radial distance in km (>3485 km): ');
      alt = double.parse(stdin.readLineSync()!);
    }

    if ((itype == 2 && alt < 3485) || (itype == 1 && alt < -3300)) {
      print('Alt must be greater than CMB radius (3485 km)');
      continue;
    } else {
      break;
    }
  }

  double dates, datee;
  while (true) {
    print('Enter start decimal date in years 1900-2025: ');
    dates = double.parse(stdin.readLineSync()!);
    if (dates < 1900 || dates > 2030) {
      continue;
    } else {
      break;
    }
  }
  while (true) {
    print('Enter end decimal date in years 1900-2025: ');
    datee = double.parse(stdin.readLineSync()!);
    if (datee < 1900 || datee > 2030 || datee < dates) {
      continue;
    } else {
      break;
    }
  }

  var date = List<double>.generate(
      datee.toInt() - dates.toInt() + 1, (index) => dates + index);
  var altList = List<double>.filled(date.length, alt);
  var latList = List<double>.filled(date.length, lat);
  var colatList = List<double>.filled(date.length, colat);
  var lonList = List<double>.filled(date.length, lon);
  var sdList = List<double>.filled(date.length, sd);
  var cdList = List<double>.filled(date.length, cd);

  return [date, altList, latList, colatList, lonList, itype, sdList, cdList];
}

List<dynamic> option3() {
  int itype;
  while (true) {
    print('Enter value for coordinate system:');
    print('1 - geodetic (shape of Earth using the WGS-84 ellipsoid)');
    print('2 - geocentric (shape of Earth is approximated by a sphere)');
    itype = int.parse(stdin.readLineSync()!.trim());
    if (itype < 1 || itype > 2) {
      continue;
    } else {
      break;
    }
  }

  double lats, lati, late;
  while (true) {
    print(
        'Enter starting latitude, increment/decrement and final latitude in decimal degrees');
    var inputValues = stdin.readLineSync()!.split(' ');
    lats = double.parse(inputValues[0]);
    lati = double.parse(inputValues[1]);
    late = double.parse(inputValues[2]);

    if (lats < -90 || lats > 90 || late < -90 || late > 90) continue;
    if (lati.abs() > (lats - late).abs()) {
      print(
          'Increment or decrement are larger than the gap between the start and end points');
      continue;
    } else {
      break;
    }
  }

  double lons, loni, lone;
  while (true) {
    print(
        'Enter starting longitude, increment/decrement and final longitude in decimal degrees');
    var inputValues = stdin.readLineSync()!.split(' ');
    lons = double.parse(inputValues[0]);
    loni = double.parse(inputValues[1]);
    lone = double.parse(inputValues[2]);

    if (lons < -180 || lons > 360 || lone < -180 || lone > 360) continue;
    if (loni.abs() > (lons - lone).abs()) {
      print(
          'Increment or decrement are larger than the gap between the start and end points');
      continue;
    } else {
      break;
    }
  }

  double alt, sd = 0, cd = 0;
  while (true) {
    if (itype == 1) {
      print('Enter altitude in km: ');
      alt = double.parse(stdin.readLineSync()!);
    } else {
      print('Enter radial distance in km (>3485 km): ');
      alt = double.parse(stdin.readLineSync()!);
    }

    if (itype == 2 && alt < 3485) {
      print('Alt must be greater than CMB radius (3485 km)');
      continue;
    } else {
      break;
    }
  }

  double date;
  while (true) {
    print('Enter decimal date in years 1900-2025: ');
    date = double.parse(stdin.readLineSync()!);
    if (date < 1900 || date > 2030) {
      continue;
    } else {
      break;
    }
  }

  // Create a meshgrid to fill in the colat/lons
  // Note: Dart doesn't have a direct equivalent to numpy's meshgrid, so we'll need to implement this manually.
  var colat = List.empty();
  var lon = List.empty();
  for (var lt = 90 - lats; lt <= 90 - late; lt += lati) {
    for (var ln = lons; ln <= lone; ln += loni) {
      colat.add(lt);
      lon.add(ln);
    }
  }

  var latList = List<num>.generate(colat.length, (index) => 90 - colat[index]);
  if (itype == 1) {
    // var result = ggToGeo(List<num>.filled(colat.length, alt), colat);
    // alt = result.rad;
    // colat = result.thc;
    // sd = result.sd;
    // cd = result.cd;
  }

  var dateList = List<double>.filled(lon.length, date);

  return [dateList, alt, latList, colat, lon, itype, sd, cd];
}

void write1(
    String name,
    double date,
    double alt,
    double lat,
    double colat,
    double lon,
    double X,
    double Y,
    double Z,
    double dX,
    double dY,
    double dZ,
    double dec,
    double hoz,
    double inc,
    double eff,
    double decs,
    double hozs,
    double incs,
    double effs,
    int itype) {
  final degreeSign = '°';

  if (itype == 1) {
    var result = geoToGg(alt, colat);
    alt = result.$1;
    lat = 90 - result.$2;
  }

  List<String> outputLines = [];

  outputLines.add(
      'Geomagnetic field values at: ${lat.toStringAsFixed(4)}$degreeSign / $lon$degreeSign, at altitude ${alt.toStringAsFixed(3)} for $date');
  outputLines.add('Declination (D): ${dec.toStringAsFixed(3)}$degreeSign');
  outputLines.add('Inclination (I): ${inc.toStringAsFixed(3)}$degreeSign');
  outputLines.add('Horizontal intensity (H): ${hoz.toStringAsFixed(1)} nT');
  outputLines.add('Total intensity (F)     : ${eff.toStringAsFixed(1)} nT');
  outputLines.add('North component (X)     : ${X.toStringAsFixed(1)} nT');
  outputLines.add('East component (Y)      : ${Y.toStringAsFixed(1)} nT');
  outputLines.add('Vertical component (Z)  : ${Z.toStringAsFixed(1)} nT');
  outputLines.add('Declination SV (D): ${decs.toStringAsFixed(2)} arcmin/yr');
  outputLines.add('Inclination SV (I): ${incs.toStringAsFixed(2)} arcmin/yr');
  outputLines.add('Horizontal SV (H): ${hozs.toStringAsFixed(1)} nT/yr');
  outputLines.add('Total SV (F)     : ${effs.toStringAsFixed(1)} nT/yr');
  outputLines.add('North SV (X)     : ${dX.toStringAsFixed(1)} nT/yr');
  outputLines.add('East SV (Y)      : ${dY.toStringAsFixed(1)} nT/yr');
  outputLines.add('Vertical SV (Z)  : ${dZ.toStringAsFixed(1)} nT/yr');

  if (name == null || name.isEmpty) {
    // Print to console
    outputLines.forEach((line) => print(line));
  } else {
    // Write to file
    File(name).writeAsStringSync(outputLines.join('\n'));
  }
}

void write2(
    String? name,
    List<double> date,
    List<double> alt,
    List<double> lat,
    List<double> colat,
    List<double> lon,
    List<double> X,
    List<double> Y,
    List<double> Z,
    List<double> dX,
    List<double> dY,
    List<double> dZ,
    List<double> dec,
    List<double> hoz,
    List<double> inc,
    List<double> eff,
    List<double> decs,
    List<double> hozs,
    List<double> incs,
    List<double> effs,
    int itype) {
  final degreeSign = '°';

  if (itype == 1) {
    var result = geoToGg(alt[0], colat[0]);
    alt[0] = result.$1;
    lat[0] = 90 - result.$2;
  }

  List<String> outputLines = [];

  if (name == null || name.isEmpty) {
    // Print to console
    print(
        '\nGeomagnetic field values at: ${lat[0].toStringAsFixed(4)}$degreeSign / ${lon[0].toStringAsFixed(4)}$degreeSign, at altitude ${alt[0].toStringAsFixed(3)}');
    print(
        'Date  D($degreeSign)  I($degreeSign)  H(nT) F(nT) X(nT) Y(nT)  Z(nT) SV_D(min/yr)  SV_I(min/yr)  SV_H(nT/yr) SV_F(nT/yr)  SV_X(nT/yr)  SV_Y(nT/yr)  SV_Z(nT/yr)');
    for (var i = 0; i < date.length; i++) {
      print(
          '${date[i]} ${dec[i].toStringAsFixed(3)} ${inc[i].toStringAsFixed(3)} ${hoz[i].toStringAsFixed(1)} ${eff[i].toStringAsFixed(1)} ${X[i].toStringAsFixed(1)} ${Y[i].toStringAsFixed(1)} ${Z[i].toStringAsFixed(1)} ${decs[i].toStringAsFixed(2)} ${incs[i].toStringAsFixed(2)} ${hozs[i].toStringAsFixed(1)} ${effs[i].toStringAsFixed(1)} ${dX[i].toStringAsFixed(1)} ${dY[i].toStringAsFixed(1)} ${dZ[i].toStringAsFixed(1)}');
    }
  } else {
    // Write to file
    outputLines.add(
        'Geomagnetic field values at: ${lat[0].toStringAsFixed(4)}$degreeSign / ${lon[0].toStringAsFixed(4)}$degreeSign, at altitude ${alt[0].toStringAsFixed(3)}');
    outputLines.add(
        'Date  D($degreeSign)  I($degreeSign)  H(nT) F(nT) X(nT) Y(nT)  Z(nT) SV_D(min/yr)  SV_I(min/yr)  SV_H(nT/yr) SV_F(nT/yr)  SV_X(nT/yr)  SV_Y(nT/yr)  SV_Z(nT/yr)');
    for (var i = 0; i < date.length; i++) {
      outputLines.add(
          '${date[i]} ${dec[i].toStringAsFixed(3)} ${inc[i].toStringAsFixed(3)} ${hoz[i].toStringAsFixed(1)} ${eff[i].toStringAsFixed(1)} ${X[i].toStringAsFixed(1)} ${Y[i].toStringAsFixed(1)} ${Z[i].toStringAsFixed(1)} ${decs[i].toStringAsFixed(2)} ${incs[i].toStringAsFixed(2)} ${hozs[i].toStringAsFixed(1)} ${effs[i].toStringAsFixed(1)} ${dX[i].toStringAsFixed(1)} ${dY[i].toStringAsFixed(1)} ${dZ[i].toStringAsFixed(1)}');
    }
    File(name).writeAsStringSync(outputLines.join('\n'));
  }
}

void write3(
    String? name,
    List<double> date,
    List<double> alt,
    List<double> lat,
    List<double> colat,
    List<double> lon,
    List<double> X,
    List<double> Y,
    List<double> Z,
    List<double> dX,
    List<double> dY,
    List<double> dZ,
    List<double> dec,
    List<double> hoz,
    List<double> inc,
    List<double> eff,
    List<double> decs,
    List<double> hozs,
    List<double> incs,
    List<double> effs,
    int itype) {
  final degreeSign = '°';

  if (itype == 1) {
    var result = geoToGg(alt[0], colat[0]);
    alt[0] = result.$1;
    lat[0] = 90 - result.$2;
  }

  List<String> outputLines = [];

  if (name == null || name.isEmpty) {
    // Print to console
    print(
        '\nGeomagnetic field values for: ${date[0]}, at altitude ${alt[0].toStringAsFixed(3)}');
    print(
        'Latitude  Longitude  D($degreeSign)  I($degreeSign)  H(nT) F(nT) X(nT) Y(nT)  Z(nT) SV_D(min/yr)  SV_I(min/yr)  SV_H(nT/yr) SV_F(nT/yr)  SV_X(nT/yr)  SV_Y(nT/yr)  SV_Z(nT/yr)');
    for (var i = 0; i < lon.length; i++) {
      print(
          '${lat[i].toStringAsFixed(4)} ${lon[i].toStringAsFixed(4)} ${dec[i].toStringAsFixed(3)} ${inc[i].toStringAsFixed(3)} ${hoz[i].toStringAsFixed(1)} ${eff[i].toStringAsFixed(1)} ${X[i].toStringAsFixed(1)} ${Y[i].toStringAsFixed(1)} ${Z[i].toStringAsFixed(1)} ${decs[i].toStringAsFixed(2)} ${incs[i].toStringAsFixed(2)} ${hozs[i].toStringAsFixed(1)} ${effs[i].toStringAsFixed(1)} ${dX[i].toStringAsFixed(1)} ${dY[i].toStringAsFixed(1)} ${dZ[i].toStringAsFixed(1)}');
    }
  } else {
    // Write to file
    outputLines.add(
        'Geomagnetic field values for: ${date[0]}, at altitude ${alt[0].toStringAsFixed(3)}');
    outputLines.add(
        'Latitude  Longitude  D($degreeSign)  I($degreeSign)  H(nT) F(nT) X(nT) Y(nT)  Z(nT) SV_D(min/yr)  SV_I(min/yr)  SV_H(nT/yr) SV_F(nT/yr)  SV_X(nT/yr)  SV_Y(nT/yr)  SV_Z(nT/yr)');
    for (var i = 0; i < date.length; i++) {
      outputLines.add(
          '${lat[i].toStringAsFixed(4)} ${lon[i].toStringAsFixed(4)} ${dec[i].toStringAsFixed(3)} ${inc[i].toStringAsFixed(3)} ${hoz[i].toStringAsFixed(1)} ${eff[i].toStringAsFixed(1)} ${X[i].toStringAsFixed(1)} ${Y[i].toStringAsFixed(1)} ${Z[i].toStringAsFixed(1)} ${decs[i].toStringAsFixed(2)} ${incs[i].toStringAsFixed(2)} ${hozs[i].toStringAsFixed(1)} ${effs[i].toStringAsFixed(1)} ${dX[i].toStringAsFixed(1)} ${dY[i].toStringAsFixed(1)} ${dZ[i].toStringAsFixed(1)}');
    }
    File(name).writeAsStringSync(outputLines.join('\n'));
  }
}
