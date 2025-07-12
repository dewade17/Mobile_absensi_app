class Location {
  String locationId;
  String namaLokasi;
  double latitude;
  double longitude;
  int radius;
  DateTime createdAt;
  DateTime updatedAt;

  Location({
    required this.locationId,
    required this.namaLokasi,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        locationId: json["location_id"],
        namaLokasi: json["nama_lokasi"],
        latitude: json["latitude"].toDouble(),
        longitude: json["longitude"].toDouble(),
        radius: json["radius"],
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
      );

  Map<String, dynamic> toJson() => {
        "location_id": locationId,
        "nama_lokasi": namaLokasi,
        "latitude": latitude,
        "longitude": longitude,
        "radius": radius,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
      };
}
