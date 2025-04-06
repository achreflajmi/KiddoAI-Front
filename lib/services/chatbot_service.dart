// services/chatbot_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/message.dart';

class ChatbotService {
  static const String _baseUrl = 'https://b736-2c0f-4280-0-6132-b43c-1e54-c386-db5d.ngrok-free.app/KiddoAI';
  static const String _voiceGenerationUrl = 'https://268b-196-184-222-196.ngrok-free.app/generate-voice';
  static const String _audioUrl = 'http://172.20.10.9:8001/outputlive.wav';

  Future<String> createThread() async {
    final response = await http.post(Uri.parse('$_baseUrl/chat/create_thread'));
    if (response.statusCode == 200) {
      final threadId = jsonDecode(response.body)['thread_id'];
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('threadId', threadId);
      return threadId;
    }
    throw Exception('Failed to create thread');
  }

  Future<String?> getThreadId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('threadId');
  }

  Future<void> saveMessages(String threadId, List<Message> messages) async {
    final prefs = await SharedPreferences.getInstance();
    final encodedMessages = jsonEncode(messages.map((msg) => msg.toJson()).toList());
    await prefs.setString('chatMessages_$threadId', encodedMessages);
  }

  Future<List<Message>> loadMessages(String threadId) async {
    final prefs = await SharedPreferences.getInstance();
    final savedMessages = prefs.getString('chatMessages_$threadId');
    
    if (savedMessages != null) {
      final List<dynamic> decodedMessages = jsonDecode(savedMessages);
      return decodedMessages.map((msg) => Message.fromJson(msg)).toList();
    }
    return [
      Message(
        sender: 'bot',
        content: 'Hi there, friend!\nI\'m so excited to chat\nwith you!',
        timestamp: DateTime.now(),
      )
    ];
  }

  Future<String> sendMessage(String message, String threadId) async {
    if (message.isEmpty) return '';
    
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/send'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({'threadId': threadId, 'userInput': message}),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      String botResponse = jsonResponse['response'];
      return botResponse.trim().replaceAll(RegExp(r'^"|"$'), '');
    }
    throw Exception('Failed to send message');
  }

  Future<String?> sendAudioMessage(List<int> audioBytes, String threadId) async {
    final uri = Uri.parse('$_baseUrl/chat/transcribe');
    final request = http.MultipartRequest('POST', uri)
      ..fields['threadId'] = threadId
      ..files.add(http.MultipartFile.fromBytes('audio', audioBytes, filename: 'audio.wav'));

    final response = await request.send();
    if (response.statusCode == 200) {
      return await response.stream.bytesToString();
    }
    return null;
  }

  Future<String> generateVoice(String text) async {
    final response = await http.post(
      Uri.parse(_voiceGenerationUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"text": text, "speaker_wav": "sounds/SpongBob.wav"}),
    );

    if (response.statusCode == 200) {
      return _audioUrl;
    }
    throw Exception('Failed to generate voice');
  }

  Future<String> sendWelcomeMessage(String threadId, double niveauIQ) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/chat/welcome'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        'threadId': threadId,
        'niveauIQ': niveauIQ.toString(),
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)['response'];
    }
    throw Exception('Failed to send welcome message');
  }
}