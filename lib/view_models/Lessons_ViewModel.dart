import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class LessonsViewModel {
  final ValueNotifier<List<Map<String, dynamic>>> lessons = ValueNotifier<List<Map<String, dynamic>>>([]);
  final ValueNotifier<bool> isLoading = ValueNotifier<bool>(false);

  Future<void> fetchLessons(String subjectName) async {
    isLoading.value = true;
    lessons.value = [];

    final url = Uri.parse("https://b736-2c0f-4280-0-6132-b43c-1e54-c386-db5d.ngrok-free.app/KiddoAI/Lesson/bySubject/$subjectName");

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(utf8.decode(response.bodyBytes));
        // Assuming each lesson is a JSON object
        lessons.value = data.map<Map<String, dynamic>>((lesson) => lesson as Map<String, dynamic>).toList();
      } else {
        throw Exception("Failed to load lessons");
      }
    } catch (e) {
      debugPrint("Error fetching lessons: $e");
    } finally {
      isLoading.value = false;
    }
  }
}