class FieldModel {
  final int id;
  final String name;
  final String ownerName;
  final String? khasraNumber;
  final double? areaSqm;
  final double? areaBigha;
  final double? areaAcre;
  final double? perimeterM;
  final Map<String, dynamic>? boundaryGeoJson;
  final DateTime? createdAt;

  FieldModel({
    required this.id,
    required this.name,
    required this.ownerName,
    this.khasraNumber,
    this.areaSqm,
    this.areaBigha,
    this.areaAcre,
    this.perimeterM,
    this.boundaryGeoJson,
    this.createdAt,
  });

  factory FieldModel.fromJson(Map<String, dynamic> json) {
    return FieldModel(
      id: json['id'] as int,
      name: json['name'] as String,
      ownerName: json['owner_name'] as String,
      khasraNumber: json['khasra_number'] as String?,
      areaSqm: (json['area_sqm'] as num?)?.toDouble(),
      areaBigha: (json['area_bigha'] as num?)?.toDouble(),
      areaAcre: (json['area_acre'] as num?)?.toDouble(),
      perimeterM: (json['perimeter_m'] as num?)?.toDouble(),
      boundaryGeoJson: json['boundary_geojson'] as Map<String, dynamic>?,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
    );
  }

  /// Returns area in Bigha formatted as "2.50 Bigha (0.50 Acre)"
  String get formattedArea {
    if (areaBigha == null) return 'Area unknown';
    final bigha = areaBigha!.toStringAsFixed(2);
    final acre = areaAcre?.toStringAsFixed(2) ?? '?';
    final sqm = areaSqm?.toStringAsFixed(0) ?? '?';
    return '$bigha Bigha ($acre Acre | $sqm m²)';
  }

  String get formattedPerimeter {
    if (perimeterM == null) return '?';
    return '${perimeterM!.toStringAsFixed(1)} m';
  }

  /// Extracts list of [lat, lon] from GeoJSON boundary
  List<List<double>> get latLonCoordinates {
    if (boundaryGeoJson == null) return [];
    final coords = boundaryGeoJson!['coordinates'] as List?;
    if (coords == null || coords.isEmpty) return [];
    final ring = coords[0] as List;
    return ring
        .map((p) => [(p[1] as num).toDouble(), (p[0] as num).toDouble()])
        .toList();
  }

  /// Centroid (approximate) from boundary
  List<double>? get centroid {
    final pts = latLonCoordinates;
    if (pts.isEmpty) return null;
    final lat = pts.map((p) => p[0]).reduce((a, b) => a + b) / pts.length;
    final lon = pts.map((p) => p[1]).reduce((a, b) => a + b) / pts.length;
    return [lat, lon];
  }
}
