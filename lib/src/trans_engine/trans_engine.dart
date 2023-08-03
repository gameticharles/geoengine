// ignore_for_file: implementation_imports

part of geoengine;

class CoordinateConversion {
  CoordinateConversion();

  /// Check if the given conversion type is valid.
  ///
  /// [type]: The conversion type to check.
  /// Returns true if the type is either `consts.PJD_3PARAM` or `consts.PJD_7PARAM`, otherwise false.
  bool checkParams(int type) {
    return (type == consts.PJD_3PARAM || type == consts.PJD_7PARAM);
  }

  /// Get the conversion type from the source coordinate type to the target coordinate type.
  ///
  /// [sourceCoordinateType]: The source coordinate type.
  /// [targetCoordinateType]: The target coordinate type.
  /// Returns the `ConversionType` enum representing the conversion type.
  ConversionType getConversionType(CoordinateType sourceCoordinateType,
      CoordinateType targetCoordinateType) {
    var conversionType = ConversionType.geodeticToGeodetic;

    String conv =
        '${sourceCoordinateType.toString().split('.')[1].toLowerCase()}To${targetCoordinateType.toString().split('.')[1].capitalize()}';

    conversionType = ConversionType.values
        .firstWhere((e) => e.toString().split('.')[1] == conv);

    return conversionType;
  }

  /// Convert a point from radians to degrees.
  ///
  /// [point]: The input point in radians.
  /// Returns the converted point in degrees.
  Point convertR2D(Point point) {
    return Point.withZ(
      x: toDegrees(point.x),
      y: toDegrees(point.y),
      z: point.z ?? 0.0,
    );
  }

  /// Convert a point from degrees to radians.
  ///
  /// [point]: The input point in degrees.
  /// Returns the converted point in radians.
  Point convertD2R(Point point) {
    return Point.withZ(
      x: toRadians(point.x),
      y: toRadians(point.y),
      z: point.z ?? 0,
    );
  }

  /// Compute the convergence at a given point.
  ///
  /// [latitude]: Latitude of the point.
  /// [longitude]: Longitude of the point.
  /// [longOfOrigin]: Longitude of the origin from the grid.
  /// Returns the computed convergence.
  double getConvergence(
      double latitude, double longitude, double longOfOrigin) {
    // Compute convergence(γ)
    /*
      γ = arctan [tan (λ - λ0) × sin φ]

      where

      γ is grid convergence,
      λ0 is longitude of UTM zone's central meridian,
      φ, λ are latitude, longitude of point in question
    */

    var conv = toDegrees(atan(
        tan(toRadians(longitude - longOfOrigin)) * sin(toRadians(latitude))));
    return conv;
  }

  /// Compute the grid scale at a given point.
  ///
  /// [e2]: Eccentricity.
  /// [latitude]: Latitude of the point.
  /// [longitude]: Longitude of the point.
  /// [longOfOrigin]: Longitude of the origin from the grid.
  /// [scale]: Scale from the grid.
  /// Returns the computed grid scale.
  double getGridScale(double e2, double latitude, double longitude,
      double longOfOrigin, double scale) {
    // Compute Grid scale at a point
    // k = ko[1+(1+C)A2/2+(5-4T+42C+13C2-28e'2)A4/24+(61-148T+16T2)A6/720)
    // C = e'2 * cos^2(ϕ)
    // T = tan^2(ϕ)
    // A = cos(ϕ) * (λ - λo)
    var ep2 = e2 / (1 - e2); // e'2
    var T = pow(tan(toRadians(latitude)), 2);
    var C = pow(cos(toRadians(latitude)), 2) * ep2;
    var A = cos(toRadians(latitude)) *
        (toRadians(longitude) - toRadians(longOfOrigin));
    return scale *
        (1 +
            ((1 + C) * pow(A, 2)) / 2 +
            ((5 - 4 * T + 42 * C + 13 * pow(C, 2) - 28 * ep2) * pow(A, 4)) /
                24 +
            ((61 - 148 * T + 16 * pow(T, 2)) * pow(A, 6)) / 720);
  }

