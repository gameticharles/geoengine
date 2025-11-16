import 'dart:convert';

class ProjWKT {
  // All parameters (also without getters)
  Map<String, dynamic> map;

  @override
  String toString() => jsonEncode(map);

  String? get type => map['type']; // valid WKT never returns null
  String? get name => map['name']; // valid WKT never returns null
  Map<String, dynamic>? get GEOGCS => map['GEOGCS'];
  String? get PROJECTION => map['PROJECTION'];
  double? get latitude_of_center => map['latitude_of_center'];
  double? get longitude_of_center => map['longitude_of_center'];
  double? get azimuth => map['azimuth'];
  double? get central_meridian => map['central_meridian'];
  double? get rectified_grid_angle => map['rectified_grid_angle'];
  double? get scale_factor => map['scale_factor'];
  double? get false_easting => map['false_easting'];
  double? get false_northing => map['false_northing'];
  Map<String, dynamic>? get UNIT => map['UNIT']; // valid WKT never returns null
  List<List<dynamic>>? get AXIS => map['AXIS'];
  Map<String, dynamic>? get EXTENSION => map['EXTENSION'];
  Map<String, dynamic>? get AUTHORITY => map['AUTHORITY'];
  String? get projName => map['projName']; // valid WKT never returns null
  String? get units => map['units']; // valid WKT never returns null
  double? get to_meter => map['to_meter']; // valid WKT never returns null
  String? get datumCode => map['datumCode']; // valid WKT never returns null
  String? get ellps => map['ellps']; // valid WKT never returns null
  double? get a => map['a']; // valid WKT never returns null
  double? get rf => map['rf']; // valid WKT never returns null
  List<dynamic>? get datum_params => map['datum_params'];
  double? get k0 => map['k0'];
  double? get lat0 => map['lat0'];
  double? get long0 => map['long0'];
  double? get longc => map['longc'];
  double? get x0 => map['x0'];
  double? get y0 => map['y0'];
  double? get alpha => map['alpha'];
  String? get srsCode => map['srsCode']; // valid WKT never returns null

  ProjWKT(this.map);
}
