# Spatial Operations Documentation

DartFrame provides comprehensive geospatial capabilities through enhanced GeoDataFrame and GeoSeries classes, offering pandas/geopandas-like functionality for spatial data analysis.

## Table of Contents
- [Spatial Operations Documentation](#spatial-operations-documentation)
  - [Table of Contents](#table-of-contents)
  - [Enhanced Spatial Operations](#enhanced-spatial-operations)
    - [1. Spatial Joins](#1-spatial-joins)
    - [2. Overlay Operations](#2-overlay-operations)
    - [3. Coordinate Reference System Transformations](#3-coordinate-reference-system-transformations)
    - [4. Spatial Indexing](#4-spatial-indexing)
  - [Advanced GeoSeries Operations](#advanced-geoseries-operations)
    - [1. Buffer Operations](#1-buffer-operations)
    - [2. Dissolve Operations](#2-dissolve-operations)
    - [3. Simplification](#3-simplification)
    - [4. Spatial Relationships](#4-spatial-relationships)
  - [Spatial Analysis Examples](#spatial-analysis-examples)
    - [1. Point-in-Polygon Analysis](#1-point-in-polygon-analysis)
    - [2. Distance Calculations](#2-distance-calculations)
    - [3. Spatial Clustering](#3-spatial-clustering)

## Enhanced Spatial Operations

### 1. Spatial Joins

Perform spatial joins based on geometric relationships between GeoDataFrames.

**Example:**
```dart
// Create sample data
final points = GeoDataFrame.fromCoordinates([
  [10.0, 20.0],
  [15.0, 25.0],
  [30.0, 40.0],
], attributes: DataFrame.fromRows([
  {'id': 1, 'name': 'Point A'},
  {'id': 2, 'name': 'Point B'},
  {'id': 3, 'name': 'Point C'},
]));

final polygons = GeoDataFrame.fromFeatureCollection(polygonCollection);

// Spatial join - find which polygon each point falls within
GeoDataFrame joined = points.spatialJoin(
  polygons,
  how: 'inner',
  predicate: 'within'
);

// Different spatial predicates
GeoDataFrame intersects = points.spatialJoin(
  polygons,
  predicate: 'intersects'
);

GeoDataFrame contains = polygons.spatialJoin(
  points,
  predicate: 'contains'
);
```

### 2. Overlay Operations

Perform overlay operations like intersection, union, and difference between GeoDataFrames.

**Example:**
```dart
final gdf1 = GeoDataFrame.fromFeatureCollection(collection1);
final gdf2 = GeoDataFrame.fromFeatureCollection(collection2);

// Intersection - areas where both geometries overlap
GeoDataFrame intersection = gdf1.overlay(gdf2, how: 'intersection');

// Union - combined area of both geometries
GeoDataFrame union = gdf1.overlay(gdf2, how: 'union');

// Difference - areas in gdf1 that don't overlap with gdf2
GeoDataFrame difference = gdf1.overlay(gdf2, how: 'difference');

// Symmetric difference - areas that don't overlap
GeoDataFrame symDifference = gdf1.overlay(gdf2, how: 'symmetric_difference');
```

### 3. Coordinate Reference System Transformations

Transform geometries between different coordinate reference systems.

**Example:**
```dart
final gdf = GeoDataFrame.fromFeatureCollection(
  featureCollection,
  crs: 'EPSG:4326' // WGS84
);

// Transform to Web Mercator
GeoDataFrame webMercator = gdf.toCrs('EPSG:3857');

// Transform to UTM Zone 33N
GeoDataFrame utm = gdf.toCrs('EPSG:32633');

// Custom transformation with parameters
GeoDataFrame custom = gdf.toCrs(
  '+proj=aea +lat_1=29.5 +lat_2=45.5 +lat_0=37.5 +lon_0=-96'
);

// Check current CRS
String currentCrs = gdf.crs;
```

### 4. Spatial Indexing

Build spatial indexes for efficient spatial queries and operations.

**Example:**
```dart
final gdf = GeoDataFrame.fromFeatureCollection(largeFeatureCollection);

// Build spatial index for faster queries
gdf.buildSpatialIndex();

// Spatial query using bounding box
List<int> candidates = gdf.spatialQuery(boundingBox);

// Spatial query using geometry
List<int> intersecting = gdf.spatialQuery(queryGeometry);

// Nearest neighbor search
List<int> nearest = gdf.nearestNeighbors(
  queryPoint,
  k: 5 // Find 5 nearest features
);
```

## Advanced GeoSeries Operations

### 1. Buffer Operations

Create buffer zones around geometries.

**Example:**
```dart
final geoSeries = gdf.geometry;

// Simple buffer
GeoSeries buffered = geoSeries.buffer(distance: 100.0);

// Buffer with custom parameters
GeoSeries customBuffer = geoSeries.buffer(
  distance: 50.0,
  resolution: 16, // Number of segments per quarter circle
  capStyle: 'round', // 'round', 'flat', 'square'
  joinStyle: 'round' // 'round', 'mitre', 'bevel'
);

// Variable buffer distances
List<double> distances = [10.0, 20.0, 30.0];
GeoSeries variableBuffer = geoSeries.buffer(distances: distances);
```

### 2. Dissolve Operations

Dissolve geometries based on attributes or merge all geometries.

**Example:**
```dart
final gdf = GeoDataFrame.fromFeatureCollection(featureCollection);

// Dissolve all geometries into one
GeoSeries dissolved = gdf.geometry.dissolve();

// Dissolve by attribute
GeoDataFrame dissolvedByAttr = gdf.dissolve(by: 'category');

// Dissolve with aggregation
GeoDataFrame dissolvedWithAgg = gdf.dissolve(
  by: 'category',
  aggFunc: {'population': 'sum', 'area': 'mean'}
);
```

### 3. Simplification

Simplify geometries to reduce complexity while preserving shape.

**Example:**
```dart
final geoSeries = gdf.geometry;

// Douglas-Peucker simplification
GeoSeries simplified = geoSeries.simplify(tolerance: 0.01);

// Preserve topology during simplification
GeoSeries topologyPreserved = geoSeries.simplify(
  tolerance: 0.01,
  preserveTopology: true
);

// Visvalingam-Whyatt simplification
GeoSeries vwSimplified = geoSeries.simplify(
  tolerance: 0.01,
  algorithm: 'visvalingam'
);
```

### 4. Spatial Relationships

Test spatial relationships between geometries.

**Example:**
```dart
final geoSeries1 = gdf1.geometry;
final geoSeries2 = gdf2.geometry;

// Test various spatial relationships
Series intersects = geoSeries1.intersects(geoSeries2);
Series contains = geoSeries1.contains(geoSeries2);
Series within = geoSeries1.within(geoSeries2);
Series touches = geoSeries1.touches(geoSeries2);
Series crosses = geoSeries1.crosses(geoSeries2);
Series overlaps = geoSeries1.overlaps(geoSeries2);

// Distance calculations
Series distances = geoSeries1.distance(geoSeries2);

// Check if geometries are within a certain distance
Series nearby = geoSeries1.dwithin(geoSeries2, distance: 100.0);
```

## Spatial Analysis Examples

### 1. Point-in-Polygon Analysis

Determine which points fall within specific polygons.

**Example:**
```dart
// Load point and polygon data
final points = await GeoDataFrame.readFile('points.geojson');
final polygons = await GeoDataFrame.readFile('polygons.geojson');

// Perform spatial join to find points within polygons
GeoDataFrame pointsInPolygons = points.spatialJoin(
  polygons,
  how: 'left',
  predicate: 'within'
);

// Count points per polygon
DataFrame pointCounts = pointsInPolygons
  .groupBy(['polygon_id'])
  .agg({'point_id': 'count'});

// Filter polygons that contain points
GeoDataFrame populatedPolygons = polygons[
  polygons['id'].isin(pointsInPolygons['polygon_id'].dropna())
];
```

### 2. Distance Calculations

Calculate distances between geometries and perform distance-based analysis.

**Example:**
```dart
final gdf = await GeoDataFrame.readFile('locations.geojson');

// Calculate distance matrix between all points
DataFrame distanceMatrix = gdf.geometry.distanceMatrix();

// Find nearest neighbor for each point
Series nearestDistances = gdf.geometry.nearestNeighborDistance();
DataFrame nearestNeighbors = gdf.geometry.nearestNeighborInfo();

// Create distance-based buffers
GeoSeries buffers = gdf.geometry.buffer(distance: 1000.0);

// Find all features within a certain distance
final queryPoint = GeoJSONPoint([10.0, 20.0]);
GeoDataFrame nearby = gdf[
  gdf.geometry.distance(queryPoint) <= 500.0
];
```

### 3. Spatial Clustering

Perform spatial clustering analysis on point data.

**Example:**
```dart
final points = await GeoDataFrame.readFile('points.geojson');

// DBSCAN clustering
DataFrame clusters = points.spatialCluster(
  algorithm: 'dbscan',
  eps: 100.0, // Maximum distance between points in same cluster
  minSamples: 5 // Minimum points required to form cluster
);

// K-means clustering with spatial constraints
DataFrame spatialKMeans = points.spatialCluster(
  algorithm: 'kmeans',
  nClusters: 5,
  spatialConstraint: true
);

// Hierarchical clustering
DataFrame hierarchical = points.spatialCluster(
  algorithm: 'hierarchical',
  nClusters: 3,
  linkage: 'ward'
);

// Add cluster labels back to original data
points['cluster'] = clusters['cluster_id'];

// Analyze cluster statistics
DataFrame clusterStats = points.groupBy(['cluster']).agg({
  'value': ['mean', 'std', 'count'],
  'geometry': 'centroid'
});
```

This documentation covers the enhanced spatial operations available in DartFrame, providing comprehensive geospatial analysis capabilities similar to those found in geopandas.