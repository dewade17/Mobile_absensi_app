class Location {
  String locationId;
  String companyId;
  String namaLokasi;
  double latitude;
  double longitude;
  int radius;
  DateTime createdAt;
  DateTime updatedAt;
  Company company;

  Location({
    required this.locationId,
    required this.companyId,
    required this.namaLokasi,
    required this.latitude,
    required this.longitude,
    required this.radius,
    required this.createdAt,
    required this.updatedAt,
    required this.company,
  });

  factory Location.fromJson(Map<String, dynamic> json) => Location(
        locationId: json["location_id"],
        companyId: json["company_id"],
        namaLokasi: json["nama_lokasi"],
        latitude: json["latitude"].toDouble(),
        longitude: json["longitude"].toDouble(),
        radius: json["radius"],
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
        company: Company.fromJson(json["company"]),
      );

  Map<String, dynamic> toJson() => {
        "location_id": locationId,
        "company_id": companyId,
        "nama_lokasi": namaLokasi,
        "latitude": latitude,
        "longitude": longitude,
        "radius": radius,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
        "company": company.toJson(),
      };
}

class Company {
  String companyId;
  String nama;
  String alamat;
  String telepon;
  String email;
  String logoUrl;
  DateTime createdAt;
  DateTime updatedAt;

  Company({
    required this.companyId,
    required this.nama,
    required this.alamat,
    required this.telepon,
    required this.email,
    required this.logoUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) => Company(
        companyId: json["company_id"],
        nama: json["nama"],
        alamat: json["alamat"],
        telepon: json["telepon"],
        email: json["email"],
        logoUrl: json["logo_url"],
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
      );

  Map<String, dynamic> toJson() => {
        "company_id": companyId,
        "nama": nama,
        "alamat": alamat,
        "telepon": telepon,
        "email": email,
        "logo_url": logoUrl,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
      };
}
