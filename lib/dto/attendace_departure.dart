class AttendaceDeparture {
  String? departureId;
  String userId;
  DateTime tanggal;
  DateTime jamKeluar;
  double latitude;
  double longitude;
  bool faceVerified;
  DateTime createdAt;
  DateTime updatedAt;

  AttendaceDeparture({
    this.departureId,
    required this.userId,
    required this.tanggal,
    required this.jamKeluar,
    required this.latitude,
    required this.longitude,
    required this.faceVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  factory AttendaceDeparture.fromJson(Map<String, dynamic> json) =>
      AttendaceDeparture(
        departureId: json["departure_id"],
        userId: json["user_id"],
        tanggal: DateTime.parse(json["tanggal"]),
        jamKeluar: DateTime.parse(json["jam_keluar"]),
        latitude: json["latitude"].toDouble(),
        longitude: json["longitude"].toDouble(),
        faceVerified: json["face_verified"],
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
      );

  Map<String, dynamic> toJson() => {
        "departure_id": departureId,
        "user_id": userId,
        "tanggal": tanggal.toIso8601String(),
        "jam_keluar": jamKeluar.toIso8601String(),
        "latitude": latitude,
        "longitude": longitude,
        "face_verified": faceVerified,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
      };
}
