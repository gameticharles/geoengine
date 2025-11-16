Map<String, dynamic> reduceFn(Map<String, dynamic> newObj, dynamic item) {
  sExpr(item, newObj);
  return newObj;
}

void mapit(Map<String, dynamic> obj, dynamic key, List<dynamic> value) {
  if (key is List<dynamic>) {
    value.insert(0, key);
    key = null;
  }
  var thing = key != null ? <String, dynamic>{} : obj;
  var out = value.fold(
      thing, (Map<String, dynamic> newObj, item) => reduceFn(newObj, item));
  if (key != null) {
    obj[key] = out;
  }
}

void sExpr(dynamic value, Map<String, dynamic> obj) {
  if (value is! List<dynamic>) {
    obj[value] = true;
    return;
  }
  var v = value;
  var key = v.removeAt(0);
  if (key == 'PARAMETER') {
    key = v.removeAt(0);
  }
  if (v.length == 1) {
    if (v[0] is List<dynamic>) {
      obj[key] = <String, dynamic>{};
      sExpr(v[0], obj[key]);
      return;
    }
    obj[key] = v[0];
    return;
  }
  if (v.isEmpty) {
    obj[key] = true;
    return;
  }
  if (key == 'TOWGS84') {
    obj[key] = v;
    return;
  }
  if (key == 'AXIS') {
    if (!obj.containsKey(key)) {
      obj[key] = <List<dynamic>>[];
    }
    obj[key].add(v);
    return;
  }
  if (key is! List<dynamic>) {
    obj[key] = <String, dynamic>{};
  }

  switch (key) {
    case 'UNIT':
    case 'PRIMEM':
    case 'VERT_DATUM':
      obj[key] = <String, dynamic>{'name': v[0].toLowerCase(), 'convert': v[1]};
      if (v.length == 3) {
        sExpr(v[2], obj[key]);
      }
      return;
    case 'SPHEROID':
    case 'ELLIPSOID':
      obj[key] = <String, dynamic>{'name': v[0], 'a': v[1], 'rf': v[2]};
      if (v.length == 4) {
        sExpr(v[3], obj[key]);
      }
      return;
    case 'PROJECTEDCRS':
    case 'PROJCRS':
    case 'GEOGCS':
    case 'GEOCCS':
    case 'PROJCS':
    case 'LOCAL_CS':
    case 'GEODCRS':
    case 'GEODETICCRS':
    case 'GEODETICDATUM':
    case 'EDATUM':
    case 'ENGINEERINGDATUM':
    case 'VERT_CS':
    case 'VERTCRS':
    case 'VERTICALCRS':
    case 'COMPD_CS':
    case 'COMPOUNDCRS':
    case 'ENGINEERINGCRS':
    case 'ENGCRS':
    case 'FITTED_CS':
    case 'LOCAL_DATUM':
    case 'DATUM':
      v[0] = <dynamic>['name', v[0]];
      mapit(obj, key, v);
      return;
    default:
      var i = -1;
      while (++i < v.length) {
        if (v[i] is! List<dynamic>) {
          return sExpr(v, obj[key]);
        }
      }
      return mapit(obj, key, v);
  }
}
