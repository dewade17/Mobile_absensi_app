import 'package:flutter/material.dart';
import '../services/api_service.dart';

class GetTokenProvider with ChangeNotifier {
  final ApiService apiService = ApiService();

  bool _isLoading = false;
  String? _message;

  bool get isLoading => _isLoading;
  String? get message => _message;

  Future<void> sendResetCode(String email) async {
    _isLoading = true;
    _message = null;
    notifyListeners();

    try {
      final response = await apiService.postData(
        'auth/getToken', // tanpa /api karena sudah disetel di baseUrl
        {'email': email},
      );

      // anggap response punya kunci "message"
      _message = response['message'] ?? 'Kode berhasil dikirim ke email.';
    } catch (e) {
      _message = 'Gagal mengirim kode: ${e.toString()}';
    }

    _isLoading = false;
    notifyListeners();
  }
}
