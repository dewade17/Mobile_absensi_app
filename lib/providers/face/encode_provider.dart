// ignore_for_file: unused_local_variable, avoid_print

import 'dart:io';
import 'dart:convert';
import 'package:absensi_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FaceEncodingProvider with ChangeNotifier {
  bool _isLoading = false;
  String? _statusMessage;

  bool get isLoading => _isLoading;
  String? get statusMessage => _statusMessage;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setStatusMessage(String? message) {
    _statusMessage = message;
    notifyListeners();
  }

  Future<bool> encodeAndSaveFace(File imageFile, String userId) async {
    _setLoading(true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      if (token == null) {
        _setStatusMessage('Token tidak ditemukan, silakan login ulang.');
        return false;
      }

      final apiService = ApiService();

      print('📤 Mengirim gambar ke Next.js Encode API...');
      final encodeResponse =
          await apiService.uploadFile('encode', imageFile); // PAKAI uploadFile!

      print('📥 Response dari API Encode: $encodeResponse');

      if (encodeResponse['status'] != 'success') {
        print('❌ Gagal encode: ${encodeResponse['message']}');
        _setStatusMessage('Encode Error: ${encodeResponse['message']}');
        return false;
      }

      final decodedEncoding = encodeResponse['face_encoding'];
      print('🧠 Encoding length: ${decodedEncoding.length}');
      print('🧠 First 5 values: ${decodedEncoding.take(5)}');

      final encoding = jsonEncode(decodedEncoding);

      print('📤 Menyimpan encoding ke database via API...');
      final saveResult = await apiService.postData('userface', {
        'user_id': userId,
        'face_encoding': encoding,
      });

      print('✅ Berhasil simpan encoding ke backend');
      _setStatusMessage('✅ Wajah berhasil disimpan.');
      return true;
    } catch (e) {
      print('❌ Exception saat encoding: $e');
      _setStatusMessage('Error: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> isFaceRegistered() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');
      final userId = prefs.getString('user_id');

      if (token == null || userId == null) return false;

      final apiService = ApiService();
      final result = await apiService.fetchDataface('userface/$userId');

      if (result != null && result['face_encoding'] != null) {
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Face not registered or error occurred: $e');
      return false; // <== fallback aman
    }
  }
}
