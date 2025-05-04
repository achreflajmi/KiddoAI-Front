// lib/services/authentication_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:front_kiddoai/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthenticationService {
  final String baseUrl = CurrentIP+'/KiddoAI';

  /* ---------- LOGIN ---------- */
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode != 200) {
      throw Exception('Login failed: ${response.statusCode} - ${response.body}');
    }

    final Map<String, dynamic> responseData = jsonDecode(response.body);
    final String userId = responseData['id'];
    

    // Debug
    debugPrint('⬅️  Login response: $responseData');

    /* Persist vectorStoreId (if any) */
    final String? vectorId = responseData['vectorStoreId'] as String?;
    if (vectorId != null) {
      debugPrint('✅ Received vectorStoreId: $vectorId');
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('vectorStoreId', vectorId);
      await prefs.setString('userId', userId);

    }

    await _saveUserSession(responseData);
    return responseData;
  }

  /* ---------- SIGN‑UP ---------- */
  Future<Map<String, dynamic>> signup(
    String nom,
    String prenom,
    String email,
    String password,
    String favoriteCharacter,
    String dateOfBirth,
    String parentPhoneNumber,
    String classe,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'password': password,
        'favoriteCharacter': favoriteCharacter,
        'dateNaissance': dateOfBirth,
        'parentPhoneNumber': parentPhoneNumber,
        'classe': classe,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Signup failed: ${response.body}');
    }

    final Map<String, dynamic> responseData = jsonDecode(response.body);
    await _saveUserSession(responseData);
    return responseData;
  }

  /* ---------- Shared‑prefs helpers ---------- */
  Future<void> _saveUserSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', true);
    if (data['threadId'] != null)  prefs.setString('threadId',  data['threadId']);
    if (data['accessToken'] != null)  prefs.setString('accessToken', data['accessToken']);
    if (data['refreshToken'] != null) prefs.setString('refreshToken', data['refreshToken']);
  }
Future<Map<String, dynamic>> getCurrentUser() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('accessToken');

  final response = await http.get(
    Uri.parse('$baseUrl/users/me'),
    headers: {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    },
  );

  if (response.statusCode == 200) {
    return json.decode(response.body);
  } else {
    throw Exception('Failed to fetch user data: ${response.statusCode}');
  }
}

  Future<bool> isLoggedIn() async =>
      (await SharedPreferences.getInstance()).getBool('isLoggedIn') ?? false;

  Future<String?> getThreadId() async =>
      (await SharedPreferences.getInstance()).getString('threadId');

  Future<void> logout() async =>
      (await SharedPreferences.getInstance()).clear();
}
