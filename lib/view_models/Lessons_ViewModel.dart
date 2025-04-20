import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../utils/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LessonsViewModel {
  final ValueNotifier<List<Map<String, dynamic>>> lessons = ValueNotifier<List<Map<String, dynamic>>>([]);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  Future<void> fetchLessons(String subjectName) async {
    isLoading.value = true;
    lessons.value = [];

    final url = Uri.parse(CurrentIP + "/KiddoAI/Lesson/bySubject/$subjectName");

    try {
      // Retrieve the access token from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      final response = await http.get(
        url,

        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        // Assuming each lesson is a JSON object
        lessons.value = data.map<Map<String, dynamic>>((lesson) => lesson as Map<String, dynamic>).toList();
      } else {
        throw Exception("Failed to load lessons: Status code ${response.statusCode} - ${response.body}");
      }
    } catch (e) {
      debugPrint("Error fetching lessons: $e");
    } finally {
      isLoading.value = false;
    }
  }
}
