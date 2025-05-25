// ignore_for_file: avoid_print
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:absensi_app/dto/face_reenrollment.dart';
import 'package:absensi_app/services/api_service.dart';

class FaceReenrollmentProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<FaceReenrollment> _requests = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  int _currentPage = 1;
  int _totalPages = 1;
  int _perPage = 10;

  List<FaceReenrollment> get requests => _requests;
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

  /// ✅ POST: Submit request for face reenrollment
  Future<bool> submitRequest(FaceReenrollment request) async {
    _setLoading(true);
    _setError(null);
    _setSuccess(null);

    try {
      final response = await _apiService.postData(
        'facereenrollment',
        request.toJson(),
      );

      final newRequest = FaceReenrollment.fromJson(response);
      _requests.insert(0, newRequest);
      _setSuccess("Permintaan pendaftaran ulang wajah berhasil dikirim.");
      return true;
    } catch (e) {
      _setError("Gagal mengirim permintaan: $e");
      print('❌ Submit Request Error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// ✅ GET: Fetch face reenrollment requests by user_id with pagination
  Future<void> fetchRequests({int page = 1, int limit = 10}) async {
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
        'facereenrollment/$userId?page=$page&limit=$limit',
      );

      final List<dynamic> data = response['data'] ?? [];
      _requests = data.map((item) => FaceReenrollment.fromJson(item)).toList();

      // Ambil meta info untuk pagination
      final meta = response['meta'];
      _currentPage = meta['currentPage'] ?? 1;
      _totalPages = meta['totalPages'] ?? 1;
      _perPage = meta['perPage'] ?? limit;
    } catch (e) {
      _setError("Gagal mengambil data permintaan: $e");
      print('❌ Fetch Requests Error: $e');
    } finally {
      _setLoading(false);
    }
  }
}
