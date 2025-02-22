import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthenticationService {
  final String baseUrl = 'https://aaa3-197-6-153-45.ngrok-free.app/KiddoAI'; // CHANGE THIS WITH YOUR IP ADDRESS (ipconfig)

  // Signup
  Future<Map<String, dynamic>> signup(String nom, String prenom, String email, String password, String favoriteCharacter, String dateOfBirth) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'nom': nom,
        'prenom': prenom,
        'email': email,
        'password': password,
        'favoriteCharacter': favoriteCharacter,
        'dateNaissance': dateOfBirth,  // Include date of birth in the body
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Signup failed');
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
    var responseBody = jsonDecode(response.body);
    print("Decoded Response: $responseBody"); // Log the decoded response

    // Ensure you have valid accessToken, refreshToken, and threadId
    if (responseBody['accessToken'] != null && responseBody['refreshToken'] != null && responseBody['threadId'] != null) {
      return responseBody;
    } else {
      throw Exception('Access token, refresh token, or thread ID not found in response');
    }
  } else {
    // Throw an error with the status code and body for more details
    throw Exception('Login failed: ${response.statusCode} - ${response.body}');
  }
}

}