  /// Get the UTM projection based on the longitude.
  ///
  /// [longitude]: The longitude of the point.
  /// Returns the UTM projection.
  Projection getUTMProjection(double longitude) {
    var centralMeridian = UTMZones().getLongZone(longitude);
    return Projection.parse(
        "PROJCS[\"WGS 84 / UTM \",GEOGCS[\"WGS 84\",DATUM[\"WGS_1984\",SPHEROID[\"WGS 84\",6378137,298.257223563,AUTHORITY[\"EPSG\",\"7030\"]],AUTHORITY[\"EPSG\",\"6326\"]],PRIMEM[\"Greenwich\",0,AUTHORITY[\"EPSG\",\"8901\"]],UNIT[\"toDegrees\",0.0174532925199433,AUTHORITY[\"EPSG\",\"9122\"]],AUTHORITY[\"EPSG\",\"4326\"]],PROJECTION[\"Transverse_Mercator\"],PARAMETER[\"latitude_of_origin\",0],PARAMETER[\"central_meridian\",$centralMeridian],PARAMETER[\"scale_factor\",0.9996],PARAMETER[\"false_easting\",500000],PARAMETER[\"false_northing\",0],UNIT[\"metre\",1,AUTHORITY[\"EPSG\",\"9001\"]],AXIS[\"Easting\",EAST],AXIS[\"Northing\",NORTH],AUTHORITY[\"EPSG\",\"200000\"]]");
    // return Projection.add("EPSG:${200500 + centralMeridian}",
    //       "PROJCS[\"WGS 84 / UTM \",GEOGCS[\"WGS 84\",DATUM[\"WGS_1984\",SPHEROID[\"WGS 84\",6378137,298.257223563,AUTHORITY[\"EPSG\",\"7030\"]],AUTHORITY[\"EPSG\",\"6326\"]],PRIMEM[\"Greenwich\",0,AUTHORITY[\"EPSG\",\"8901\"]],UNIT[\"toDegrees\",0.0174532925199433,AUTHORITY[\"EPSG\",\"9122\"]],AUTHORITY[\"EPSG\",\"4326\"]],PROJECTION[\"Transverse_Mercator\"],PARAMETER[\"latitude_of_origin\",0],PARAMETER[\"central_meridian\",$centralMeridian],PARAMETER[\"scale_factor\",0.9996],PARAMETER[\"false_easting\",500000],PARAMETER[\"false_northing\",0],UNIT[\"metre\",1,AUTHORITY[\"EPSG\",\"9001\"]],AXIS[\"Easting\",EAST],AXIS[\"Northing\",NORTH],AUTHORITY[\"EPSG\",\"200000\"]]");
  }

  /// Convert a point from geocentric coordinates to geocentric coordinates of another CRS.
  ///
  /// [point]: The input point in geocentric coordinates.
  /// [projSrc]: The source CRS projection.
  /// [projDst]: The target CRS projection.
  /// Returns the converted point in geocentric coordinates of the target CRS.
  Point geocentricToGeocentric(
      {required Point point,
      required Projection projSrc,
      required Projection projDst}) {
    var p = point;

    if (!datum_utils.compareDatums(projSrc.datum, Projection.WGS84.datum)) {
      p = datum_utils.geocentricToWgs84(
          point, projSrc.datum.datumType, projSrc.datum.datumParams);
    }

    return (!datum_utils.compareDatums(projDst.datum, Projection.WGS84.datum))
        ? datum_utils.geocentricFromWgs84(
            p, projDst.datum.datumType, projDst.datum.datumParams)
        : p;
  }

  /// Convert a point from geocentric coordinates to geodetic coordinates.
  ///
  /// [point]: The input point in geocentric coordinates.
  /// [projSrc]: The source CRS projection.
  /// [projDst]: The target CRS projection.
  /// Returns the converted point in geodetic coordinates.
  Point geocentricToGeodetic(
      {required Point point,
      required Projection projSrc,
      required Projection projDst}) {
    var p = point;

    if (!datum_utils.compareDatums(projSrc.datum, projDst.datum)) {
      p = geocentricToGeocentric(
          point: point, projSrc: projSrc, projDst: projDst);
    }

    p = datum_utils.geocentricToGeodetic(p, projDst.es, projDst.a, projDst.b);

    return convertR2D(p);
  }

  /// Convert a point from geodetic coordinates to geodetic coordinates of another CRS.
  ///
  /// [point]: The input point in geodetic coordinates.
  /// [projSrc]: The source CRS projection.
  /// [projDst]: The target CRS projection.
  /// Returns the converted point in geodetic coordinates of the target CRS.
  Point geodeticToGeodetic(
      {required Point point,
      required Projection projSrc,
      required Projection projDst}) {
    var p = point;

    if (!datum_utils.compareDatums(projSrc.datum, projDst.datum)) {
      var pc = geodeticToGeocentric(point: point, projection: projSrc);

      var cc =
          geocentricToGeocentric(point: pc, projSrc: projSrc, projDst: projDst);

      p = datum_utils.geocentricToGeodetic(
          cc, projDst.es, projDst.a, projDst.b);

      p = convertR2D(p);
    }

    return p;
  }

  /// Convert a point from geodetic coordinates to geocentric coordinates in meters.
  ///
  /// [point]: The input point in geodetic coordinates.
  /// [projection]: The CRS projection.
  /// Returns the converted point in geocentric coordinates in meters.
  Point geodeticToGeocentric(
      {required Point point, required Projection projection}) {
    return datum_utils.geodeticToGeocentric(
        convertD2R(point), projection.es, projection.a);
  }

