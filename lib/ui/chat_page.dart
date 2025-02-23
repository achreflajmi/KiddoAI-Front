import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
//import audio player
import 'package:audioplayers/audioplayers.dart';

import '../widgets/bottom_nav_bar.dart';

class ChatPage extends StatefulWidget {
  final String threadId;

  ChatPage({required this.threadId});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  late String threadId;
  final TextEditingController _controller = TextEditingController();
  final List<Message> messages = [];
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void initState() {
    super.initState();
    threadId = widget.threadId;
    if (threadId.isEmpty) {
      _getThreadId();
    }
    _loadMessages();
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
        messages.addAll(
            decodedMessages.map((msg) => Message.fromJson(msg)).toList());
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
    final encodedMessages =
        jsonEncode(messages.map((msg) => msg.toJson()).toList());
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
      Uri.parse(
          'https://aaa3-197-6-153-45.ngrok-free.app/KiddoAI/chat/send'), // CHANGE THIS WITH YOUR IP ADDRESS (ipconfig)
      body: jsonEncode({
        'threadId': threadId,
        'userInput': message,
      }),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      String botResponse = jsonDecode(response.body)['response'];
      setState(() {
        messages.add(Message(
          sender: 'bot',
          content: botResponse,
        ));
      });
      _saveMessages();
      _scrollToBottom();
      await _generateAndPlayVoice(botResponse);
    } else {
      print("Error: ${response.body}");
    }
  }

// tb3a vergil st3mltha fl chat t3k fo9 :3
  Future<void> _generateAndPlayVoice(String text) async {
    final response = await http.post(
      Uri.parse('https://93ae-102-156-135-121.ngrok-free.app/generate-voice'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "text": text,
        "speaker_wav": "sounds/SpongBob.wav",
      }),
    );

    if (response.statusCode == 200) {
      final String audioUrl = jsonDecode(response.body)['audio_url'];
      await _audioPlayer.play(UrlSource(audioUrl));
    } else {
      print("Error generating voice: ${response.body}");
    }
  }

  Widget _buildMessage(Message message) {
    final isUser = message.sender == 'user';
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser && message.showAvatar) ...[
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/spongebob.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ] else if (!isUser) ...[
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
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                message.content,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'voice chat',
          style: TextStyle(color: Colors.black, fontSize: 18),
        ),
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
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Write a message',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.grey),
                  onPressed: () {
                    _sendMessage(_controller.text);
                    _controller.clear();
                  },
                ),
              ],
            ),
          ),
          BottomNavBar(
            threadId: threadId,
            currentIndex: 2,
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

  Message(
      {required this.sender, required this.content, this.showAvatar = false});

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
