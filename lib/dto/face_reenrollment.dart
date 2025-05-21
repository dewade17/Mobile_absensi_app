class Merchant {
  String? requestId;
  String? userId;
  String alasan;
  String status;
  String? catatan;
  DateTime? createdAt;
  DateTime? updatedAt;

  Merchant({
    this.requestId,
    this.userId,
    required this.alasan,
    required this.status,
    this.catatan,
    this.createdAt,
    this.updatedAt,
  });

  factory Merchant.fromJson(Map<String, dynamic> json) => Merchant(
        requestId: json["request_id"],
        userId: json["user_id"],
        alasan: json["alasan"],
        status: json["status"],
        catatan: json["catatan"],
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
      );

  Map<String, dynamic> toJson() => {
        "request_id": requestId,
        "user_id": userId,
        "alasan": alasan,
        "status": status,
        "catatan": catatan,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
      };
}
