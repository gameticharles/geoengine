part of '../geojson.dart';

/// A class representing a GeoJSON Point.
///
/// A Point object represents a single location in coordinate space.
/// The [coordinates] property of the Point object is an array of length 2
/// (for 2D points), with the first element being the longitude and the
/// second element being the latitude.
class GeoJSONPoint implements GeoJSONGeometry {
  @override
  GeoJSONType type = GeoJSONType.point;

  /// The coordinates of this Point, represented as an array of doubles.
  var coordinates = <double>[];

  @override
  double get area => 0.0;

  @override
  List<double> get bbox => [
        coordinates[0],
        coordinates[1],
        coordinates[0],
        coordinates[1],
      ];

  @override
  double get distance => 0.0;

  /// Constructs a GeoJSONPoint from the provided list of [coordinates].
  GeoJSONPoint(this.coordinates)
      : assert(
            coordinates.length >= 2,
            'The coordinates is List<double>. '
            'There MUST be two or more elements');

  /// Constructs a GeoJSONPoint from a Map.
  factory GeoJSONPoint.fromMap(Map<String, dynamic> map) {
    assert(map.containsKey('type'), 'There MUST be contains key `type`');
    assert(['Point'].contains(map['type']), 'Invalid type');
    assert(map.containsKey('coordinates'),
        'There MUST be contains key `coordinates`');
    assert(map['coordinates'] is List, 'There MUST be List of double');
    final ll = map['coordinates'];
    assert((ll as List).length > 1, 'There MUST be two or more element');
    final pos = ll.map((e) => e.toDouble()).cast<double>().toList();
    return GeoJSONPoint(pos);
  }

  /// Constructs a GeoJSONPoint from a JSON string.
  factory GeoJSONPoint.fromJSON(String source) =>
      GeoJSONPoint.fromMap(json.decode(source));

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': type.value,
      'coordinates': coordinates,
    };
  }

  @override
  String toJSON({int indent = 0}) {
    if (indent > 0) {
      return JsonEncoder.withIndent(' ' * indent).convert(toMap());
    } else {
      return json.encode(toMap());
    }
  }

  @override
  String toString() => 'GeoJSONPoint(type: $type, coordinates: $coordinates)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    if (other is GeoJSONPoint) {
      return type == type && doubleListsEqual(coordinates, other.coordinates);
    }
    return false;
  }

  @override
  int get hashCode =>
      type.hashCode ^
      coordinates.fold(0, (hash, value) => hash ^ value.hashCode);
}
