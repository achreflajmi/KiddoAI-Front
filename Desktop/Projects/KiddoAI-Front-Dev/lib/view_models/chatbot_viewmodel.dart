import 'package:flutter/material.dart';
import '../services/chatbot_service.dart';

class ChatbotViewModel extends ChangeNotifier {
  final ChatbotService _chatbotService = ChatbotService();
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<String> createThread() async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _chatbotService.createThread();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String message, String threadId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _chatbotService.sendMessage(message, threadId);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> sendWelcomeMessage(String threadId, double niveauIQ) async {
    _isLoading = true;
    notifyListeners();
    try {
      return await _chatbotService.sendWelcomeMessage(threadId, niveauIQ);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}