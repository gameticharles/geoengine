part of geoengine;

/// The Info object defines the standard information
/// stored with spatial reference objects.
abstract class Info {
  /// Name of the object.
  String name;

  /// Authority name for this object, e.g., "EPSG",
  /// if this is a standard object with an authority-specific
  /// identity code. Returns "CUSTOM" if this is a custom object.
  String authority;

  /// Authority-specific identification code of the object.
  int authorityCode;

  /// Alias of the object.
  String? alias;

  /// Abbreviation of the object.
  String? abbreviation;

  /// Provider-supplied remarks for the object.
  String? remarks;

  /// Initializes a new instance of Info.
  Info({
    required this.name,
    required this.authority,
    required this.authorityCode,
    this.alias,
    this.abbreviation,
    this.remarks,
  });

  /// Returns the Well-known text for this object
  /// as defined in the simple features specification.
  String get wkt;

  /// Gets an XML representation of this object.
  String get xml;

  @override
  String toString() {
    return wkt;
  }

  /// Returns an XML string of the info object.
  String get infoXml {
    final sb = StringBuffer();
    sb.write('<CS_Info');
    if (authorityCode > 0) sb.write(' AuthorityCode="$authorityCode"');
    if (abbreviation!.isNotEmpty) sb.write(' Abbreviation="$abbreviation"');
    if (authority.isNotEmpty) sb.write(' Authority="$authority"');
    if (name.isNotEmpty) sb.write(' Name="$name"');
    sb.write('/>');
    return sb.toString();
  }

  /// Checks whether the values of this instance are equal to the values of another instance.
  /// Only parameters used for coordinate systems are used for comparison.
  /// Name, abbreviation, authority, alias, and remarks are ignored in the comparison.
  bool equal(Object obj);
}
