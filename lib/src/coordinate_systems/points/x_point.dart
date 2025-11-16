// ignore_for_file: depend_on_referenced_packages

part of 'points.dart';

/// An extension of the Point class with additional properties and functionalities.
///
/// This class extends the basic Point class by adding additional fields
/// and methods that are useful for geospatial data handling. It allows for
/// more detailed point information including metadata like name, description,
/// country, coordinate reference system (CRS), etc.
class PointX extends Point {
  CoordinateType? type;
  String? status;

  /// The name of the point. This field will be transferred to and from
  /// the conversion.
  String? name;

  /// A text description of the element. Holds additional information about the
  /// element intended for the user.
  String? desc;
  String? country;
  String? crsCode;

  Projection? crs;
  bool selected;

  /// Creates an instance of PointX with specified coordinates and metadata.
  ///
  /// [x], [y]: The x and y coordinates of the point.
  /// [z]: The z coordinate of the point (optional).
  /// [m]: The m value of the point (optional).
  /// [type]: The type of coordinates.
  /// [status]: The status associated with the point.
  /// [name]: The name of the point.
  /// [desc]: The description of the point.
  /// [country]: The country associated with the point.
  /// [crsCode]: The code of the coordinate reference system.
  /// [crs]: The coordinate reference system.
  /// [selected]: A flag indicating whether the point is selected.
  PointX({
    required super.x,
    required super.y,
    super.z,
    super.m,
    this.type,
    this.status,
    this.name,
    this.desc,
    this.country,
    this.crsCode,
    this.crs,
    this.selected = false,
  }) : super.withM();

  /// Constructs an instance of PointX with specified coordinates and properties.
  ///
  /// This constructor is used when all coordinates (x, y, z, and m) are known.
  ///
  /// [x]: The x-coordinate of the point.
  /// [y]: The y-coordinate of the point.
  /// [z]: The z-coordinate of the point.
  /// [m]: The m-value of the point.
  /// [selected]: (Optional) Indicates whether the point is selected. Defaults to false.
  /// [name]: (Optional) The name of the point.
  /// [desc]: (Optional) A description of the point.
  /// [country]: (Optional) The country associated with the point.
  /// [crsCode]: (Optional) The code of the coordinate reference system.
  /// [crs]: (Optional) The coordinate reference system.
  /// [status]: (Optional) The status associated with the point.
  /// [type]: (Optional) The type of coordinates.
  PointX.withM(
      {required super.x,
      required super.y,
      required double super.z,
      required double super.m,
      this.selected = false,
      this.name,
      this.desc,
      this.country,
      this.crsCode,
      this.crs,
      this.status,
      this.type})
      : super.withM();

  /// Constructs a new PointX with default values.
  ///
  /// This constructor creates a point at the origin (0,0,0) with default values
  /// for other properties.
  ///
  /// It's useful for creating a starting point or a placeholder.
  PointX.newPoint()
      : name = '',
        desc = '',
        selected = false,
        super.withZ(x: 0, y: 0, z: 0);

  /// Copies the current PointX instance and overrides it with given values.
  ///
  /// Returns a new instance of PointX with updated values.
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

  /// Constructs a PointX from a string representation of coordinates.
  ///
  /// The string should contain coordinates separated by commas.
  /// For example: "1.23,4.56,7.89" for x, y, and z coordinates.
  ///
  /// [coordsString]: A string representing the coordinates.
  factory PointX.fromString(String coordsString) {
    var coords = coordsString.split(',');
    var x = double.parse(coords[0]);
    var y = double.parse(coords[1]);
    var z = coords.length > 2 ? double.parse(coords[2]) : null;
    var m = coords.length > 3 ? double.parse(coords[3]) : null;

    return PointX.withM(x: x, y: y, z: z!, m: m!);
  }

  /// Converts the PointX instance to a LatLng object.
  ///
  /// Returns a LatLng object representing the same geographical location.
  LatLng asLatLng() {
    return LatLng(y, x, z);
  }

