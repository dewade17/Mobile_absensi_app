import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class FaceVerificationProvider with ChangeNotifier {
  bool _isVerifying = false;
  String? _statusMessage;
  String? _matchedUserId;

  bool get isVerifying => _isVerifying;
  String? get statusMessage => _statusMessage;
  String? get matchedUserId => _matchedUserId;
  bool get isVerified => _matchedUserId != null;

  void _setVerifying(bool value) {
    _isVerifying = value;
    notifyListeners();
  }

  void _setStatus(String? message, {String? userId}) {
    _statusMessage = message;
    _matchedUserId = userId;
    notifyListeners();
  }

  Future<bool> verifyFace(File imageFile) async {
    _setVerifying(true);
    _setStatus(null);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        _setStatus('Token tidak ditemukan, silakan login ulang.');
        return false;
      }

      // 1. Ambil semua face dari database
      final apiService = ApiService();
      final response = await apiService.fetchData('userface');
      final List<dynamic> dbFaces = response['faces'];

      // 2. Kirim ke Flask endpoint /verify
      print('📸 File size: ${await imageFile.length()} bytes');
      print('📦 db_faces size: ${jsonEncode(dbFaces).length} bytes');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
            'https://nuclear-complaints-ser-spanish.trycloudflare.com/verify'),
      );
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));
      request.fields['db_faces'] = jsonEncode(dbFaces);

      var res = await request.send();
      final resStr = await res.stream.bytesToString();

      // ✅ Cek error dari server (misalnya: 413 Payload Too Large)
      if (res.statusCode != 200) {
        _setStatus('❌ Flask server error: ${res.statusCode}');
        return false;
      }

      // ✅ Amankan dari FormatException
      Map<String, dynamic> data;
      try {
        data = jsonDecode(resStr);
      } catch (e) {
        _setStatus('❌ Gagal membaca response JSON dari server.');
        return false;
      }

      // ✅ Tangani hasil verifikasi
      if (data['status'] == 'error') {
        _setStatus('❌ Verifikasi gagal: ${data['message']}');
        return false;
      }

      if (data['match'] == true) {
        _setStatus('✅ Wajah cocok dengan user ID: ${data["user_id"]}',
            userId: data["user_id"]);
        return true;
      } else {
        _setStatus('❌ Tidak ada wajah yang cocok.');
        return false;
      }
    } catch (e) {
      _setStatus('❌ Error: $e');
      return false;
    } finally {
      _setVerifying(false);
    }
  }
}
