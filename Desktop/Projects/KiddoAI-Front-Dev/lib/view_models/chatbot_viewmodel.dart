// viewmodels/chat_view_model.dart
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/message.dart';
import '../services/chatbot_service.dart';

class ChatViewModel extends ChangeNotifier {
  final ChatbotService _chatbotService;
  final AudioPlayer _audioPlayer = AudioPlayer();
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();

  List<Message> _messages = [];
  String _threadId = '';
  bool _isLoading = false;
  bool _isSending = false;
  bool _isRecording = false;
  bool _isTyping = false;
  String _recordingDuration = "0:00";
  int _recordingSeconds = 0;
  Timer? _recordingTimer;
  String _errorMessage = '';

  ChatViewModel(this._chatbotService);

  // Getters
  List<Message> get messages => _messages;
  String get threadId => _threadId;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;
  bool get isRecording => _isRecording;
  bool get isTyping => _isTyping;
  String get recordingDuration => _recordingDuration;
  String get errorMessage => _errorMessage;

  Future<void> initialize() async {
    _setLoading(true);
    try {
      await _initializeRecorder();
      _threadId = await _chatbotService.getThreadId() ?? await _chatbotService.createThread();
      _messages = await _chatbotService.loadMessages(_threadId);
    } catch (e) {
      _errorMessage = 'Error initializing chat: $e';
    } finally {
      _setLoading(false);
    }
  }

  void onTextChanged(String text) {
    _isTyping = text.isNotEmpty;
    notifyListeners();
  }

  Future<void> sendTextMessage(String text) async {
    if (text.isEmpty || _threadId.isEmpty) return;

    _setSending(true);
    try {
      final userMessage = Message(sender: 'user', content: text, timestamp: DateTime.now());
      _addMessage(userMessage);

      final botResponse = await _chatbotService.sendMessage(text, _threadId);
      final botMessage = Message(sender: 'bot', content: botResponse, timestamp: DateTime.now());
      _addMessage(botMessage);

      await _generateAndPlayVoice(botResponse);
    } catch (e) {
      _errorMessage = 'Error sending message: $e';
      _addMessage(Message(
        sender: 'bot',
        content: "Connection error! Please try again.",
        timestamp: DateTime.now(),
      ));
    } finally {
      _setSending(false);
    }
  }

  Future<void> startRecording() async {
    try {
      await _audioRecorder.startRecorder(toFile: 'audio.wav');
      _isRecording = true;
      _startRecordingTimer();
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Error starting recording: $e';
    }
  }

  Future<void> stopRecording() async {
    try {
      final path = await _audioRecorder.stopRecorder();
      _stopRecordingTimer();
      _isRecording = false;

      if (path != null) {
        final audioFile = File(path);
        final audioBytes = await audioFile.readAsBytes();
        await _processAudioMessage(audioBytes);
      }
    } catch (e) {
      _errorMessage = 'Error stopping recording: $e';
    } finally {
      notifyListeners();
    }
  }

  Future<void> _processAudioMessage(List<int> audioBytes) async {
    _setSending(true);
    try {
      final transcribedText = await _chatbotService.sendAudioMessage(audioBytes, _threadId);
      if (transcribedText != null && transcribedText.isNotEmpty) {
        final userMessage = Message(sender: 'user', content: transcribedText, timestamp: DateTime.now());
        _addMessage(userMessage);

        final botResponse = await _chatbotService.sendMessage(transcribedText, _threadId);
        final botMessage = Message(sender: 'bot', content: botResponse, timestamp: DateTime.now());
        _addMessage(botMessage);

        await _generateAndPlayVoice(botResponse);
      }
    } catch (e) {
      _errorMessage = 'Error processing audio: $e';
    } finally {
      _setSending(false);
    }
  }

  Future<void> _generateAndPlayVoice(String text) async {
    try {
      final audioUrl = await _chatbotService.generateVoice(text);
      await _audioPlayer.play(UrlSource(audioUrl));
    } catch (e) {
      _errorMessage = 'Error playing voice: $e';
    }
  }

  void _addMessage(Message message) {
    _messages.add(message);
    _chatbotService.saveMessages(_threadId, _messages);
    notifyListeners();
  }

  Future<void> _initializeRecorder() async {
    try {
      await [Permission.microphone, Permission.storage].request();
      await _audioRecorder.openRecorder();
    } catch (e) {
      _errorMessage = 'Error initializing recorder: $e';
    }
  }

  void _startRecordingTimer() {
    _recordingSeconds = 0;
    _recordingDuration = "0:00";
    _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      _recordingSeconds++;
      final minutes = _recordingSeconds ~/ 60;
      final seconds = _recordingSeconds % 60;
      _recordingDuration = "$minutes:${seconds.toString().padLeft(2, '0')}";
      notifyListeners();
    });
  }

  void _stopRecordingTimer() {
    _recordingTimer?.cancel();
    _recordingTimer = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setSending(bool value) {
    _isSending = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioRecorder.closeRecorder();
    _audioPlayer.dispose();
    super.dispose();
  }
}