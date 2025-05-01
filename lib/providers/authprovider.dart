// ignore_for_file: avoid_print
import 'package:absensi_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  final ApiService apiService = ApiService();
  bool isLoading = false;
  String? errorMessage;

  /// 🔹 Proses login setelah dapat token dari LoginPage
  Future<void> login(String token, BuildContext context) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    try {
      final userResponse = await apiService.getUserProfile(token);
      print("User Profile Response: $userResponse");

      if (userResponse == null || userResponse['user_id'] == null) {
        throw Exception("User profile tidak ditemukan");
      }

      // Simpan semua data ke SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', token);
      await prefs.setString('user_id', userResponse['user_id']);
      await prefs.setString('name', userResponse['nama'] ?? '');
      await prefs.setString('email', userResponse['email'] ?? '');
      await prefs.setString('role', userResponse['role'] ?? '');

      // Redirect sesuai role
      final role = userResponse['role'];
      if (context.mounted) {
        if (role == 'KARYAWAN') {
          Navigator.pushReplacementNamed(context, '/home-screen');
        } else if (role == 'ADMIN') {
          Navigator.pushReplacementNamed(context, '/dashboard-admin');
        } else {
          Navigator.pushReplacementNamed(context, '/dashboard');
        }
      }
    } catch (e) {
      print("Login Error: ${e.toString()}");
      errorMessage = "Login gagal: ${e.toString()}";

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage!)),
        );
      }
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// 🔹 Logout Function
  Future<void> logout(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.clear();

      notifyListeners();

      if (context.mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      print("Logout Error: ${e.toString()}");
    }
  }

  /// 🔹 Get User Role
  Future<String?> getUserRole() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      return prefs.getString('role');
    } catch (e) {
      print("Get User Role Error: ${e.toString()}");
      return null;
    }
  }

  /// 🔹 Cek apakah role = KARYAWAN
  Future<bool> isUser() async {
    return (await getUserRole()) == "KARYAWAN";
  }
}
