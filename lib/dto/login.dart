class Login {
  String userId;
  String nama;
  String email;
  DateTime createdAt;
  DateTime updatedAt;

  Login({
    required this.userId,
    required this.nama,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Login.fromJson(Map<String, dynamic> json) => Login(
        userId: json["user_id"],
        nama: json["nama"],
        email: json["email"],
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
      );

  Map<String, dynamic> toJson() => {
        "user_id": userId,
        "nama": nama,
        "email": email,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
      };
}
