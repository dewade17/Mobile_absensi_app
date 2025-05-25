// ignore_for_file: avoid_print
import 'package:absensi_app/dto/attendace_departure.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AttendanceDepartureProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<AttendaceDeparture> _departures = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 4;

  List<AttendaceDeparture> get departures => _departures;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> fetchDepartureHistory({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _departures.clear();
      _currentPage = 1;
      _hasMore = true;
      notifyListeners();
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        throw Exception('No stored user_id found.');
      }

      final response = await _apiService.fetchData(
        'attendance/departure/$userId?page=$_currentPage&limit=$_limit',
      );

      final List<dynamic> newData = response['data'] ?? [];

      if (newData.isEmpty) {
        _hasMore = false;
      } else {
        final newDepartures =
            newData.map((item) => AttendaceDeparture.fromJson(item)).toList();
        _departures.addAll(newDepartures);
        _currentPage++;
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Fetch Departure History Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AttendaceDeparture?> fetchTodayDeparture() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) throw Exception('User ID tidak ditemukan');

      final response =
          await _apiService.fetchData('attendance/departure/$userId');

      if (response['data'] == null) return null;

      final latestDeparture = AttendaceDeparture.fromJson(response['data'][0]);
      return latestDeparture;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Fetch Today Departure Error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createDeparture(AttendaceDeparture departure) async {
    try {
      final response = await _apiService.postData(
        'attendance/departure',
        departure.toJson(),
      );

      print('✅ Create Departure Response: $response');

      if (response == null || response['departure_id'] == null) {
        throw Exception('Gagal menyimpan data departure.');
      }

      final newDeparture = AttendaceDeparture.fromJson(response);
      _departures.add(newDeparture);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Create Departure Error: $e');
      return false;
    }
  }
}
