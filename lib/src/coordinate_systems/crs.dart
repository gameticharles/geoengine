part of geoengine;

class CRS {
  final String crsName;
  final int isFavorite;
  final String wktID;
  final String wktString;

  CRS({
    required this.crsName,
    required this.isFavorite,
    required this.wktID,
    required this.wktString,
  });

  static CRS fromJson(Map<String, dynamic> json) {
    return CRS(
      crsName: json['CRSName'],
      isFavorite: json['IsFavorite'],
      wktID: json['WKTID'],
      wktString: json['WKTString'],
    );
  }
}
