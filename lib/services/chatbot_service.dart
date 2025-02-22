import 'dart:convert';
import 'package:http/http.dart' as http;

class ChatbotService {
  final String baseUrl = 'https://aaa3-197-6-153-45.ngrok-free.app/KiddoAI';  // CHANGE THIS WITH YOUR IP ADDRESS (ipconfig)

  // Fetch thread ID from the backend
  Future<String> createThread() async {
    final response = await http.post(Uri.parse('$baseUrl/chat/create_thread'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['thread_id']; // Extract thread_id from response
    } else {    
      throw Exception('Failed to create thread');
    }
  }

// Send a message to the chatbot (with threadId)
Future<void> sendMessage(String message, String threadId) async {
  if (message.isEmpty) return;

  final response = await http.post(
    Uri.parse('$baseUrl/chat/send?threadId=$threadId'), // Pass threadId as a query parameter
    body: jsonEncode({
      'userInput': message,  // Send 'userInput' in the body as JSON
    }),
    headers: {"Content-Type": "application/json"},
  );

  if (response.statusCode == 200) {
    print("Chatbot response: ${jsonDecode(response.body)['response']}");
  } else {
    print("Error: ${response.body}");
  }
}

// Send a welcoming message to the chatbot
Future<String> sendWelcomeMessage(String threadId, double niveauIQ) async {
  final response = await http.post(
    Uri.parse('$baseUrl/chat/welcome?threadId=$threadId'), // Pass threadId as a query parameter
    body: jsonEncode({
      'niveauIQ': niveauIQ.toString(),
    }),
    headers: {"Content-Type": "application/json"},
  );

  if (response.statusCode == 200) {
    return jsonDecode(response.body)['response'];
  } else {
    throw Exception('Failed to send welcome message');
  }
}

  }

