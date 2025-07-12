// ignore_for_file: avoid_print

import 'dart:io';
import 'package:absensi_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

      final apiService = ApiService();

      // ✅ Upload hanya image, tanpa kirim db_faces
      final verifyResponse = await apiService.uploadFile(
        'verify', // Pastikan path endpoint sesuai
        imageFile,
      );

      print('📥 Response dari API Verify: $verifyResponse');

      // ✅ Cek hasil verifikasi
      if (verifyResponse['status'] == 'error') {
        _setStatus('❌ Verifikasi gagal: ${verifyResponse['message']}');
        return false;
      }

      if (verifyResponse['match'] == true) {
        _setStatus('✅ Wajah cocok dengan user ID: ${verifyResponse["user_id"]}',
            userId: verifyResponse["user_id"]);
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
