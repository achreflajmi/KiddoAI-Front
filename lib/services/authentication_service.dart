import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class AuthenticationService {
  final String baseUrl = 'https://7aaf-41-226-166-49.ngrok-free.app/KiddoAI';

  // Signup - now includes the "classe" parameter.
  Future<Map<String, dynamic>> signup(
      String nom,
      String prenom,
      String email,
      String password,
      String favoriteCharacter,
      String dateOfBirth,
      String parentPhoneNumber,
      String classe) async {
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
        'classe': classe, // New field sent to backend.
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      await _saveUserSession(responseData);
      return responseData;
    } else {
      throw Exception('Signup failed: ${response.body}');
    }
  }

  // Login
  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);

      if (responseData['accessToken'] == null ||
          responseData['refreshToken'] == null ||
          responseData['threadId'] == null) {
        throw Exception('Invalid response data: missing required fields');
      }

      await _saveUserSession(responseData);
      return responseData;
    } else {
      throw Exception('Login failed: ${response.statusCode} - ${response.body}');
    }
  }

  // Save user session data
  Future<void> _saveUserSession(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    prefs.setBool('isLoggedIn', true);

    if (data['threadId'] != null) {
      prefs.setString('threadId', data['threadId']);
    }

    if (data['accessToken'] != null) {
      prefs.setString('accessToken', data['accessToken']);
    }

    if (data['refreshToken'] != null) {
      prefs.setString('refreshToken', data['refreshToken']);
    }
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('isLoggedIn') ?? false;
  }

  // Get stored threadId
  Future<String?> getThreadId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('threadId');
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