  /// Convert a point from geodetic coordinates to projected coordinates (ENZ).
  ///
  /// [point]: The input point in geodetic coordinates.
  /// [projection]: The CRS projection.
  /// Returns the converted point in projected coordinates.
  Point geodeticToProjected(
      {required Point point, required Projection projection}) {
    point = projection.forward(convertD2R(point));

    // Convert from meters to CRS units conversion
    if (projection.to_meter != null) {
      point = Point.withZ(
          x: point.x / projection.to_meter!,
          y: point.y / projection.to_meter!,
          z: point.z ?? 0.0);
    }

    return point;
  }

  /// Convert a point from projected coordinates (ENZ) to geodetic coordinates.
  ///
  /// [point]: The input point in projected coordinates.
  /// [projection]: The CRS projection.
  /// Returns the converted point in geodetic coordinates.
  Point projectedToGeodetic(
      {required Point point, required Projection projection}) {
    // Convert from CRS units conversion to meters
    if (projection.to_meter != null) {
      point = Point.withZ(
          x: point.x * projection.to_meter!,
          y: point.y * projection.to_meter!,
          z: point.z ?? 0.0);
    }

    point = projection.inverse(point);

    return convertR2D(point);
  }

  /// Perform a coordinate conversion based on the given parameters.
  ///
  /// [point]: The input point to be converted.
  /// [projSrc]: The source CRS projection.
  /// [projDst]: The target CRS projection.
  /// [conversion]: The type of conversion to be performed.
  /// [isProjection]: If true, indicates that the source and target projections are the same (used internally).
  /// Returns the converted point with the updated CRS and type information.
  PointX convert({
    required PointX point,
    required Projection projSrc,
    required Projection projDst,
    required ConversionType conversion,
    bool isProjection = false,
  }) {
    Point result = Point.withZ(x: 0, y: 0, z: 0);

    // Check for correct values
    utils.checkSanity(point.toPoint());

    if (isProjection) projDst = projSrc;

    switch (conversion) {
      case ConversionType.geocentricToGeocentric:
        result = geocentricToGeocentric(
            point: point.toPoint(), projSrc: projSrc, projDst: projDst);
        break;
      case ConversionType.geocentricToGeodetic:
        result = geocentricToGeodetic(
            point: point.toPoint(), projSrc: projSrc, projDst: projDst);
        break;
      case ConversionType.geocentricToProjected:
        var cg = geocentricToGeodetic(
            point: point.toPoint(), projSrc: projSrc, projDst: projDst);
        result = geodeticToProjected(point: cg, projection: projDst);
        break;

      case ConversionType.geodeticToGeocentric:
        var pc =
            geodeticToGeocentric(point: point.toPoint(), projection: projSrc);
        result = geocentricToGeocentric(
            point: pc, projSrc: projSrc, projDst: projDst);
        break;
      case ConversionType.geodeticToGeodetic:
        result = geodeticToGeodetic(
            point: point.toPoint(), projSrc: projSrc, projDst: projDst);
        break;
      case ConversionType.geodeticToProjected:
        var gg = geodeticToGeodetic(
            point: point.toPoint(), projSrc: projSrc, projDst: projDst);
        result = geodeticToProjected(point: gg, projection: projDst);
        break;

      case ConversionType.projectedToGeocentric:
        var pg =
            projectedToGeodetic(point: point.toPoint(), projection: projSrc);
        var pc = geodeticToGeocentric(point: pg, projection: projSrc);
        result = geocentricToGeocentric(
            point: pc, projSrc: projSrc, projDst: projDst);
        break;
      case ConversionType.projectedToGeodetic:
        var pg =
            projectedToGeodetic(point: point.toPoint(), projection: projSrc);
        result =
            geodeticToGeodetic(point: pg, projSrc: projSrc, projDst: projDst);
        break;
      case ConversionType.projectedToProjected:
        var pg =
            projectedToGeodetic(point: point.toPoint(), projection: projSrc);
        var gg =
            geodeticToGeodetic(point: pg, projSrc: projSrc, projDst: projDst);
        result = geodeticToProjected(point: gg, projection: projDst);
        break;

      default:
        result = projSrc.transform(projDst, point.toPoint());
        break;
    }
    return point.copyWith(
      x: result.x,
      y: result.y,
      //z: result.z,
      z: conversion.name.contains('Geodetic') ||
              conversion.name.contains('Geocentric') ||
              projDst.to_meter == null
          ? result.z!
          : result.z! / projDst.to_meter!,
      crs: projDst,
      type: CoordinateType.values.firstWhere((e) =>
          e.toString().split('.')[1] ==
          conversion.toString().split('To')[1].toLowerCase()),
    );
  }
}
