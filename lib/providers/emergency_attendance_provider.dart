// ignore_for_file: avoid_print, unused_field
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absensi_app/dto/emergency_attendance.dart';
import 'package:absensi_app/services/api_service.dart';

class EmergencyAttendanceProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<EmergencyAttendance> _emergencies = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  int _currentPage = 1;
  int _totalPages = 1;
  int _perPage = 10;

  List<EmergencyAttendance> get emergencies => _emergencies;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _setSuccess(String? message) {
    _successMessage = message;
    notifyListeners();
  }

  void setPage(int page) {
    _currentPage = page;
    notifyListeners();
  }

  /// ✅ POST: Submit emergency attendance
  Future<bool> submitEmergency(EmergencyAttendance emergency) async {
    _setLoading(true);
    _setError(null);
    _setSuccess(null);

    try {
      final response = await _apiService.postData(
        'emergencyattendance',
        emergency.toJson(),
      );

      final newData = EmergencyAttendance.fromJson(response);
      _emergencies.insert(0, newData); // tampilkan data terbaru di atas
      _setSuccess("Absensi darurat berhasil disimpan.");
      return true;
    } catch (e) {
      _setError("Gagal menyimpan absensi darurat: $e");
      print('❌ Submit Emergency Error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ✅ GET: Fetch emergency attendances by user_id with pagination
  Future<void> fetchEmergencies({int page = 1, int limit = 10}) async {
    _setLoading(true);
    _setError(null);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        _setError('User ID tidak ditemukan di SharedPreferences');
        print('⚠️ Tidak ada user_id di SharedPreferences');
        _setLoading(false);
        return;
      }

      final response = await _apiService.fetchData(
        'emergencyattendance/$userId?page=$page&limit=$limit',
      );

      final List<dynamic> data = response['data'] ?? [];

      _emergencies =
          data.map((item) => EmergencyAttendance.fromJson(item)).toList();

      // ambil info pagination dari meta
      final meta = response['meta'];
      _currentPage = meta['currentPage'] ?? 1;
      _totalPages = meta['totalPages'] ?? 1;
      _perPage = meta['perPage'] ?? 10;
    } catch (e) {
      _setError("Gagal mengambil data absensi darurat: $e");
      print('❌ Fetch Emergency Error: $e');
    } finally {
      _setLoading(false);
    }
  }
}
