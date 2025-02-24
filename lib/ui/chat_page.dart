import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart'; // For getting app directories

class ChatPage extends StatefulWidget {
  final String threadId;

  ChatPage({required this.threadId});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  late String threadId;
  final TextEditingController _controller = TextEditingController();
  final List<Message> messages = [];
  final ScrollController _scrollController = ScrollController();

  FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  bool _isRecording = false;
  late AnimationController _animationController;
  late Animation<double> _microphoneScaleAnimation;

  @override
  void initState() {
    super.initState();
    threadId = widget.threadId;
    if (threadId.isEmpty) {
      _getThreadId();
    }
    _loadMessages();
    _initializeRecorder();

    // Animation for recording button scaling
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _microphoneScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeRecorder() async {
    try {
      await _requestPermissions();
      await _audioRecorder.openRecorder();
    } catch (e) {
      print("Error initializing recorder: $e");
    }
  }

  Future<void> _requestPermissions() async {
    await [Permission.microphone, Permission.storage].request();
  }

  Future<void> _getThreadId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      threadId = prefs.getString('threadId') ?? '';
    });
  }

  Future<void> _loadMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final savedMessages = prefs.getString('chatMessages_$threadId');
    
    if (savedMessages != null) {
      final List<dynamic> decodedMessages = jsonDecode(savedMessages);
      setState(() {
        messages.clear();
        messages.addAll(decodedMessages.map((msg) => Message.fromJson(msg)).toList());
      });
    } else {
      setState(() {
        messages.add(Message(
          sender: 'bot',
          content: 'Hi there, friend!\nI\'m so excited to chat\nwith you!',
          showAvatar: true,
        ));
      });
    }
  }

  Future<void> _saveMessages() async {
    final prefs = await SharedPreferences.getInstance();
    final encodedMessages = jsonEncode(messages.map((msg) => msg.toJson()).toList());
    await prefs.setString('chatMessages_$threadId', encodedMessages);
  }

  void _scrollToBottom() {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent,
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  Future<void> _sendMessage(String message) async {
    if (message.isEmpty) return;

    setState(() {
      messages.add(Message(sender: 'user', content: message));
    });

    _saveMessages();
    _scrollToBottom();

    final response = await http.post(
      Uri.parse('https://aaa3-197-6-153-45.ngrok-free.app/KiddoAI/chat/send'),
      body: jsonEncode({
        'threadId': threadId,
        'userInput': message,
      }),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      setState(() {
        messages.add(Message(
          sender: 'user',
          content: jsonDecode(response.body)['response'],
        ));
      });
      _saveMessages();
      _scrollToBottom();
    } else {
      print("Error: ${response.body}");
    }
  }

  Future<void> _stopRecording() async {
    try {
      String? path = await _audioRecorder.stopRecorder();
      if (path == null) {
        print("Error: Recording failed or path is null.");
        return;
      }

      setState(() {
        _isRecording = false;
      });

      print("Audio file saved at: $path");

      final audioFile = File(path);
      final audioBytes = await audioFile.readAsBytes();

      final response = await _sendAudioToBackend(audioBytes);

      if (response != null) {
        // Only add the transcription as a bot message.
        setState(() {
          messages.add(Message(sender: 'bot', content: response));
        });

        _controller.clear();
        _saveMessages();
        _scrollToBottom();
      } else {
        print("Error: No response from backend.");
      }
    } catch (e) {
      print("Error stopping recording: $e");
    }
  }

  Future<void> _startRecording() async {
    try {
      if (!_isRecording) {
        // Start recording
        await _audioRecorder.startRecorder(toFile: 'audio.wav');
        setState(() {
          _isRecording = true;
        });
        _animationController.repeat(reverse: true);  // Trigger animation when speaking
      }
    } catch (e) {
      print("Error starting recording: $e");
    }
  }

  Future<String?> _sendAudioToBackend(List<int> audioBytes) async {
    final uri = Uri.parse('https://aaa3-197-6-153-45.ngrok-free.app/KiddoAI/chat/transcribe');
    
    if (threadId.isEmpty) {
      print("Error: threadId is empty");
      return null;
    }

    final request = http.MultipartRequest('POST', uri)
      ..fields['threadId'] = threadId
      ..files.add(http.MultipartFile.fromBytes('audio', audioBytes, filename: 'audio.wav'));

    final response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      print("Backend response body: $responseBody");
      return responseBody;
    }

    print("Error: Failed to send audio to backend.");
    return null;
  }

  @override
  void dispose() {
    _audioRecorder.closeRecorder();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (threadId.isEmpty) {
      return Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        title: Text('Voice Chat', style: TextStyle(color: Colors.black, fontSize: 18)),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/spongebob.png'),
              radius: 18,
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: messages.length,
              itemBuilder: (context, index) {
                return _buildMessage(messages[index]);
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onLongPressStart: (_) => _startRecording(),
                  onLongPressEnd: (_) => _stopRecording(),
                  child: ScaleTransition(
                    scale: _microphoneScaleAnimation,
                    child: Icon(
                      _isRecording ? Icons.stop : Icons.mic,
                      color: _isRecording ? Colors.red : Colors.blue,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Type a message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)),
                      filled: true,
                      fillColor: Colors.grey[200],
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.blue),
                  onPressed: () {
                    _sendMessage(_controller.text);
                    _controller.clear();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(Message message) {
    final isUser = message.sender == 'user';
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundImage: AssetImage('assets/spongebob.png'),
              radius: 16,
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Color(0xFF4CAF50) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: Offset(0, 2)),
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(color: isUser ? Colors.white : Colors.black87, fontSize: 16),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class Message {
  final String sender;
  final String content;
  final bool showAvatar;

  Message({
    required this.sender,
    required this.content,
    this.showAvatar = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'content': content,
      'showAvatar': showAvatar,
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      sender: json['sender'],
      content: json['content'],
      showAvatar: json['showAvatar'] ?? false,
    );
  }
}