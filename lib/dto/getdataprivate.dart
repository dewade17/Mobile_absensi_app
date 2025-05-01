class Getdataprivate {
  String userId;
  String nama;
  String email;
  String role;
  DateTime createdAt;
  DateTime updatedAt;

  Getdataprivate({
    required this.userId,
    required this.nama,
    required this.email,
    required this.role,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Getdataprivate.fromJson(Map<String, dynamic> json) => Getdataprivate(
        userId: json["user_id"],
        nama: json["nama"],
        email: json["email"],
        role: json["role"],
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
      );

  Map<String, dynamic> toJson() => {
        "user_id": userId,
        "nama": nama,
        "email": email,
        "role": role,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
      };
}
