// ignore_for_file: avoid_print, unused_local_variable
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl =
      'https://additional-ride-international-grenada.trycloudflare.com/api';

  Future<Map<String, dynamic>> fetchData(String endpoint) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      throw Exception('Token not found. Please login again.');
    }

    final response = await http.get(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final decodedResponse = utf8.decode(response.bodyBytes);
      final jsonResponse = jsonDecode(decodedResponse);
      return jsonResponse;
    } else if (response.statusCode == 401) {
      await prefs.remove('token');
      throw Exception('Unauthorized. Please login again.');
    } else {
      // Cetak detail error ke console untuk debugging
      print("API Error [${response.statusCode}]: ${response.body}");
      throw Exception('Failed to load data from $endpoint');
    }
  }

  Future<Map<String, dynamic>> postData(
      String endpoint, Map<String, dynamic> data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.post(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      prefs.remove('token');
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to post data');
    }
  }

  Future<Map<String, dynamic>> updateData(
      String endpoint, Map<String, dynamic> data) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/$endpoint');

    debugPrint("📤 [API PUT] URL: $url");
    debugPrint("📤 [API PUT] Headers: ${{
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    }}");
    debugPrint("📤 [API PUT] Body: ${jsonEncode(data)}");

    final response = await http.put(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );

    debugPrint("✅ [API Response] Status: ${response.statusCode}");
    debugPrint("✅ [API Response] Body: ${response.body}");

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      prefs.remove('token');
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to update data: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> deleteData(String endpoint) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final response = await http.delete(
      Uri.parse('$baseUrl/$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else if (response.statusCode == 401) {
      prefs.remove('token');
      throw Exception('Unauthorized');
    } else {
      throw Exception('Failed to delete data');
    }
  }

  Future<Map<String, dynamic>> login(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode(data),
    );

    print('Request to: ${Uri.parse('$baseUrl/auth/login')}');
    print('Status Code: ${response.statusCode}');
    print('Response Body: ${response.body}');

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to login: ${response.body}');
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/auth/getdataprivate'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      return body['user']; // ✅ Ambil hanya bagian user
    } else {
      print('Get user profile failed: ${response.statusCode}');
      return null;
    }
  }

  Future<Map<String, dynamic>> uploadFile(String endpoint, File file,
      {Map<String, String>? fields}) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final url = Uri.parse('$baseUrl/$endpoint');

    var request = http.MultipartRequest('POST', url);
    request.headers['Authorization'] = 'Bearer $token';
    request.files.add(await http.MultipartFile.fromPath('image', file.path));

    if (fields != null) {
      request.fields.addAll(fields);
    }

    final response = await request.send();
    final responseStr = await response.stream.bytesToString();
    final responseData = jsonDecode(responseStr);

    if (response.statusCode == 200 || response.statusCode == 201) {
      return responseData;
    } else {
      throw Exception(
          'Failed to upload file: ${response.statusCode} - $responseStr');
    }
  }
}
