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

  // Fetch all attendance arrivals
  Future<void> fetchAttendanceArrivals() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _apiService.fetchData('attendance/arrival');
      final List<dynamic> data = response['attendance'] ?? [];

      _attendanceArrivals =
          data.map((item) => Attendancearrival.fromJson(item)).toList();
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Fetch Attendance Arrivals Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Attendancearrival?> fetchAttendanceArrivalByStoredUserId() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final storedUserId = prefs.getString('user_id');

      if (storedUserId == null) {
        throw Exception('No stored user_id found in SharedPreferences.');
      }

      final response =
          await _apiService.fetchData('attendance/arrival/$storedUserId');

      if (response['attendance'] == null) {
        _isLoading = false;
        notifyListeners();
        return null; // JANGAN throw exception kalau data kosong
      }

      final attendanceArrival =
          Attendancearrival.fromJson(response['attendance']);

      _isLoading = false;
      notifyListeners();
      return attendanceArrival;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      print('❌ Fetch Attendance Arrival by Stored User ID Error: $e');
      return null;
    }
  }

  // Create a new attendance arrival
  Future<bool> createAttendanceArrival(
      Attendancearrival attendanceArrival) async {
    try {
      final response = await _apiService.postData(
        'attendance/arrival',
        attendanceArrival.toJson(),
      );

      print('✅ Response from createAttendanceArrival: $response');

      if (response['created'] == null) {
        throw Exception('Created data not found in response.');
      }

      final newAttendanceArrival =
          Attendancearrival.fromJson(response['created']);
      _attendanceArrivals.add(newAttendanceArrival);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Create Attendance Arrival Error: $e');
      return false;
    }
  }

  Future<void> fetchPaginatedAttendanceArrivals({bool refresh = false}) async {
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
        throw Exception('No stored user_id found in SharedPreferences.');
      }

      final response = await _apiService.fetchData(
        'attendance/arrival/$storedUserId?page=$_currentPage&limit=$_limit',
      );

      final List<dynamic> newData = response['data'] ?? [];

      if (newData.isEmpty) {
        _hasMore = false;
      } else {
        final newAttendances =
            newData.map((item) => Attendancearrival.fromJson(item)).toList();
        _attendanceArrivals.addAll(newAttendances);
        _currentPage++;
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Fetch Paginated Attendance Arrivals Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
