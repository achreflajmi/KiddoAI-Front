import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SubjectService {
  final String baseUrl;

  SubjectService(this.baseUrl);

  Future<List<String>> fetchSubjects() async {
    try {
      // Retrieve the access token from SharedPreferences.
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      final response = await http.get(
        Uri.parse('$baseUrl/Subject/all'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        print('Response Body: ${response.body}');  // Log the raw response
        final List<dynamic> data = json.decode(response.body);
        return data.map((subject) => subject['name'] as String).toList();
      } else {
        print('Failed to load subjects. Status code: ${response.statusCode}');
        throw Exception('Failed to load subjects');
      }
    } catch (e) {
      print("Error: $e");
      throw Exception('Failed to load subjects: $e');
    }
  }
}
