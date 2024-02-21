part of '../../../geoengine.dart';

/// An enum that UTM Ellipsoids
class UTMEllipsoid {
  /// WGS 84
  static final wgs72 =
      UTMEllipsoid('WGS 72', 'WGS_1972', 'WGS 72', Ellipsoid.wgs72);

  /// WGS 72BE
  static final wgs72BE =
      UTMEllipsoid('WGS 72BE', 'WGS_1972', 'WGS 72', Ellipsoid.wgs72);

  /// WGS 84
  static final wgs84 =
      UTMEllipsoid('WGS 84', 'WGS_1984', 'WGS 84', Ellipsoid.wgs84);

  const UTMEllipsoid(
    this.name,
    this.year,
    this.spheroidName,
    this.ellipsoid,
  );

  final String name;
  final String year;
  final String spheroidName;
  final Ellipsoid ellipsoid;

  @override
  String toString() {
    return name;
  }
}
