class Profile {
  String userId;
  String nama;
  String email;
  dynamic noHp;
  dynamic nip;
  dynamic fotoProfil;
  DateTime createdAt;
  DateTime updatedAt;

  Profile({
    required this.userId,
    required this.nama,
    required this.email,
    required this.noHp,
    required this.nip,
    required this.fotoProfil,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
        userId: json["user_id"] ?? "",
        nama: json["nama"] ?? "",
        email: json["email"] ?? "",
        noHp: json["no_hp"] ?? "",
        nip: json["nip"] ?? "",
        fotoProfil: json["foto_profil"] ?? "",
        createdAt: DateTime.parse(json["createdAt"]),
        updatedAt: DateTime.parse(json["updatedAt"]),
      );

  Map<String, dynamic> toJson() => {
        "user_id": userId,
        "nama": nama,
        "email": email,
        "no_hp": noHp,
        "nip": nip,
        "foto_profil": fotoProfil,
        "createdAt": createdAt.toIso8601String(),
        "updatedAt": updatedAt.toIso8601String(),
      };

  bool get isComplete =>
      userId.isNotEmpty &&
      nama.isNotEmpty &&
      email.isNotEmpty &&
      noHp.isNotEmpty &&
      nip.isNotEmpty &&
      fotoProfil.isNotEmpty;
}
