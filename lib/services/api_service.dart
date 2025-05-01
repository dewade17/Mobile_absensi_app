// import 'package:flutter/material.dart';
// ignore_for_file: avoid_print, unused_local_variable

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:mime/mime.dart';
import 'dart:convert';
import 'package:http_parser/http_parser.dart';
import 'dart:io';
import 'package:path/path.dart' as path;

class ApiService {
  final String baseUrl =
      'https://sociology-butts-field-resolved.trycloudflare.com/api'; //api-back-nextjs
  final String baseurl =
      'https://engineers-tongue-herald-marine.trycloudflare.com/api'; //api-face-recognition-flask

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

  Future<Map<String, String>> verifyFace(File imageFile) async {
    final uri = Uri.parse('$baseUrl/verifyface');

    final mimeType = lookupMimeType(imageFile.path);
    final ext = path.extension(imageFile.path).toLowerCase();

    // Gunakan 'image/jpeg' kalau tidak bisa terdeteksi
    final contentType = mimeType != null
        ? MediaType.parse(mimeType)
        : MediaType('image', 'jpeg');

    final request = http.MultipartRequest('POST', uri)
      ..files.add(await http.MultipartFile.fromPath(
        'image',
        imageFile.path,
        contentType: contentType,
      ));

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        return {
          'status': 'success',
          'message': responseBody.trim(),
        };
      } else {
        return {
          'status': 'failed',
          'message': 'Failed with status: ${response.statusCode}'
        };
      }
    } catch (e) {
      return {
        'status': 'error',
        'message': e.toString(),
      };
    }
  }
}
