// ignore_for_file: avoid_print
import 'package:absensi_app/dto/attendancearrival.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';

class AttendanceArrivalProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Attendancearrival> _attendanceArrivals = [];
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasMore = true;
  int _currentPage = 1;
  final int _limit = 4;

  List<Attendancearrival> get attendanceArrivals => _attendanceArrivals;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// ✅ Fetch paginated arrival records
  Future<void> fetchAttendanceArrivals({bool refresh = false}) async {
    if (_isLoading) return;

    if (refresh) {
      _attendanceArrivals.clear();
      _currentPage = 1;
      _hasMore = true;
      notifyListeners();
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('user_id');

      if (storedUserId == null) {
        throw Exception('User ID tidak ditemukan di SharedPreferences');
      }

      final response = await _apiService.fetchData(
        'attendance/arrival/$storedUserId?page=$_currentPage&limit=$_limit',
      );

      final List<dynamic> newData = response['data'] ?? [];

      if (newData.isEmpty) {
        _hasMore = false;
      } else {
        final newList =
            newData.map((item) => Attendancearrival.fromJson(item)).toList();

        _attendanceArrivals.addAll(newList);
        _currentPage++;
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Fetch Attendance Arrivals Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ Fetch latest attendance (today)
  Future<Attendancearrival?> fetchTodayArrival() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('user_id');

      if (storedUserId == null) throw Exception('User ID tidak ditemukan');

      final response =
          await _apiService.fetchData('attendance/arrival/$storedUserId');

      if (response['data'] == null || response['data'].isEmpty) return null;

      final latestArrival = Attendancearrival.fromJson(response['data'][0]);
      return latestArrival;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Fetch Today Arrival Error: $e');
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ Create new attendance arrival record
  Future<bool> createAttendanceArrival(
      Attendancearrival attendanceArrival) async {
    try {
      final response = await _apiService.postData(
        'attendance/arrival',
        attendanceArrival.toJson(),
      );

      if (response['created'] == null) {
        throw Exception('Response tidak mengandung field "created"');
      }

      final newData = Attendancearrival.fromJson(response['created']);
      _attendanceArrivals.insert(0, newData); // terbaru di atas
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Create Attendance Arrival Error: $e');
      return false;
    }
  }
}
