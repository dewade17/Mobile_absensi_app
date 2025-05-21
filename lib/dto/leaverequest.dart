class Leaverequest {
  String? leaveId;
  String? userId;
  String jenisIzin;
  DateTime tanggalMulai;
  DateTime tanggalSelesai;
  String alasan;
  String buktiFile;
  String? status;
  DateTime? createdAt;
  DateTime? updatedAt;

  Leaverequest({
    this.leaveId,
    this.userId,
    required this.jenisIzin,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    required this.alasan,
    required this.buktiFile,
    this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory Leaverequest.fromJson(Map<String, dynamic> json) => Leaverequest(
        leaveId: json["leave_id"],
        userId: json["user_id"],
        jenisIzin: json["jenis_izin"],
        tanggalMulai: DateTime.parse(json["tanggal_mulai"]),
        tanggalSelesai: DateTime.parse(json["tanggal_selesai"]),
        alasan: json["alasan"],
        buktiFile: json["bukti_file"],
        status: json["status"],
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
      );

  Map<String, dynamic> toJson() => {
        "leave_id": leaveId,
        "user_id": userId,
        "jenis_izin": jenisIzin,
        "tanggal_mulai": tanggalMulai.toIso8601String(),
        "tanggal_selesai": tanggalSelesai.toIso8601String(),
        "alasan": alasan,
        "bukti_file": buktiFile,
        "status": status,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
      };
}
