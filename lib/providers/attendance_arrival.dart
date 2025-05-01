import 'package:absensi_app/dto/attendancearrival.dart';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AttendanceArrivalProvider with ChangeNotifier {
  final ApiService apiService = ApiService();
  List<Attendancearrival> _items = [];
  bool _isLoading = false;

  List<Attendancearrival> get items => _items;
  bool get isLoading => _isLoading;

  // Get all attendance arrivals
  Future<void> fetchAttendanceArrivals() async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await apiService.fetchData('/attendance/arrival');
      _items = (response as List)
          .map((json) => Attendancearrival.fromJson(json))
          .toList();
    } catch (e) {
      print('❌ Failed to fetch attendance arrivals: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new attendance arrival
  Future<bool> createAttendanceArrival(Attendancearrival data) async {
    try {
      final response = await apiService.postData('attendance/arrival', {
        "user_id": data.userId,
        "tanggal": data.tanggal.toIso8601String(),
        "jam_masuk": data.jamMasuk.toIso8601String(),
        "latitude": data.latitude,
        "longitude": data.longitude,
        "face_verified": data.faceVerified,
      });

      final created = Attendancearrival.fromJson(response['created']);
      _items.add(created);
      notifyListeners();
      return true;
    } catch (e) {
      print('❌ Failed to create attendance: $e');
      return false;
    }
  }
}
