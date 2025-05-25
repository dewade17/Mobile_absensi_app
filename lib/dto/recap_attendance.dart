import 'package:intl/intl.dart';

class RecapAttendance {
  // Field untuk kedatangan
  final String? arrivalId;
  // Field untuk kepulangan
  final String? departureId;
  // Field umum
  final String? userId;
  final DateTime? tanggal;
  final DateTime? jamMasuk; // untuk arrivals
  final DateTime? jamKeluar; // untuk departures
  final double? latitude;
  final double? longitude;
  final bool? faceVerified;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  RecapAttendance({
    this.arrivalId,
    this.departureId,
    this.userId,
    this.tanggal,
    this.jamMasuk,
    this.jamKeluar,
    this.latitude,
    this.longitude,
    this.faceVerified,
    this.createdAt,
    this.updatedAt,
  });

  factory RecapAttendance.fromJson(Map<String, dynamic> json) {
    return RecapAttendance(
      arrivalId: json['arrival_id']?.toString(),
      departureId: json['departure_id']?.toString(),
      userId: json['user_id']?.toString(),
      tanggal: safeParseDate(json['tanggal']),
      jamMasuk: safeParseDate(json['jam_masuk']),
      jamKeluar: safeParseDate(json['jam_keluar']),
      latitude: safeParseDouble(json['latitude']),
      longitude: safeParseDouble(json['longitude']),
      faceVerified: parseBool(json['face_verified']),
      createdAt: safeParseDate(json['createdAt']),
      updatedAt: safeParseDate(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
        "arrival_id": arrivalId,
        "departure_id": departureId,
        "user_id": userId,
        "tanggal": tanggal?.toIso8601String(),
        "jam_masuk": jamMasuk?.toIso8601String(),
        "jam_keluar": jamKeluar?.toIso8601String(),
        "latitude": latitude,
        "longitude": longitude,
        "face_verified": faceVerified,
        "createdAt": createdAt?.toIso8601String(),
        "updatedAt": updatedAt?.toIso8601String(),
      };
}

// Helper untuk parsing date, null-safe dan anti error
DateTime? safeParseDate(dynamic value) {
  if (value == null) return null;
  if (value is String && value.trim().isEmpty) return null;
  try {
    return DateTime.parse(value.toString());
  } catch (_) {
    return null;
  }
}

// Helper untuk parsing double, null-safe
double? safeParseDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String && value.trim().isEmpty) return null;
  try {
    return double.parse(value.toString());
  } catch (_) {
    return null;
  }
}

// Helper parsing boolean lebih robust (true/"true"/1)
bool? parseBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final lower = value.toLowerCase();
    if (lower == "true" || lower == "1") return true;
    if (lower == "false" || lower == "0") return false;
  }
  return null;
}

// ---------------------
// Meta pagination class
// ---------------------
class Meta {
  final int totalItems;
  final int totalArrivals;
  final int totalDepartures;
  final int totalPages;
  final int currentPage;
  final int perPage;

  Meta({
    required this.totalItems,
    required this.totalArrivals,
    required this.totalDepartures,
    required this.totalPages,
    required this.currentPage,
    required this.perPage,
  });

  factory Meta.fromJson(Map<String, dynamic> json) => Meta(
        totalItems: json["totalItems"] ?? 0,
        totalArrivals: json["totalArrivals"] ?? 0,
        totalDepartures: json["totalDepartures"] ?? 0,
        totalPages: json["totalPages"] ?? 0,
        currentPage: json["currentPage"] ?? 1,
        perPage: json["perPage"] ?? 10,
      );

  Map<String, dynamic> toJson() => {
        "totalItems": totalItems,
        "totalArrivals": totalArrivals,
        "totalDepartures": totalDepartures,
        "totalPages": totalPages,
        "currentPage": currentPage,
        "perPage": perPage,
      };
}
