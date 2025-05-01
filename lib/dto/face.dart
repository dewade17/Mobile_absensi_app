class Face {
  String faceId;
  String userId;
  String faceEncoding;
  DateTime createdAt;
  DateTime updatedAt;

  Face({
    required this.faceId,
    required this.userId,
    required this.faceEncoding,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Face.fromJson(Map<String, dynamic> json) => Face(
        faceId: json["face_id"],
        userId: json["user_id"],
        faceEncoding: json["face_encoding"],
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
      );

  Map<String, dynamic> toJson() => {
        "face_id": faceId,
        "user_id": userId,
        "face_encoding": faceEncoding,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
      };

  /// Digunakan khusus untuk POST (tanpa face_id)
  Map<String, dynamic> toCreateJson() => {
        "user_id": userId,
        "face_encoding": faceEncoding,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
      };
}
