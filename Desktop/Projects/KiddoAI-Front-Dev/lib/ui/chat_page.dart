import 'package:flutter/material.dart';
import 'package:front_kiddoai/ui/profile_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../widgets/bottom_nav_bar.dart';
import 'dart:ui';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';

class Message {
  final String sender;
  final String content;
  final bool showAvatar;
  final bool isAudio;
  final DateTime timestamp;

  Message({
    required this.sender,
    required this.content,
    this.showAvatar = false,
    this.isAudio = false,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'content': content,
      'showAvatar': showAvatar,
      'isAudio': isAudio,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      sender: json['sender'],
      content: json['content'],
      showAvatar: json['showAvatar'] ?? false,
      isAudio: json['isAudio'] ?? false,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }
}


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
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _timer;
  late AnimationController _animationController;
  late Animation<double> _microphoneScaleAnimation;
  FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  bool _isRecording = false;
  bool _isTyping = false;
  bool _isSending = false;
  String _recordingDuration = "0:00";
  Timer? _recordingTimer;
  int _recordingSeconds = 0;

  Widget _buildMessage(Message message, int index) {
  final isUser = message.sender == 'user';
  final isLastMessage = index == messages.length - 1;
  final showTimestamp = isLastMessage || 
                        (index + 1 < messages.length &&
                         messages[index + 1].sender != message.sender);

  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    child: Row(
      mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (!isUser) ...[
          GestureDetector(
            onTap: () => _generateAndPlayVoice(message.content),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/spongebob.png'),
              radius: 16,
            ),
          ),
          SizedBox(width: 8),
        ],
        Flexible(
          child: GestureDetector(
            onTap: !isUser ? () => _generateAndPlayVoice(message.content) : null,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Color(0xFF4CAF50) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: isUser ? Radius.circular(20) : Radius.circular(4),
                  bottomRight: isUser ? Radius.circular(4) : Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: isUser ? Colors.white : Colors.black87,
                      fontSize: 16,
                      height: 1.4,
                    ),
                  ),
                  if (showTimestamp)
                    Padding(
                      padding: EdgeInsets.only(top: 6),
                      child: Text(
                        "${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}",
                        style: TextStyle(
                          color: isUser ? Colors.white.withOpacity(0.7) : Colors.black54,
                          fontSize: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}


  @override
  void initState() {
    super.initState();
    threadId = widget.threadId;
    if (threadId.isEmpty) {
      _getThreadId();
    }
    _loadMessages();
    _initializeRecorder();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _microphoneScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _controller.addListener(() {
      setState(() {
        _isTyping = _controller.text.isNotEmpty;
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _recordingTimer?.cancel();
    _audioRecorder.closeRecorder();
    _animationController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
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

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollToBottom();
        }
      });
    } else {
      setState(() {
        messages.add(Message(
          sender: 'bot',
          content: 'Hi there, friend!\nI\'m so excited to chat\nwith you!',
          timestamp: DateTime.now(),
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
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _sendMessage(String message) async {
  if (message.isEmpty) return;

  final DateTime timestamp = DateTime.now();

  setState(() {
    messages.add(Message(sender: 'user', content: message, timestamp: timestamp));
    _isSending = true;
  });

  _saveMessages();
  Future.delayed(Duration(milliseconds: 100), () => _scrollToBottom());

  try {
    final response = await http.post(
      Uri.parse('https://8fd8-102-154-202-95.ngrok-free.app/KiddoAI/chat/send'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({'threadId': threadId, 'userInput': message}),
    );

    if (response.statusCode == 200) {
      // Parse the JSON response
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      String botResponse = jsonResponse['response'];

      // Remove "response" and ":" from the text, and keep only the plain content
      // For example, if the response is '{"response": "مرحباً يا صديقي، كيف يمكنني مساعدتك؟"}',
      // we want to extract only "مرحباً يا صديقي، كيف يمكنني مساعدتك؟"
      if (botResponse.startsWith('"') && botResponse.endsWith('"')) {
        botResponse = botResponse.substring(1, botResponse.length - 1); // Remove quotes
      }
      // Optionally, you can trim any extra whitespace
      botResponse = botResponse.trim();

      setState(() {
        messages.add(Message(sender: 'bot', content: botResponse, timestamp: DateTime.now()));
        _isSending = false;
      });

      _saveMessages();
      _scrollToBottom();
      _generateAndPlayVoice(botResponse);
    } else {
      setState(() {
        _isSending = false;
        messages.add(Message(sender: 'bot', content: "Oops! Please try again!", timestamp: DateTime.now()));
      });
    }
  } catch (e) {
    setState(() {
      _isSending = false;
      messages.add(Message(sender: 'bot', content: "Connection error!", timestamp: DateTime.now()));
    });
  }
}

  Future<void> _generateAndPlayVoice(String text) async {
    try {
      final response = await http.post(
        Uri.parse('https://268b-196-184-222-196.ngrok-free.app/generate-voice'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"text": text, "speaker_wav": "sounds/SpongBob.wav"}),
      );

      if (response.statusCode == 200) {
        final String audioUrl = 'http://172.20.10.9:8001/outputlive.wav';
        await _audioPlayer.play(UrlSource(audioUrl));
      }
    } catch (e) {
      print("Error in voice generation/playback: $e");
    }
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

  Future<void> _startRecording() async {
    try {
      await _audioRecorder.startRecorder(toFile: 'audio.wav');
      setState(() {
        _isRecording = true;
      });
      _animationController.repeat(reverse: true);
    } catch (e) {
      print("Error starting recording: $e");
    }
  }

  Future<void> _stopRecording() async {
    try {
      String? path = await _audioRecorder.stopRecorder();
      if (path == null) return;

      setState(() {
        _isRecording = false;
        _animationController.stop();
      });

      final audioFile = File(path);
      final audioBytes = await audioFile.readAsBytes();

      final response = await _sendAudioToBackend(audioBytes);
      if (response != null) {
        setState(() {
          messages.add(Message(sender: 'bot', content: response, timestamp: DateTime.now()));
        });

        _saveMessages();
        _scrollToBottom();
        _generateAndPlayVoice(response);
      }
    } catch (e) {
      print("Error stopping recording: $e");
    }
  }

  Future<String?> _sendAudioToBackend(List<int> audioBytes) async {
    final uri = Uri.parse('https://8fd8-102-154-202-95.ngrok-free.app/KiddoAI/chat/transcribe');

    final request = http.MultipartRequest('POST', uri)
      ..fields['threadId'] = threadId
      ..files.add(http.MultipartFile.fromBytes('audio', audioBytes, filename: 'audio.wav'));

    final response = await request.send();
    if (response.statusCode == 200) {
      return await response.stream.bytesToString();
    }
    return null;
  }

@override
Widget build(BuildContext context) {
  if (threadId.isEmpty) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Lottie.network(
              'https://assets9.lottiefiles.com/packages/lf20_kkhbsucc.json',
              height: 150,
            ),
            SizedBox(height: 20),
            Text(
              "Loading your chat...",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  return Scaffold(
    backgroundColor: Color.fromARGB(255, 242, 244, 249),
    appBar: AppBar(
      backgroundColor: Color(0xFF049a02),
      elevation: 0,
      centerTitle: true,
      title: RichText(
        text: TextSpan(
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          children: [
            TextSpan(
              text: 'K',
              style: TextStyle(color: Colors.white),
            ),
            TextSpan(text: 'iddo'),
            TextSpan(
              text: 'A',
              style: TextStyle(color: Colors.white),
            ),
            TextSpan(text: 'i Chat'),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: EdgeInsets.only(right: 16),
          child: GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ProfilePage(threadId: threadId)),
            ),
            child: CircleAvatar(
              backgroundImage: AssetImage('assets/spongebob.png'),
              radius: 18,
            ),
          ),
        ),
      ],
    ),
    body: Stack(
      children: [
        // Chat messages list
        Positioned.fill(
          child: ListView.builder(
            controller: _scrollController,
            padding: EdgeInsets.only(top: 220, bottom: 100),
            itemCount: messages.length,
            itemBuilder: (context, index) => _buildMessage(messages[index], index),
          ),
        ),

        // Blurred background for SpongeBob and status
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 170,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF049a02).withOpacity(0.8),
                  Color(0xFF049a02).withOpacity(0.0),
                ],
              ),
            ),
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(color: Colors.transparent),
              ),
            ),
          ),
        ),

        // SpongeBob Image with a card
        Positioned(
          top: 16,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              clipBehavior: Clip.none,
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(70),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(70),
                    child: Image.asset(
                      'assets/spongebob.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  // Animated effect when speaking
                  if (_isRecording || _isSending)
                    Positioned.fill(
                      child: Lottie.network(
                        'https://assets1.lottiefiles.com/packages/lf20_vctzcozn.json',
                        fit: BoxFit.cover,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),

        // Status text below SpongeBob
        Positioned(
          top: 160,
          left: 0,
          right: 0,
          child: Center(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: _isRecording
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Recording... $_recordingDuration",
                          style: TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    )
                  : _isSending
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF049a02)),
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Thinking...",
                              style: TextStyle(
                                color: Color(0xFF049a02),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Text(
                          "Let's chat!",
                          style: TextStyle(
                            color: Color(0xFF049a02),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
            ),
          ),
        ),

        // Input field with microphone and send button
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: ClipRect(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: _isRecording
                                ? Colors.red.withOpacity(0.5)
                                : _isTyping
                                    ? Color(0xFF049a02).withOpacity(0.5)
                                    : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            GestureDetector(
                              onLongPressStart: (_) => _startRecording(),
                              onLongPressEnd: (_) => _stopRecording(),
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 12),
                                child: AnimatedBuilder(
                                  animation: _animationController,
                                  builder: (context, child) {
                                    return Transform.scale(
                                      scale: _isRecording
                                          ? 1.0 + 0.2 * _microphoneScaleAnimation.value
                                          : 1.0,
                                      child: Icon(
                                        _isRecording ? Icons.stop : Icons.mic,
                                        color: _isRecording ? Colors.red : Color(0xFF4CAF50),
                                        size: 28,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.symmetric(horizontal: 20),
                                child: TextField(
                                  controller: _controller,
                                  decoration: InputDecoration(
                                    hintText: _isRecording ? 'Recording...' : 'Type your message...',
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(
                                      color: _isRecording ? Colors.red.withOpacity(0.6) : Colors.grey[600],
                                    ),
                                  ),
                                  style: TextStyle(fontSize: 16),
                                  maxLines: null,
                                  enabled: !_isRecording,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.send_rounded),
                              color: Color(0xFF4CAF50),
                              iconSize: 28,
                              onPressed: () {
                                if (_controller.text.isNotEmpty) {
                                  _sendMessage(_controller.text);
                                  _controller.clear();
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
    bottomNavigationBar: BottomNavBar(
      threadId: threadId,
      currentIndex: 2,
    ),
  );
}
}