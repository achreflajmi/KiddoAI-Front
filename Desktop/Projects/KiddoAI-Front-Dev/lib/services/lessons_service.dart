import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert' show utf8;

class LessonsService {
  // Base URL - Replace with your actual backend URL
  final String _baseUrl;
  final String _baseTeachLessonUrl;
  final String _baseActivityUrl;
  final String _baseVoiceGenerationUrl;
  final String _baseAudioUrl;
  final String _activityPageUrl;
  final String _baseLessonsUrl;

  // Constructor to initialize the URLs
  LessonsService()
      : _baseUrl = 'https://a607-102-27-195-209.ngrok-free.app',
        _baseTeachLessonUrl = 'https://a607-102-27-195-209.ngrok-free.app/KiddoAI/chat/teach_lesson',
        _baseActivityUrl = 'https://a607-102-27-195-209.ngrok-free.app/KiddoAI/Activity/problem',
        _baseVoiceGenerationUrl = 'https://268b-196-184-222-196.ngrok-free.app/generate-voice',
        _baseAudioUrl = 'http://172.20.10.9:8001/outputlive.wav',
        _activityPageUrl = 'http://172.20.10.4:8080/',
        _baseLessonsUrl = 'https://a607-102-27-195-209.ngrok-free.app/KiddoAI/Lesson/bySubject'; // Updated to match ngrok logs

  Future<List<Map<String, dynamic>>> fetchLessons(String subjectName) async {
    try {
      // Encode the subject name to ensure proper URL formatting
      final encodedSubject = Uri.encodeComponent(subjectName);
      final url = Uri.parse('$_baseLessonsUrl/$encodedSubject');
      print('Fetching lessons from: $url'); // Debug log
      final response = await http.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      print('Response status: ${response.statusCode}'); // Debug log
      print('Response body: ${response.body}'); // Debug log

      if (response.statusCode == 200) {
        final List<dynamic> lessonsJson = jsonDecode(response.body);
        return lessonsJson.map((lesson) => {
          'name': lesson['name'] as String? ?? 'Unnamed Lesson',
          'description': lesson['description'] as String? ?? 'No description available', // Adjust if 'description' is missing
        }).toList();
      } else {
        throw Exception('Failed to fetch lessons: Status code ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error fetching lessons: $e');
    }
  }

  Future<String> teachLesson(String lessonName, String subjectName) async {
    final prefs = await SharedPreferences.getInstance();
    final threadId = prefs.getString('threadId') ?? '';
    
    if (threadId.isEmpty) {
      throw Exception('No threadId found. Please login again.');
    }
    
    try {
      final response = await http.post(
        Uri.parse(_baseTeachLessonUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'threadId': threadId,
          'lessonName': lessonName,
          'subjectName': subjectName,
        }),
      );
      
      if (response.statusCode == 200) {
        try {
          final decodedResponse = jsonDecode(response.body);
          if (decodedResponse is Map && decodedResponse.containsKey('response')) {
            return decodedResponse['response'] as String? ?? '';
          } else {
            return response.body;
          }
        } catch (_) {
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
      final response = await http.post(
        Uri.parse(_baseVoiceGenerationUrl),
        headers: {"Content-Type": "application/json"},
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
      bool isActivityReady = false;
      
      while (!isActivityReady) {
        final response = await http.post(
          Uri.parse(_baseActivityUrl),
          headers: {"Content-Type": "application/json"},
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