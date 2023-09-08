// ignore_for_file: depend_on_referenced_packages

part of geoengine;

enum PointXPart { name, x, y, z }

class PointX extends Point {
  CoordinateType? type;
  String? status;
  String? name;
  String? desc;
  String? country;
  String? crsCode;
  Projection? crs;
  bool selected;

  PointX({
    required double x,
    required double y,
    double? z,
    double? m,
    this.type,
    this.status,
    this.name,
    this.desc,
    this.country,
    this.crsCode,
    this.crs,
    this.selected = false,
  }) : super.withM(x: x, y: y, z: z, m: m);

  PointX.withM(
      {required double x,
      required double y,
      required double z,
      required double m,
      this.selected = false,
      this.name,
      this.desc,
      this.country,
      this.crsCode,
      this.crs,
      this.status,
      this.type})
      : super.withM(x: x, y: y, z: z, m: m);

  PointX.newPoint()
      : name = '',
        desc = '',
        selected = false,
        super.withZ(x: 0, y: 0, z: 0);

  @override
  PointX copyWith({
    double? x,
    double? y,
    double? z,
    double? m,
    String? name,
    CoordinateType? type,
    String? status,
    String? desc,
    String? country,
    String? crsCode,
    Projection? crs,
  }) {
    return PointX(
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      m: m ?? this.m,
      name: name ?? this.name,
      type: type ?? this.type,
      desc: desc ?? this.desc,
      status: status ?? this.status,
      country: country ?? this.country,
      crsCode: crsCode ?? this.crsCode,
      crs: crs ?? this.crs,
    );
  }

  factory PointX.fromString(String coordsString) {
    var coords = coordsString.split(',');
    var x = double.parse(coords[0]);
    var y = double.parse(coords[1]);
    var z = coords.length > 2 ? double.parse(coords[2]) : null;
    var m = coords.length > 3 ? double.parse(coords[3]) : null;

    return PointX.withM(x: x, y: y, z: z!, m: m!);
  }

  Point toPoint() {
    return Point.withZ(x: x, y: y, z: z);
  }

  List<dynamic> toDataArray() {
    var res = [name, x, y];
    if (z != null) {
      res.add(z!);

      if (m != null) {
        res.add(m!);
      }
    }
    return res;
  }

  dynamic getValue(PointXPart part) {
    return part == PointXPart.name
        ? name
        : part == PointXPart.x
            ? x
            : part == PointXPart.y
                ? y
                : z;
  }

  dynamic setValue(PointXPart part, String newValue) {
    part == PointXPart.name
        ? name = newValue
        : part == PointXPart.x
            ? x = double.parse(newValue)
            : part == PointXPart.y
                ? y = double.parse(newValue)
                : z = double.parse(newValue);
  }

  @override
  String toString() {
    var headerLabels =
        type == null ? ["x", "y", "z"] : getCoordinateHeaderLabels(type!);

    return """
${headerLabels[0]}: $x
${headerLabels[1]}: $y
${headerLabels[2]}: $z
${m == null ? "" : "m: $m"}
crsCode: $crsCode
name: $name
description: $desc
Coordinate type: ${type!.name}
""";
  }
}
