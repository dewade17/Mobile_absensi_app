import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart'; // sesuaikan path kalau perlu

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

      final flaskApiUrl =
          'https://nuclear-complaints-ser-spanish.trycloudflare.com/encode';

      print('📤 Mengirim gambar ke Flask...');
      var request = http.MultipartRequest('POST', Uri.parse(flaskApiUrl));
      request.files
          .add(await http.MultipartFile.fromPath('image', imageFile.path));
      var response = await request.send();

      print('📥 Menerima respons dari Flask...');
      final resStr = await response.stream.bytesToString();
      print('📦 Respons string dari Flask: $resStr');

      final data = jsonDecode(resStr);
      print('✅ JSON berhasil di-decode');

      if (data['status'] != 'success') {
        print('❌ Flask gagal encode: ${data['message']}');
        _setStatusMessage('Python Error: ${data['message']}');
        return false;
      }

      final decodedEncoding = data['face_encoding'];
      print('🧠 Encoding length: ${decodedEncoding.length}');
      print('🧠 First 5 values: ${decodedEncoding.take(5)}');

      final encoding = jsonEncode(decodedEncoding);

      final apiService = ApiService();
      final result = await apiService.postData('userface', {
        'user_id': userId,
        'face_encoding': encoding,
      });

      print('✅ Berhasil kirim encoding ke API');
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
}
