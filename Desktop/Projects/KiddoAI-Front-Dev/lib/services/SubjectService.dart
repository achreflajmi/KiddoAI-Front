import 'dart:convert';
import 'package:http/http.dart' as http;

class SubjectService {
  final String baseUrl;

  SubjectService(this.baseUrl);

  Future<List<String>> fetchSubjects() async {
  try {
    final response = await http.get(Uri.parse('$baseUrl/Subject/all'));

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
