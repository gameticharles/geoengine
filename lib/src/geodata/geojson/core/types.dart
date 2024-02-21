part of '../geojson.dart';

/// Enumerates the types of geometries that can be used in a GeoJSON object.
///
/// Each enum value corresponds to one of the geometry types defined in the GeoJSON specification.
/// The enum provides a straightforward way to represent these types and their string representations.
enum GeoJSONType {
  /// Represents a GeoJSON FeatureCollection.
  ///
  /// A FeatureCollection is a collection of Features.
  featureCollection('FeatureCollection'),

  /// Represents a single GeoJSON Feature.
  ///
  /// A Feature is a single spatially bounded entity.
  feature('Feature'),

  /// Represents a GeoJSON Point geometry.
  ///
  /// A Point is a single location in coordinate space.
  point('Point'),

  /// Represents a GeoJSON MultiPoint geometry.
  ///
  /// A MultiPoint is a collection of Points.
  multiPoint('MultiPoint'),

  /// Represents a GeoJSON LineString geometry.
  ///
  /// A LineString is a series of connected points forming a line.
  lineString('LineString'),

  /// Represents a GeoJSON MultiLineString geometry.
  ///
  /// A MultiLineString is a collection of LineStrings.
  multiLineString('MultiLineString'),

  /// Represents a GeoJSON Polygon geometry.
  ///
  /// A Polygon is a planar area defined by a series of linear rings.
  polygon('Polygon'),

  /// Represents a GeoJSON MultiPolygon geometry.
  ///
  /// A MultiPolygon is a collection of Polygons.
  multiPolygon('MultiPolygon'),

  /// Represents a GeoJSON GeometryCollection.
  ///
  /// A GeometryCollection is a collection of different geometries.
  geometryCollection('GeometryCollection');

  /// The string representation of the GeoJSON geometry type.
  ///
  /// This corresponds to the type names as defined in the GeoJSON specification.
  final String value;

  /// Constructs a GeoJSONType enum value with the given [value] representing
  /// the GeoJSON geometry type as a string.
  const GeoJSONType(this.value);

  @override
  String toString() => value;
}
