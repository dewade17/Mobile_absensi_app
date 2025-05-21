// ignore_for_file: avoid_print
import 'package:absensi_app/dto/agenda.dart';
import 'package:absensi_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WorkAgendaProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<Workagenda> _agendas = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<Workagenda> get agendas => _agendas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ✅ Fetch all agendas by user_id
  Future<void> fetchWorkAgendas(
      {int page = 1, int limit = 10, bool append = false}) async {
    _isLoading = !append;
    _errorMessage = null;
    if (!append) notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');
      if (userId == null) {
        _errorMessage = 'User ID tidak ditemukan di SharedPreferences';
        _isLoading = false;
        notifyListeners();
        return;
      }

      final response = await _apiService
          .fetchData('workagenda-with-items?page=$page&limit=$limit');
      final List<dynamic> data = response['data'] ?? [];
      final newAgendas = data.map((item) => Workagenda.fromJson(item)).toList();

      if (append) {
        _agendas.addAll(newAgendas);
      } else {
        _agendas = newAgendas;
      }
    } catch (e) {
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Create agenda with multiple items
  Future<dynamic> createWorkAgendaWithItems(Workagenda agenda) async {
    try {
      final payload = agenda.toJsonWithItems();
      final response =
          await _apiService.postData('workagenda-with-items', payload);

      if (response['agenda'] != null) {
        final newAgenda = Workagenda.fromJson(response['agenda']);
        _agendas.add(newAgenda);
        notifyListeners();
        return true;
      } else {
        return response; // kirim balik error JSON
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Create WorkAgenda Error: $e');
      return false;
    }
  }

  Future<dynamic> updateWorkAgendaWithItems(
      String agendaId, Workagenda agenda) async {
    try {
      final payload = {
        'items': agenda.items?.map((item) => item.toJson()).toList(),
      };
      final response = await _apiService.updateData(
          'workagenda-with-items/$agendaId', payload);

      if (response['agenda'] != null) {
        final updated = Workagenda.fromJson(response['agenda']);
        final index = _agendas.indexWhere((a) => a.agendaId == agendaId);
        if (index != -1) {
          _agendas[index] = updated;
          notifyListeners();
        }
        return true;
      } else {
        print('⚠️ Response tidak valid: $response');
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Update WorkAgenda Error: $e');
      return false;
    }
  }

  // ✅ Delete agenda
  Future<bool> deleteWorkAgenda(String agendaId) async {
    try {
      final response =
          await _apiService.deleteData('workagenda-with-items/$agendaId');
      if (response['message'] == 'Agenda dan semua item berhasil dihapus') {
        _agendas.removeWhere((a) => a.agendaId == agendaId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ Delete WorkAgenda Error: $e');
      return false;
    }
  }
}
