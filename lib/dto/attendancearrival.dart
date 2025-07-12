class Attendancearrival {
  String? arrivalId;
  String userId;
  DateTime tanggal;
  DateTime jamMasuk;
  double latitude;
  double longitude;
  bool faceVerified;
  DateTime createdAt;
  DateTime updatedAt;

  Attendancearrival({
    required this.arrivalId,
    required this.userId,
    required this.tanggal,
    required this.jamMasuk,
    required this.latitude,
    required this.longitude,
    required this.faceVerified,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Attendancearrival.fromJson(Map<String, dynamic> json) =>
      Attendancearrival(
        arrivalId: json["arrival_id"],
        userId: json["user_id"],
        tanggal: DateTime.parse(json["tanggal"]),
        jamMasuk: DateTime.parse(json["jam_masuk"]),
        latitude: json["latitude"].toDouble(),
        longitude: json["longitude"].toDouble(),
        faceVerified: json["face_verified"],
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
      );

  Map<String, dynamic> toJson() => {
        "arrival_id": arrivalId,
        "user_id": userId,
        "tanggal": tanggal.toIso8601String(),
        "jam_masuk": jamMasuk.toIso8601String(),
        "latitude": latitude,
        "longitude": longitude,
        "face_verified": faceVerified,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
      };
}
