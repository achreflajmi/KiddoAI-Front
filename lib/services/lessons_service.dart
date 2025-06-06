import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/constants.dart';
import 'package:flutter/foundation.dart';   // ← add this line


class LessonsService {
  // Updated base URL for teach endpoint to use the new API
  final String _baseUrl;
  final String _baseTeachLessonUrl;
  final String _baseActivityUrl;
  final String _baseVoiceGenerationUrl;
  final String _baseAudioUrl;
  final String _activityPageUrl;
  final String _baseLessonsUrl;

  // Constructor to initialize the URLs
  LessonsService()
      : _baseUrl = CurrentIP,
        // Updated teach endpoint (Flask route is /teach)
        _baseTeachLessonUrl = AzizIP+'/teach',
        _baseActivityUrl = CurrentIP + '/KiddoAI/Activity/saveProblem',
        _baseVoiceGenerationUrl = 'https://268b-196-184-222-196.ngrok-free.app/generate-voice',
        _baseAudioUrl = 'http://172.20.10.9:8001/outputlive.wav',
        _activityPageUrl = CurrentIP + '/',
        _baseLessonsUrl = CurrentIP + '/KiddoAI/Lesson/bySubject'; //
        final String _configureVectorStoreUrl = CurrentIP +'/KiddoAI/adminDashboard/configureVectorStore'; // ⇦ NEW

  // Helper method to retrieve access token from SharedPreferences
  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('accessToken');
  }

Future<List<Map<String, dynamic>>> fetchLessons(String subjectName) async {
  try {
    final encodedSubject = Uri.encodeComponent(subjectName);
    final url = Uri.parse('$_baseLessonsUrl/$encodedSubject');
    print('Fetching lessons from: $url');

    final token = await _getAccessToken();
    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );

    print('Response status: ${response.statusCode}');
    print('Response body: ${response.body}');

    if (response.statusCode == 200) {
      final List<dynamic> lessonsJson = jsonDecode(response.body);
      return lessonsJson.map((lesson) => {
            'name': lesson['name'] as String? ?? 'Unnamed Lesson',
            'description': lesson['description'] as String? ?? 'No description available',
          }).toList();
    } else {
      // Throwing exception with more details from the response.
      throw Exception('Failed to fetch lessons: Status code ${response.statusCode} - ${response.body}');
    }
  } catch (e, stackTrace) {
    print("Error fetching lessons: $e");
    print("StackTrace: $stackTrace");
    throw Exception('Failed to load lessons: $e');
  }
}


  Future<String> createThread() async {
    // Replace with your actual create_thread endpoint URL.
    final String baseCreateThreadUrl =
        AzizIP+'/create_thread';
    final response = await http.post(
      Uri.parse(baseCreateThreadUrl),
      headers: {'Content-Type': 'application/json'},
      // This endpoint is assumed public; if needed, add token here as well.
    );
    if (response.statusCode == 201) {
      final decodedResponse = jsonDecode(response.body);
      return decodedResponse['thread_id'] as String;
    } else {
      throw Exception('Failed to create thread: ${response.statusCode} - ${response.body}');
    }
  }

  /// Updated teachLesson method to work with the new chatbot endpoint.
  /// This method now only accepts a [userInput] string.
  Future<String> teachLesson(String userInput) async {
    final prefs = await SharedPreferences.getInstance();
    final threadId = prefs.getString('threadId') ?? '';
    
    if (threadId.isEmpty) {
      throw Exception('No threadId found. Please login again.');
    }
    
    try {
      final token = await _getAccessToken();
      final response = await http.post(
        Uri.parse(_baseTeachLessonUrl),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'thread_id': threadId, // Note the underscore in the key
          'text': userInput,     // Send the user’s chat message as text
        }),
      );
      
      if (response.statusCode == 200) {
        final decodedResponse = jsonDecode(response.body);
        if (decodedResponse is Map && decodedResponse.containsKey('response')) {
          return decodedResponse['response'] as String? ?? '';
        } else {
          return response.body;
        }
      } else {
        throw Exception('Failed to load lesson explanation: Status code ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Failed to load lesson: $e');
    }
  }




  Future<String> generateVoice(String text) async {
    try {
      final token = await _getAccessToken();
      final response = await http.post(
        Uri.parse(_baseVoiceGenerationUrl),
        headers: {
          "Content-Type": "application/json",
          if (token != null) "Authorization": "Bearer $token",
        },
        body: jsonEncode({
          "text": text,
          "speaker_wav": "sounds/SpongBob.wav",
        }),
      );
      
      if (response.statusCode == 200) {
        final cacheBuster = DateTime.now().millisecondsSinceEpoch;
        final uniqueUrl = '$_baseAudioUrl?cache=$cacheBuster';
        
        final headResponse = await http.head(Uri.parse(uniqueUrl));
        if (headResponse.statusCode != 200) {
          throw Exception('Audio file not found at $uniqueUrl');
        }
        
        return uniqueUrl;
      } else {
        throw Exception('Failed to generate voice: Status code ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error in voice generation: $e');
    }
  }

  Future<String> prepareActivity(String description) async {
    try {
      final token = await _getAccessToken();
      bool isActivityReady = false;
      
      while (!isActivityReady) {
        final response = await http.post(
          Uri.parse(_baseActivityUrl),
          headers: {
            "Content-Type": "application/json",
            if (token != null) "Authorization": "Bearer $token",
          },
          body: jsonEncode({"prompt": description}),
        );
        
        if (response.statusCode == 200) {
          isActivityReady = true;
        } else {
          await Future.delayed(Duration(seconds: 2));
        }
      }
      
      return _activityPageUrl;
    } catch (e) {
      throw Exception('Error loading activity: $e');
    }
  }

  String getActivityPageUrl() {
    return _activityPageUrl;
  }
}
