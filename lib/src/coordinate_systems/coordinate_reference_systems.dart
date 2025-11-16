library;

import 'package:advance_math/advance_math.dart' hide Point;

import 'points/points.dart';
import 'proj4dart/proj4dart.dart';
import 'proj4dart/common/datum_utils.dart' as datum_utils;
import 'proj4dart/common/utils.dart' as utils;
import 'proj4dart/constants/values.dart' as consts;

export 'package:geoengine/src/coordinate_systems/points/points.dart';
export 'package:geoengine/src/coordinate_systems/proj4dart/proj4dart.dart';

part 'trans_engine.dart';
part 'utm_zones.dart';
part 'enums.dart';
part 'info.dart';

part 'units/angular.dart';
part 'units/linear.dart';

part 'ellipsoid/ellipsoid.dart';
part 'ellipsoid/utm_ellipsoid.dart';

part 'prime_meridian.dart';
// part 'datum_types.dart';
// part 'crs.dart';
// part 'crs/coordinate_system.dart';
// part 'wgs84_conversion_info.dart';
// part 'horizontal_datum.dart';
// part 'projection.dart';
// part 'crs/horizontal_coordinate_system.dart';
// part 'crs/geographic_coordinate_system.dart';
// part 'crs/geocentric_coordinate_system.dart';
// part 'projected_coordinate_system.dart';
// part 'crs/fitted_coordinate_system.dart';
part 'transformation_parameters.dart';

// part 'axis_info/axis_info.dart';
// part 'axis_info/axis_orientation.dart';
