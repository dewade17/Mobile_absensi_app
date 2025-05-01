// ignore_for_file: avoid_print

import 'dart:convert';

import 'package:absensi_app/dto/face.dart';
import 'package:absensi_app/services/api_service.dart';

import 'package:flutter/material.dart';

class FaceProvider with ChangeNotifier {
  final ApiService apiService = ApiService();
  List<Face> _faces = [];

  List<Face> get faces => _faces;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  // GET: Ambil semua wajah
  Future<void> fetchFaces() async {
    try {
      _isLoading = true;
      notifyListeners();

      final response = await apiService.fetchData('/api/userface');
      final List<dynamic> data = response['faces'];

      _faces = data.map((json) => Face.fromJson(json)).toList();
    } catch (e) {
      print('❌ Error fetchFaces: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // POST: Tambah wajah baru
  Future<bool> addFace(Face face) async {
    try {
      print('📤 Final Face toCreateJson: ${face.toCreateJson()}');
      print('📤 Final JSON to send: ${jsonEncode(face.toCreateJson())}');
      final response =
          await apiService.postData('userface', face.toCreateJson());

    print('📥 Response Type: ${response.runtimeType}');
      print('📥 Response Content: $response');

      final newFace = Face.fromJson(response['face']);
      _faces.add(newFace);

      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Error addFace: $e');
      return false;
    }
  }
}
