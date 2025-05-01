import 'package:flutter/material.dart';
import 'package:absensi_app/dto/location.dart'; // pastikan ini path ke model Location kamu
import '../services/api_service.dart'; // pastikan ini path ke ApiService kamu

class LocationProvider with ChangeNotifier {
  final ApiService apiService = ApiService();
  List<Location> _locations = [];
  bool _isLoading = false;
  String? _error;

  List<Location> get locations => _locations;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> fetchLocations() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await apiService.fetchData("location"); // endpoint-nya
      final List rawList = data['locations'];

      _locations = rawList.map((e) => Location.fromJson(e)).toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }
}