  /// Converts the PointX instance to a Point object.
  ///
  /// Returns a Point object with the same x, y, and z coordinates.
  Point toPoint() {
    return Point.withZ(x: x, y: y, z: z);
  }

  /// Converts the PointX instance into a data array.
  ///
  /// Returns a list containing the point's name, x, y, z, and m values.
  /// The z and m values are included only if they are not null.
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

  /// Gets the value of a specified part of the PointX instance.
  ///
  /// [part]: The part of the PointX for which the value is required.
  ///
  /// Returns the value of the specified part.
  dynamic getValue(PointXPart part) {
    return part == PointXPart.name
        ? name
        : part == PointXPart.x
            ? x
            : part == PointXPart.y
                ? y
                : z;
  }

  /// Sets the value of a specified part of the PointX instance.
  ///
  /// [part]: The part of the PointX to be set.
  /// [newValue]: The new value to be set for the specified part.
  ///
  /// Updates the specified part of the PointX with the new value.
  dynamic setValue(PointXPart part, String newValue) {
    part == PointXPart.name
        ? name = newValue
        : part == PointXPart.x
            ? x = double.parse(newValue)
            : part == PointXPart.y
                ? y = double.parse(newValue)
                : z = double.parse(newValue);
  }

  /// Returns a string representation of the PointX instance.
  ///
  /// Provides a detailed view of the point's coordinates, metadata, and other properties.
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
Coordinate type: ${type == null ? '' : type!.name}
""";
  }
}

// extension PointExtensions on Point {
//   CoordinateType? get type => null;
//   String? get status => null;
//   set status(String? value) {}

//   /// The name of the point. This field will be transferred to and from
//   /// the conversion.
//   String? get name => null;
//   set name(String? value) {}

//   /// A text description of the element. Holds additional information about the
//   /// element intended for the user.
//   String? get desc => null;
//   set desc(String? value) {}

//   String? get country => null;
//   set country(String? value) {}

//   String? get crsCode => null;
//   set crsCode(String? value) {}

//   Projection? get crs => null;
//   set crs(Projection? value) {}

//   bool get selected => false;
//   set selected(bool value) {}

//   /// Converts the PointX instance to a LatLng object.
//   ///
//   /// Returns a LatLng object representing the same geographical location.
//   LatLng asLatLng() {
//     return LatLng(y, x, z);
//   }

//   /// Converts the PointX instance to a Point object.
//   ///
//   /// Returns a Point object with the same x, y, and z coordinates.
//   Point toPoint() {
//     return Point.withZ(x: x, y: y, z: z);
//   }

//   /// Converts the PointX instance into a data array.
//   ///
//   /// Returns a list containing the point's name, x, y, z, and m values.
//   /// The z and m values are included only if they are not null.
//   List<dynamic> toDataArray() {
//     var res = [name, x, y];
//     if (z != null) {
//       res.add(z!);

//       if (m != null) {
//         res.add(m!);
//       }
//     }
//     return res;
//   }

//   /// Gets the value of a specified part of the PointX instance.
//   ///
//   /// [part]: The part of the PointX for which the value is required.
//   ///
//   /// Returns the value of the specified part.
//   dynamic getValue(PointXPart part) {
//     return part == PointXPart.name
//         ? name
//         : part == PointXPart.x
//             ? x
//             : part == PointXPart.y
//                 ? y
//                 : z;
//   }

//   /// Sets the value of a specified part of the PointX instance.
//   ///
//   /// [part]: The part of the PointX to be set.
//   /// [newValue]: The new value to be set for the specified part.
//   ///
//   /// Updates the specified part of the PointX with the new value.
//   dynamic setValue(PointXPart part, String newValue) {
//     part == PointXPart.name
//         ? name = newValue
//         : part == PointXPart.x
//             ? x = double.parse(newValue)
//             : part == PointXPart.y
//                 ? y = double.parse(newValue)
//                 : z = double.parse(newValue);
//   }
// }
