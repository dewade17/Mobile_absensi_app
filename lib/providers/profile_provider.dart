// ignore_for_file: unnecessary_null_comparison

import 'dart:async';
import 'dart:io';

import 'package:absensi_app/dto/profile.dart';
import 'package:absensi_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileProvider extends ChangeNotifier {
  final ApiService apiService = ApiService();
  Profile? _user;
  String? _userId;

  Profile? get user => _user;
  String? get userId => _userId;

  bool get isProfileComplete => _user?.isComplete ?? false;

  /// ⏬ Bisa dipanggil saat login selesai
  Future<void> loadUserIdFromPreferences() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('user_id');
    debugPrint("✅ Loaded user_id: $_userId");
    notifyListeners();
  }

  /// ⏬ Panggil ini setelah `loadUserIdFromPreferences()`
  Future<void> fetchUserProfile() async {
    if (_userId == null) {
      debugPrint("❌ Cannot fetch profile: user_id is null");
      return;
    }

    try {
      final response = await apiService.fetchData('user/$_userId');
      _user = Profile.fromJson(response['user']);
      debugPrint("✅ Profile fetched: ${_user?.nama}");
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Failed to fetch profile: $e');
    }
  }

  /// ⏬ Untuk menggabungkan keduanya secara praktis
  Future<void> initUserProfile() async {
    await loadUserIdFromPreferences();
    await fetchUserProfile();
  }

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<void> updateUserProfile({
    required String nama,
    required String email,
    required String noHp,
    required String nip,
    required String fotoProfil,
  }) async {
    if (_userId == null) {
      _errorMessage = "User ID tidak ditemukan.";
      debugPrint("❌ $_errorMessage");
      notifyListeners();
      return;
    }

    try {
      final data = {
        "nama": nama,
        "email": email,
        "no_hp": noHp,
        "nip": nip,
        "foto_profil": fotoProfil,
      };

      final response =
          await apiService.updateData('user/editprofile/$_userId', data);

      // Contoh validasi response tergantung dari struktur API
      if (response == null) {
        _errorMessage = "Tidak ada respon dari server.";
        debugPrint("❌ $_errorMessage");
        notifyListeners();
        return;
      }

      if (response['success'] != true) {
        _errorMessage = response['message'] ?? "Gagal memperbarui profil.";
        debugPrint("❌ $_errorMessage");
        notifyListeners();
        return;
      }

      // Update state user setelah berhasil
      _user = Profile.fromJson(response['user']);
      _errorMessage = null;
      debugPrint("✅ Profile updated: ${_user?.nama}");
      notifyListeners();
    } on TimeoutException catch (_) {
      _errorMessage = "Permintaan waktu habis. Periksa koneksi internet.";
      debugPrint("❌ $_errorMessage");
      notifyListeners();
    } on SocketException catch (_) {
      _errorMessage = "Tidak dapat terhubung ke server.";
      debugPrint("❌ $_errorMessage");
      notifyListeners();
    } catch (e) {
      _errorMessage = "Terjadi kesalahan: $e";
      debugPrint("❌ $_errorMessage");
      notifyListeners();
    }
  }
}
