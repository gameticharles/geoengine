var _D2R = 0.01745329251994329577;

double _d2r(double input) {
  return input * _D2R;
}

void _rename(Map<String, dynamic> obj, List<dynamic> params) {
  var outName = params[0];
  var inName = params[1];
  if (!(obj.containsKey(outName)) && (obj.containsKey(inName))) {
    obj[outName] = obj[inName];
    if (params.length == 3) {
      obj[outName] = params[2](obj[outName]);
    }
  }
}

void cleanWKT(Map<String, dynamic> wkt) {
  double toMeter(double input) {
    var ratio = wkt['to_meter'] ?? 1.0;
    return input * ratio;
  }

  void renamer(List<dynamic> a) {
    return _rename(wkt, a);
  }

  if (wkt['type'] == 'GEOGCS') {
    wkt['projName'] = 'longlat';
  } else if (wkt['type'] == 'LOCAL_CS') {
    wkt['projName'] = 'identity';
    wkt['local'] = true;
  } else {
    if (wkt['PROJECTION'] is Map<String, dynamic>) {
      wkt['projName'] = (wkt['PROJECTION'] as Map<String, dynamic>).keys.first;
    } else {
      wkt['projName'] = wkt['PROJECTION'];
    }
  }
  if (wkt['AXIS'] != null) {
    var axisOrder = '';
    for (var i = 0; i < wkt['AXIS'].length; i++) {
      var axis = wkt['AXIS'][i];
      var descriptor = axis[0].toLowerCase();
      if (descriptor.contains('north')) {
        axisOrder += 'n';
      } else if (descriptor.contains('south')) {
        axisOrder += 's';
      } else if (descriptor.contains('east')) {
        axisOrder += 'e';
      } else if (descriptor.contains('west')) {
        axisOrder += 'w';
      }
    }
    if (axisOrder.length == 2) {
      axisOrder += 'u';
    }
    if (axisOrder.length == 3) {
      wkt['axis'] = axisOrder;
    }
  }
  if (wkt['UNIT'] != null) {
    wkt['units'] = wkt['UNIT']['name'].toLowerCase();
    if (wkt['units'] == 'metre') {
      wkt['units'] = 'meter';
    }
    if (wkt['UNIT']['convert'] != null) {
      if (wkt['type'] == 'GEOGCS') {
        if (wkt['DATUM'] != null && wkt['DATUM']['SPHEROID'] != null) {
          wkt['to_meter'] =
              wkt['UNIT']['convert'] * wkt['DATUM']['SPHEROID']['a'];
        }
      } else {
        wkt['to_meter'] = wkt['UNIT']['convert'];
      }
    }
  }
  var geogcs = wkt['GEOGCS'];
  if (wkt['type'] == 'GEOGCS') {
    geogcs = wkt;
  }
  if (geogcs != null) {
    //if(wkt['GEOGCS'].PRIMEM&&wkt['GEOGCS'].PRIMEM['convert']){
    //  wkt.from_greenwich=wkt['GEOGCS'].PRIMEM['convert']*D2R;
    //}
    if (geogcs['DATUM'] != null) {
      wkt['datumCode'] = geogcs['DATUM']['name'].toLowerCase();
    } else {
      wkt['datumCode'] = geogcs['name'].toLowerCase();
    }
    if (wkt['datumCode'].toString().startsWith('d_')) {
      wkt['datumCode'] = wkt['datumCode']
          .toString()
          .substring(2, wkt['datumCode'].toString().length);
    }
    if (wkt['datumCode'] == 'new_zealand_geodetic_datum_1949' ||
        wkt['datumCode'] == 'new_zealand_1949') {
      wkt['datumCode'] = 'nzgd49';
    }
    if (wkt['datumCode'] == 'wgs_1984' ||
        wkt['datumCode'] == 'world_geodetic_system_1984') {
      if (wkt['PROJECTION'] == 'Mercator_Auxiliary_Sphere') {
        wkt['sphere'] = true;
      }
      wkt['datumCode'] = 'wgs84';
    }
    if (wkt['datumCode'].toString().length >= 6 &&
        wkt['datumCode'].toString().substring(
                wkt['datumCode'].toString().length - 6,
                wkt['datumCode'].toString().length) ==
            '_ferro') {
      wkt['datumCode'] = wkt['datumCode']
          .toString()
          .substring(0, wkt['datumCode'].toString().length - 6);
    }
    if (wkt['datumCode'].toString().length >= 8 &&
        wkt['datumCode'].toString().substring(
                wkt['datumCode'].toString().length - 8,
                wkt['datumCode'].toString().length) ==
            '_jakarta') {
      wkt['datumCode'] = wkt['datumCode']
          .toString()
          .substring(0, wkt['datumCode'].toString().length - 8);
    }
    if (wkt['datumCode'].toString().contains('belge')) {
      wkt['datumCode'] = 'rnb72';
    }
    if (geogcs['DATUM'] != null && geogcs['DATUM']['SPHEROID'] != null) {
      wkt['ellps'] = geogcs['DATUM']['SPHEROID']['name']
          .toString()
          .replaceAll('_19', '')
          .toString()
          .replaceAllMapped(RegExp(r'[Cc]larke\_18'), (match) => 'clrk');
      var ellps = wkt['ellps'].toString().toLowerCase();
      if (ellps.length >= 13 && ellps.substring(0, 13) == 'international') {
        wkt['ellps'] = 'intl';
      }
      wkt['a'] = geogcs['DATUM']['SPHEROID']['a'];
      wkt['rf'] = double.parse(geogcs['DATUM']['SPHEROID']['rf'].toString());
    }

    if (geogcs['DATUM'] != null && geogcs['DATUM']['TOWGS84'] != null) {
      wkt['datum_params'] = geogcs['DATUM']['TOWGS84'];
    }
    if (wkt['datumCode'].toString().contains('osgb_1936')) {
      wkt['datumCode'] = 'osgb36';
    }
    if (wkt['datumCode'].toString().contains('osni_1952')) {
      wkt['datumCode'] = 'osni52';
    }
    if (wkt['datumCode'].toString().contains('tm65') ||
        wkt['datumCode'].toString().contains('geodetic_datum_of_1965')) {
      wkt['datumCode'] = 'ire65';
    }
    if (wkt['datumCode'] == 'ch1903+') {
      wkt['datumCode'] = 'ch1903';
    }
    if (wkt['datumCode'].toString().contains('israel')) {
      wkt['datumCode'] = 'isr93';
    }
  }
  if (wkt['b'] != null && !double.parse(wkt['b']).isFinite) {
    wkt['b'] = wkt['a'];
  }

  var list = [
    ['standard_parallel_1', 'Standard_Parallel_1'],
    ['standard_parallel_2', 'Standard_Parallel_2'],
    ['false_easting', 'False_Easting'],
    ['false_northing', 'False_Northing'],
    ['central_meridian', 'Central_Meridian'],
    ['latitude_of_origin', 'Latitude_Of_Origin'],
    ['latitude_of_origin', 'Central_Parallel'],
    ['scale_factor', 'Scale_Factor'],
    ['k0', 'scale_factor'],
    ['latitude_of_center', 'Latitude_Of_Center'],
    ['latitude_of_center', 'Latitude_of_center'],
    ['lat0', 'latitude_of_center', _d2r],
    ['longitude_of_center', 'Longitude_Of_Center'],
    ['longitude_of_center', 'Longitude_of_center'],
    ['longc', 'longitude_of_center', _d2r],
    ['x0', 'false_easting', toMeter],
    ['y0', 'false_northing', toMeter],
    ['long0', 'central_meridian', _d2r],
    ['lat0', 'latitude_of_origin', _d2r],
    ['lat0', 'standard_parallel_1', _d2r],
    ['lat1', 'standard_parallel_1', _d2r],
    ['lat2', 'standard_parallel_2', _d2r],
    ['azimuth', 'Azimuth'],
    ['alpha', 'azimuth', _d2r],
    ['srsCode', 'name']
  ];
  list.forEach(renamer);
  if (wkt['long0'] == null &&
      wkt['longc'] != null &&
      (wkt['projName'] == 'Albers_Conic_Equal_Area' ||
          wkt['projName'] == 'Lambert_Azimuthal_Equal_Area')) {
    wkt['long0'] = wkt['longc'];
  }
  if (wkt['lat_ts'] == null &&
      wkt['lat1'] != null &&
      (wkt['projName'] == 'Stereographic_South_Pole' ||
          wkt['projName'] == 'Polar Stereographic (variant B)')) {
    wkt['lat0'] = _d2r(wkt['lat1'] > 0 ? 90 : -90);
    wkt['lat_ts'] = wkt['lat1'];
  }
}
