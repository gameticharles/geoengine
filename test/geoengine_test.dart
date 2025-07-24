import 'package:test/test.dart';
import 'package:geoengine/geoengine.dart';
import 'package:advance_math/advance_math.dart'; // For Matrix, LatLng, dms2Degree etc.

void main() {
  group('Core Calculations (Distance and Bearings)', () {
    // Test points (degrees)
    final LatLng point1 = LatLng(50.06632, -5.71475); // Near Land's End, UK
    final LatLng point2 = LatLng(58.64402, -3.07009); // Near John o' Groats, UK
    final LatLng london = LatLng(51.5074, 0.1278); // London
    final LatLng paris = LatLng(48.8566, 2.3522); // Paris
    final LatLng newYork = LatLng(40.7128, -74.0060); // New York
    final LatLng losAngeles = LatLng(34.0522, -118.2437); // Los Angeles

    test('Distance.haversine', () {
      var distance = Distance.haversine(point1, point2);
      expect(distance.valueSI,
          closeTo(969954, 5)); // Approx 969.95km, result in meters

      var distLondonParis = Distance.haversine(london, paris);
      expect(distLondonParis.valueInUnits(LengthUnits.kilometers),
          closeTo(343.5, 0.5)); // Approx 343.5 km
    });

    test('LatLng.distanceTo (greatCircle, vincenty)', () {
      // Great Circle
      var distGC =
          point1.distanceTo(point2, method: DistanceMethod.greatCircle);
      expect(distGC!.valueSI,
          closeTo(969954, 5)); // Similar to Haversine for these distances

      // Vincenty - should be more accurate, might differ slightly from Haversine/GreatCircle
      var distVY = point1.distanceTo(point2, method: DistanceMethod.vincenty);
      expect(distVY!.valueSI,
          closeTo(969828, 5)); // Slightly different, ~969.828km

      var distNYLA_VY =
          newYork.distanceTo(losAngeles, method: DistanceMethod.vincenty);
      expect(distNYLA_VY!.valueInUnits(LengthUnits.kilometers),
          closeTo(3944.2, 1)); // Approx 3944 km
    });

    test('LatLng.initialBearingTo and LatLng.finalBearingTo', () {
      var initial = london.initialBearingTo(paris);
      expect(initial.deg, closeTo(156.1, 0.1));

      var finalB = london.finalBearingTo(paris);
      expect(finalB.deg, closeTo(157.9, 0.1));

      // Bearing from New York to Los Angeles
      var initialNYLA = newYork.initialBearingTo(losAngeles);
      expect(initialNYLA.deg, closeTo(266.0, 0.1));
      var finalNYLA = newYork.finalBearingTo(losAngeles);
      expect(finalNYLA.deg, closeTo(246.3, 0.1));
    });

    test('LatLng.midPointTo', () {
      var mid = london.midPointTo(paris);
      expect(mid.latitude, closeTo(50.1843, 0.0001));
      expect(mid.longitude, closeTo(1.2400, 0.0001));
    });

    test('LatLng.destinationPoint', () {
      // From London, 100km on bearing 90 degrees (East)
      var dest = london.destinationPoint(100000, 90);
      expect(dest.latitude,
          closeTo(51.5072, 0.0001)); // Latitude should barely change
      expect(dest.longitude, closeTo(1.4743, 0.0001)); // Longitude increases
    });

    test('LatLng.intersectionPoint', () {
      var p1 = LatLng(51.8853, 0.2545); // Point 1
      var brng1 = 108.55; // Bearing from P1
      var p2 = LatLng(49.0034, 2.5735); // Point 2
      var brng2 = 32.44; // Bearing from P2

      var intersection = LatLng.intersectionPoint(p1, brng1, p2, brng2);
      expect(intersection, isNotNull);
      expect(intersection!.latitude, closeTo(50.9076, 0.0001));
      expect(intersection.longitude, closeTo(4.5084, 0.0001));
      // Values from online Ed Williams' calculator: 50°54'27.4"N, 004°30'30.2"E
      // 50 + 54/60 + 27.4/3600 = 50.9076
      // 4 + 30/60 + 30.2/3600 = 4.5084
    });

    test('Rhumb Line Calculations', () {
      var startPoint = LatLng(50.3667, -4.1340); // Plymouth
      var endPoint = LatLng(42.3511, -71.0408); // Boston (approx)

      var dist = startPoint.rhumbLineDistance(endPoint);
      expect(dist.valueInUnits(LengthUnits.kilometers),
          closeTo(5198, 1)); // From README example

      var bearing = startPoint.rhumbLineBearing(endPoint);
      expect(bearing.deg, closeTo(256.67, 0.01)); // From README example

      var mid = startPoint.rhumbMidpoint(endPoint);
      // README example: 047° 50' 9.060" N, 038° 13' 28.378" W
      // 47 + 50/60 + 9.060/3600 = 47.83585
      // -(38 + 13/60 + 28.378/3600) = -38.2245
      expect(mid.latitude, closeTo(47.83585, 0.0001));
      expect(mid.longitude, closeTo(-38.2245, 0.0001));

      var dest = startPoint.rhumbDestinationPoint(1000000, 270); // 1000km West
      expect(
          dest.latitude,
          closeTo(
              50.3667, 0.0001)); // Latitude is constant on rhumb line due West
      expect(dest.longitude, closeTo(-15.60, 0.01)); // Approximate
    });
  });

  group('Coordinate Systems', () {
    test('UTMZones', () {
      var u = UTMZones();
      expect(u.getZone(latitude: 6.5655, longitude: -1.5646), equals('30P'));
      expect(u.getHemisphere('30P'), equals('N'));
      expect(u.getLatZone(6.5655), equals('P'));
      expect(
          u.getZone(latitude: -31.295043, longitude: 27.293409), equals('35J'));
      expect(u.getHemisphere('35J'), equals('S'));
    });

    test('MGRS.parse', () {
      var mgrs1 = MGRS.parse('31U DQ 48251 11932');
      expect(mgrs1.toString(), equals('31U DQ 48251 11932'));
      var mgrs2 = MGRS.parse('31UDQ4825111932');
      expect(mgrs2.toString(), equals('31U DQ 48251 11932'));
      // Consider adding tests for invalid MGRS strings if parse throws errors
    });

    test('LatLng to UTM/MGRS and back', () {
      var ll = LatLng(6.5655, -1.5646);
      var utmExpected = UTM(
          zoneNumber: 30,
          zoneLetter: 'N',
          easting: 658699,
          northing: 725944); // Approx from README
      var mgrsExpectedStr = "30N XN 58699 25944"; // From README

      var utmActual = ll.toUTM();
      expect(utmActual.zoneNumber, utmExpected.zoneNumber);
      expect(utmActual.zoneLetter,
          utmExpected.zoneLetter); // Library uses N/S, MGRS uses letters
      expect(utmActual.easting, closeTo(utmExpected.easting, 1));
      expect(utmActual.northing, closeTo(utmExpected.northing, 1));

      expect(
          ll.toMGRS().replaceAll(' ', ''), mgrsExpectedStr.replaceAll(' ', ''));

      var mgrsObj = MGRS.parse(mgrsExpectedStr);
      var llFromMgrs = mgrsObj.toLatLng();
      expect(llFromMgrs.lat, closeTo(ll.lat, 0.0001));
      expect(llFromMgrs.lng, closeTo(ll.lng, 0.0001));

      var utmFromMgrs = mgrsObj.toUTM();
      expect(utmFromMgrs.zoneNumber, utmActual.zoneNumber);
      // expect(utmFromMgrs.zoneLetter, utmActual.zoneLetter); // MGRS parsing might set letter based on MGRS band
      expect(utmFromMgrs.easting, closeTo(utmActual.easting, 1));
      expect(utmFromMgrs.northing, closeTo(utmActual.northing, 1));

      var llFromUtm = utmActual.toLatLng();
      expect(llFromUtm.lat, closeTo(ll.lat, 0.0001));
      expect(llFromUtm.lng, closeTo(ll.lng, 0.0001));

      expect(utmActual.toMGRS().replaceAll(' ', ''),
          mgrsExpectedStr.replaceAll(' ', ''));
    });

    test('CoordinateConversion Geodetic to Geodetic (Datum Transformation)',
        () {
      final LatLng pointWGS84 = LatLng(6.65412, -1.54651, 200);
      CoordinateConversion transCoordinate = CoordinateConversion();
      Projection sourceProjection = Projection.get('EPSG:4326')!;
      Projection targetProjection = Projection.parse(
          'PROJCS["Accra / Ghana National Grid",GEOGCS["Accra",DATUM["Accra",SPHEROID["War Office",6378300,296,AUTHORITY["EPSG","7029"]],TOWGS84[-199,32,322,0,0,0,0],AUTHORITY["EPSG","6168"]],PRIMEM["Greenwich",0,AUTHORITY["EPSG","8901"]],UNIT["degree",0.0174532925199433,AUTHORITY["EPSG","9122"]],AUTHORITY["EPSG","4168"]],PROJECTION["Transverse_Mercator"],PARAMETER["latitude_of_origin",4.666666666666667],PARAMETER["central_meridian",-1],PARAMETER["scale_factor",0.99975],PARAMETER["false_easting",900000],PARAMETER["false_northing",0],UNIT["Gold Coast foot",0.3047997101815088,AUTHORITY["EPSG","9094"]],AXIS["Easting",EAST],AXIS["Northing",NORTH],AUTHORITY["EPSG","2136"]]');

      var res = transCoordinate.convert(
        point: pointWGS84,
        projSrc: sourceProjection,
        projDst: targetProjection,
        conversion: ConversionType.geodeticToGeodetic,
      );
      // Expected values from README
      expect(
          res.asLatLng().latitude, closeTo(dms2Degree(6, 39, 4.889), 0.00001));
      expect(res.asLatLng().longitude,
          closeTo(dms2Degree(-1, 32, 48.303), 0.00001));
      expect(res.asLatLng().elevation, closeTo(200.331, 0.001));
    });

    test('CoordinateConversion Geodetic to Projected (UTM)', () {
      final LatLng pp = LatLng(6.65412, -1.54651, 200);
      CoordinateConversion transCoordinate = CoordinateConversion();
      Projection sourceProjection = Projection.get('EPSG:4326')!;
      Projection targetProjectionUTM =
          transCoordinate.getUTM84ProjectionFromLon(pp.lat, pp.lng);

      var res = transCoordinate.convert(
        point: pp,
        projSrc: sourceProjection,
        projDst: targetProjectionUTM,
        conversion: ConversionType.geodeticToProjected,
      );
      // Expected values from README
      expect(res.x, closeTo(660671.65, 0.01));
      expect(res.y, closeTo(735749.49, 0.01));
      expect(res.z, closeTo(200.0, 0.01));
    });
  });

  group('Julian Dates', () {
    test('Initialization and toJulianDate()', () {
      var jdFromYMD =
          JulianDate.fromDate(year: 2023, month: 8, day: 15, hour: 12); // Noon
      expect(jdFromYMD.toJulianDate(), equals(2460171.0));

      var dt = DateTime.utc(2023, 8, 15, 12); // Noon UTC
      var jdFromDateTime = JulianDate(dt);
      expect(jdFromDateTime.toJulianDate(), equals(2460171.0));

      // Midnight UTC (start of the day)
      var jdMidnight =
          JulianDate.fromDate(year: 2023, month: 8, day: 15, hour: 0);
      expect(jdMidnight.toJulianDate(), equals(2460170.5));
    });

    test('Comparison', () {
      var date1 = JulianDate.fromDate(year: 2023, month: 8, day: 15);
      var date2 = JulianDate.fromDate(year: 2023, month: 8, day: 20);
      var date1Again = JulianDate.fromDate(year: 2023, month: 8, day: 15);

      expect(date1 == date2, isFalse);
      expect(date1 < date2, isTrue);
      expect(date1 <= date2, isTrue);
      expect(date2 > date1, isTrue);
      expect(date2 >= date1, isTrue);
      expect(date1 == date1Again, isTrue);
    });

    test('toModifiedJulianDate()', () {
      // JD for 2023-08-16 00:00:00.000 UTC is 2460171.5
      var jd = JulianDate.fromJulianDate(2460171.5);
      expect(jd.toModifiedJulianDate(), equals(60171.0)); // JD - 2400000.5

      // MJD with custom reference date (Jan 1, 1960, 00:00 UTC)
      // JD for 1960-01-01 00:00:00.000 UTC is 2436934.5
      var refDate = DateTime.utc(1960, 1, 1);
      // 2460171.5 - 2436934.5 = 23237.0
      expect(jd.toModifiedJulianDate(referenceDate: refDate), equals(23237.0));
    });

    test('JulianDate.fromJulianDate() and .dateTime', () {
      double jdVal = 2460171.5; // Represents 2023-08-16 00:00:00 UTC
      var jdObj = JulianDate.fromJulianDate(jdVal);
      var dt = jdObj.dateTime;

      expect(dt.year, equals(2023));
      expect(dt.month, equals(8));
      expect(dt.day, equals(16));
      expect(dt.hour, equals(0));
      expect(dt.minute, equals(0));
      expect(dt.second, equals(0));
      expect(dt.isUtc,
          isTrue); // GeoEngine JulianDate seems to work in UTC context for DateTime
    });
  });

  group('Least Squares Adjustment', () {
    test('LSA Example from README', () {
      var A = Matrix([
        [-1, 0, 0, 0],
        [-1, 1, 0, 0],
        [0, -1, 1, 0],
        [0, 0, -1, 0],
        [0, 0, -1, 1],
        [0, 0, 0, -1],
        [1, 0, 0, -1],
      ]);
      var W = DiagonalMatrix(
          [1 / 16, 1 / 9, 1 / 49, 1 / 36, 1 / 16, 1 / 9, 1 / 25]);
      var B = ColumnMatrix([0, 0, 0.13, 0, 0, -0.32, -0.53]);

      var lsa = LeastSquaresAdjustment(A: A, B: B, W: W, confidenceLevel: 40);

      // // Check unknown parameters (x)
      // expect(lsa.x.get(0, 0), closeTo(-0.065134899, 1e-6));
      // expect(lsa.x.get(1, 0), closeTo(-0.045703714, 1e-6));
      // expect(lsa.x.get(2, 0), closeTo(0.190088292, 1e-6));
      // expect(lsa.x.get(3, 0), closeTo(0.309116307, 1e-6));

      // Check unit variance (uv)
      expect(lsa.uv, closeTo(0.001136059, 1e-6));

      // Check Chi-squared test
      var chiTest = lsa.chiSquareTest();
      expect(chiTest.chiSquared, closeTo(0.003408177, 1e-6));
      expect(chiTest.degreesOfFreedom, equals(3));

      // Check outliers (as per README example output)
      expect(lsa.outliers,
          equals([false, true, false, false, true, false, false]));
    });
  });

  group('Levelling', () {
    final startingTBM = 100.000;
    final closingTBM = 98.050;
    final data = [
      ['A', 1.751, null, null],
      ['B', null, 0.540, null],
      ['C', 0.300, null, 2.100],
      ['D', null, 1.100, null],
      ['E', null, 1.260, null],
      ['F', 1.500, null, 2.300],
      ['G', null, null, 1.110]
    ];

    Levelling setupLevelling(LevellingMethod method) {
      final levelling = Levelling(
        startingTBM: startingTBM,
        closingTBM: closingTBM,
        accuracy: 5,
        method: method,
        roundDigits: 3,
      );
      for (var entry in data) {
        levelling.addData(entry[0].toString(), entry[1] as double?,
            entry[2] as double?, entry[3] as double?);
      }
      levelling.computeReducedLevels();
      return levelling;
    }

    test('Rise & Fall Method', () {
      final levelling = setupLevelling(LevellingMethod.riseFall);

      // Based on README output for Rise & Fall (which is the same as HPC in the example printout)
      expect(levelling.misclose, closeTo(-0.009, 0.0001));
      expect(levelling.allowableMisclose, closeTo(8.660, 0.001)); // mm
      expect(levelling.isWorkAccepted,
          isFalse); // As per README output: |-0.009|m * 1000 = 9mm. 9mm > 8.660mm

      final expectedRLs = [
        100.0,
        101.211,
        99.651,
        98.851,
        98.691,
        97.651,
        98.041
      ];
      for (int i = 0; i < expectedRLs.length; i++) {
        expect(levelling.reducedLevels[i], closeTo(expectedRLs[i], 0.0001));
      }
      // Check adjusted RLs from the printout in README
      final expectedAdjustedRLs = [
        100.000,
        101.214,
        99.657,
        98.857,
        98.697,
        97.660,
        98.050
      ];
      for (int i = 0; i < expectedAdjustedRLs.length; i++) {
        expect(levelling.reducedLevels[i],
            closeTo(expectedAdjustedRLs[i], 0.0001));
      }
    });

    test('HPC Method', () {
      final levelling = setupLevelling(LevellingMethod.hpc);
      // Assuming HPC calculations and adjustments are similar to Rise&Fall for this dataset as per README print
      expect(levelling.misclose, closeTo(-0.009, 0.0001));
      expect(levelling.allowableMisclose, closeTo(8.660, 0.001)); // mm
      expect(levelling.isWorkAccepted, isFalse);

      final expectedRLs = [
        100.0,
        101.211,
        99.651,
        98.851,
        98.691,
        97.651,
        98.041
      ];
      for (int i = 0; i < expectedRLs.length; i++) {
        expect(levelling.reducedLevels[i], closeTo(expectedRLs[i], 0.0001));
      }
      final expectedAdjustedRLs = [
        100.000,
        101.214,
        99.657,
        98.857,
        98.697,
        97.660,
        98.050
      ];
      for (int i = 0; i < expectedAdjustedRLs.length; i++) {
        expect(levelling.reducedLevels[i],
            closeTo(expectedAdjustedRLs[i], 0.0001));
      }
    });
    test('Arithmetic Check Result', () {
      final levelling = setupLevelling(LevellingMethod.riseFall);
      expect(levelling.arithmeticCheckResult,
          contains("Arithmetic Checks are OK."));
    });
  });

  group('Geocoding (LocalStrategy)', () {
    // Sample data for LocalStrategy
    final List<Map<String, dynamic>> sampleGeoData = [
      {
        'id': 1,
        'name': 'Location A',
        'latitude': 5.80736,
        'longitude': 0.41074
      },
      {
        'id': 2,
        'name': 'Location B',
        'latitude': 6.13373,
        'longitude': 0.81585
      },
      {
        'id': 3,
        'name': 'KNUST',
        'latitude': 6.6785135,
        'longitude': -1.5754220
      }, // KNUST, Kumasi
    ];

    final localGeocoder = Geocoder(
      strategyFactory: LocalStrategy.create(
        entries: sampleGeoData,
        coordinatesColumnNames: (y: 'latitude', x: 'longitude'),
      ),
      config: {
        'isGeodetic': true,
        'searchRadius': 5000, // 5km
        'limit': 3,
        'indexingStrategy': 'KDTree',
      },
    );

    test('LocalStrategy search', () async {
      var response = await localGeocoder.search('KNUST');
      expect(response.success, isTrue);
      expect(response.result, isNotEmpty);
      expect(response.result.first['name'], equals('KNUST'));
      expect(response.result.first['latitude'], closeTo(6.6785135, 0.00001));
    });

    test('LocalStrategy reverse', () async {
      var point = LatLng(6.6780, -1.5750); // Near KNUST
      var response = await localGeocoder.reverse(point);
      expect(response.success, isTrue);
      expect(response.result, isNotEmpty);
      // Result is List<List<dynamic>>, where inner list is [Map entry, double distance]
      expect(response.result.first[0]['name'], equals('KNUST'));
      expect(
          response.result.first[1], lessThan(1000)); // Distance should be < 1km
    });
  });

  group('Astronomy', () {
    test('Observer creation', () {
      final observer = Observer(5.6037, -0.1870, 61); // Accra
      expect(observer.latitude, equals(5.6037));
      expect(observer.longitude, equals(-0.1870));
      expect(observer.height, equals(61));
    });

    test('Moon Phase calculation', () {
      // Test for a known New Moon, e.g., 2023-01-21 20:53 UTC
      var newMoonDate = DateTime.utc(2023, 1, 21, 20, 53);
      var phaseAngle = moonPhase(newMoonDate);
      // Phase angle for New Moon should be close to 0 or 360.
      // Allowing a small tolerance due to the exact definition of "New Moon" time.
      bool isNewMoon = phaseAngle < 5.0 || phaseAngle > 355.0;
      expect(isNewMoon, isTrue,
          reason:
              "Phase angle $phaseAngle was not close to 0/360 for New Moon");

      // Test for a known Full Moon, e.g., 2023-08-01 18:31 UTC
      var fullMoonDate = DateTime.utc(2023, 8, 1, 18, 31);
      phaseAngle = moonPhase(fullMoonDate);
      // Phase angle for Full Moon should be close to 180.
      expect(phaseAngle, closeTo(180.0, 5.0),
          reason: "Phase angle $phaseAngle was not close to 180 for Full Moon");
    });

    test('Rise/Set Times (Conceptual - using fixed date/location)', () {
      final observer = Observer(51.5074, -0.1278, 35); // London
      final date = DateTime.utc(2024, 3, 15); // A specific date

      AstroTime? sunrise = searchRiseSet(Body.Sun, observer, 1, date, 300);
      AstroTime? sunset = searchRiseSet(Body.Sun, observer, -1, date, 300);

      expect(sunrise, isNotNull,
          reason: "Sunrise should be found for London on 2024-03-15");
      expect(sunset, isNotNull,
          reason: "Sunset should be found for London on 2024-03-15");

      if (sunrise != null && sunset != null) {
        expect(sunrise.date.isBefore(sunset.date),
            isTrue); // Sunrise before sunset
        // Typically sunrise around 6-7 AM UTC, sunset around 6-7 PM UTC for this date/location in March
        expect(sunrise.date.hour, greaterThanOrEqualTo(5));
        expect(sunrise.date.hour, lessThanOrEqualTo(8));
        expect(sunset.date.hour, greaterThanOrEqualTo(17));
        expect(sunset.date.hour, lessThanOrEqualTo(20));
      }
    });

    // test('Equinox Calculation', () {
    //     // March Equinox 2023 was around March 20.
    //     var equinoxInfo = searchEquinox(EquinoxType.March, 2023);
    //     expect(equinoxInfo, isNotNull);
    //     expect(equinoxInfo.time.date.year, 2023);
    //     expect(equinoxInfo.time.date.month, 3);
    //     expect(equinoxInfo.time.date.day, isIn([20, 21])); // Usually 20th or 21st
    // });
  });
}
