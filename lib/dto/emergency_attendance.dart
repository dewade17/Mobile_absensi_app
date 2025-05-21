class EmergencyAttendance {
  String? emergencyId;
  String? userId;
  DateTime tanggal;
  DateTime jamMasuk;
  String jenis;
  String? alasan;
  DateTime? createdAt;
  DateTime? updatedAt;

  EmergencyAttendance({
    this.emergencyId,
    this.userId,
    required this.tanggal,
    required this.jamMasuk,
    required this.jenis,
    this.alasan,
    this.createdAt,
    this.updatedAt,
  });

  factory EmergencyAttendance.fromJson(Map<String, dynamic> json) =>
      EmergencyAttendance(
        emergencyId: json["emergency_id"],
        userId: json["user_id"],
        tanggal: DateTime.parse(json["tanggal"]),
        jamMasuk: DateTime.parse(json["jam_masuk"]),
        jenis: json["jenis"],
        alasan: json["alasan"],
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
      );

  Map<String, dynamic> toJson() => {
        "emergency_id": emergencyId,
        "user_id": userId,
        "tanggal": tanggal.toIso8601String(),
        "jam_masuk": jamMasuk.toIso8601String(),
        "jenis": jenis,
        "alasan": alasan,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
      };
}
