class WorkagendaItem {
  DateTime? tanggal;
  DateTime? jamMulai;
  DateTime? jamSelesai;
  String? deskripsiPekerjaan;
  String? buktiFotoUrl;

  WorkagendaItem({
    this.tanggal,
    this.jamMulai,
    this.jamSelesai,
    this.deskripsiPekerjaan,
    this.buktiFotoUrl,
  });

  factory WorkagendaItem.fromJson(Map<String, dynamic> json) {
    try {
      final tanggalStr = json['tanggal']?.toString();
      final jamMulaiStr = json['jam_mulai']?.toString();
      final jamSelesaiStr = json['jam_selesai']?.toString();

      final tanggal = tanggalStr != null && tanggalStr.trim().isNotEmpty
          ? DateTime.tryParse(tanggalStr)
          : null;
      final jamMulai = jamMulaiStr != null && jamMulaiStr.trim().isNotEmpty
          ? DateTime.tryParse(jamMulaiStr)
          : null;
      final jamSelesai =
          jamSelesaiStr != null && jamSelesaiStr.trim().isNotEmpty
              ? DateTime.tryParse(jamSelesaiStr)
              : null;

      return WorkagendaItem(
        tanggal: tanggal,
        jamMulai: jamMulai,
        jamSelesai: jamSelesai,
        deskripsiPekerjaan: json['deskripsi_pekerjaan'],
        buktiFotoUrl: json['bukti_foto_url'],
      );
    } catch (e) {
      return WorkagendaItem(); // fallback
    }
  }

  Map<String, dynamic> toJson() => {
        "tanggal": tanggal?.toIso8601String().split('T').first,
        "jam_mulai": jamMulai?.toIso8601String(),
        "jam_selesai": jamSelesai?.toIso8601String(),
        "deskripsi_pekerjaan": deskripsiPekerjaan,
        "bukti_foto_url": buktiFotoUrl,
      };
}
