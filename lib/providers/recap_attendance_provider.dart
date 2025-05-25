import 'package:absensi_app/dto/recap_attendance.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class RecapAttendanceProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  final Map<String, List<RecapAttendance>> _arrivalsMap = {};
  final Map<String, List<RecapAttendance>> _departuresMap = {};
  final Map<String, Meta?> _metaMap = {};
  final Map<String, bool> _loadingMap = {};
  final Map<String, String?> _errorMap = {};

  String _currentKey = 'default';

  // Getter default (digunakan di HomeScreen)
  List<RecapAttendance> get arrivals => _arrivalsMap[_currentKey] ?? [];
  List<RecapAttendance> get departures => _departuresMap[_currentKey] ?? [];
  Meta? get meta => _metaMap[_currentKey];
  bool get isLoading => _loadingMap[_currentKey] ?? false;
  String? get errorMessage => _errorMap[_currentKey];

  // Getter berdasarkan tanggal key (untuk screen dengan filter bulan/tahun)
  List<RecapAttendance> getArrivals(String tanggal) =>
      _arrivalsMap[tanggal] ?? [];
  List<RecapAttendance> getDepartures(String tanggal) =>
      _departuresMap[tanggal] ?? [];
  Meta? getMeta(String tanggal) => _metaMap[tanggal];
  bool isLoadingFor(String tanggal) => _loadingMap[tanggal] ?? false;
  String? getErrorFor(String tanggal) => _errorMap[tanggal];

  Future<void> fetchRecapAttendance({
    String? tanggal,
    int page = 1,
    int limit = 10,
    bool refresh = false,
  }) async {
    final key = tanggal ?? 'default';
    final isFiltered = tanggal != null && tanggal != 'default';

    _currentKey = key;
    _loadingMap[key] = true;
    _errorMap[key] = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('user_id');
      if (storedUserId == null) throw Exception('No stored user_id found.');

      String endpoint =
          'attendance/rekap/$storedUserId?page=$page&limit=$limit';
      if (isFiltered) {
        endpoint += '&tanggal=$tanggal';
      }

      final response = await _apiService.fetchData(endpoint);

      final List<RecapAttendance> fetchedArrivals =
          (response['data']['arrivals'] as List)
              .map((e) => RecapAttendance.fromJson(e))
              .toList();
      final List<RecapAttendance> fetchedDepartures =
          (response['data']['departures'] as List)
              .map((e) => RecapAttendance.fromJson(e))
              .toList();

      if (refresh || page == 1) {
        _arrivalsMap[key] = fetchedArrivals;
        _departuresMap[key] = fetchedDepartures;
      } else {
        _arrivalsMap.putIfAbsent(key, () => []).addAll(fetchedArrivals);
        _departuresMap.putIfAbsent(key, () => []).addAll(fetchedDepartures);
      }

      _metaMap[key] =
          response['meta'] != null ? Meta.fromJson(response['meta']) : null;
    } catch (e) {
      _errorMap[key] = e.toString();
      print('❌ Fetch Recap Attendance Error ($key): $e');
    } finally {
      _loadingMap[key] = false;
      notifyListeners();
    }
  }

  void clear(String? tanggal) {
    final key = tanggal ?? 'default';
    _arrivalsMap.remove(key);
    _departuresMap.remove(key);
    _metaMap.remove(key);
    _errorMap.remove(key);
    _loadingMap.remove(key);
    notifyListeners();
  }
}
