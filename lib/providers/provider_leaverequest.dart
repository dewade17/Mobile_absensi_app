// ignore_for_file: avoid_print
import 'package:absensi_app/dto/leaverequest.dart';
import 'package:absensi_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LeaveRequestProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Leaverequest> _leaveRequests = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Leaverequest> get leaveRequests => _leaveRequests;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ✅ Fetch leave requests berdasarkan user_id dari SharedPreferences
  Future<void> fetchLeaveRequests() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId == null) {
        _errorMessage = 'User ID tidak ditemukan di SharedPreferences';
        print('⚠️ Tidak ada user_id di SharedPreferences');
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await _apiService.fetchData('leaverequest/$userId');
      final List<dynamic> data = response['data'] ?? [];

      _leaveRequests = data.map((item) => Leaverequest.fromJson(item)).toList();
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Fetch Leave Requests Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Create leave request
  Future<bool> createLeaveRequest(Leaverequest leaveRequest) async {
    try {
      final response =
          await _apiService.postData('leaverequest', leaveRequest.toJson());

      final newLeaveRequest = Leaverequest.fromJson(response['leave']);
      _leaveRequests.add(newLeaveRequest);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Create Leave Request Error: $e');
      return false;
    }
  }

  // ✅ Update leave request berdasarkan ID
  Future<bool> updateLeaveRequest(
      String id, Leaverequest updatedLeaveRequest) async {
    try {
      final response = await _apiService.updateData(
          'leaverequest/$id', updatedLeaveRequest.toJson());

      final index = _leaveRequests.indexWhere((leave) => leave.leaveId == id);
      if (index != -1) {
        _leaveRequests[index] = Leaverequest.fromJson(response['leave']);
        notifyListeners();
      }
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Update Leave Request Error: $e');
      return false;
    }
  }

  // ✅ Delete leave request
  Future<bool> deleteLeaveRequest(String id) async {
    try {
      await _apiService.deleteData('leaverequest/$id');

      _leaveRequests.removeWhere((leave) => leave.leaveId == id);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Delete Leave Request Error: $e');
      return false;
    }
  }
}
