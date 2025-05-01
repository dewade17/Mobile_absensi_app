import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ResetPasswordProvider with ChangeNotifier {
  final ApiService apiService = ApiService();

  bool _isLoading = false;
  String? _message;

  bool get isLoading => _isLoading;
  String? get message => _message;

  Future<void> resetPassword(String token, String newPassword) async {
    _isLoading = true;
    _message = null;
    notifyListeners();

    try {
      final response = await apiService.postData(
        'auth/resetPassword', // sesuaikan dengan endpoint kamu (tanpa '/api')
        {
          'token': token,
          'newPassword': newPassword,
        },
      );

      _message = response['message'] ?? 'Password berhasil direset.';
    } catch (e) {
      _message = 'Gagal reset password: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }

  void resetMessage() {
    _message = null;
    notifyListeners();
  }
}
