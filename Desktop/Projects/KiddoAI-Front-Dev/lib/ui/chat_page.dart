import 'package:flutter/material.dart';
import 'package:front_kiddoai/ui/profile_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../widgets/bottom_nav_bar.dart';
import 'dart:ui'; // For blur effect
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart'; // For getting app directories
import 'dart:io'; // For File class
import 'package:permission_handler/permission_handler.dart'; // For requesting permissions

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

  @override
  void dispose() {
    _timer?.cancel();
    _audioRecorder.closeRecorder();
    _animationController.dispose();
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
      Uri.parse('https://8fd8-102-154-202-95.ngrok-free.app/KiddoAI/chat/send'),
      body: jsonEncode({
        'threadId': threadId,
        'userInput': message,
      }),
      headers: {"Content-Type": "application/json"},
    );

    if (response.statusCode == 200) {
      String botResponse = response.body; // Use the raw response body as plain text

      setState(() {
        messages.add(Message(
          sender: 'bot',
          content: botResponse,
        ));
      });
      _saveMessages();
      _scrollToBottom();
    } else {
      print("Error: ${response.body}");
    }
  }

  Future<void> _generateAndPlayVoice(String text) async {
    try {
      final response = await http.post(
        Uri.parse('https://86fb-197-6-81-221.ngrok-free.app/generate-voice'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "text": text,
          "speaker_wav": "sounds/SpongBob.wav",
        }),
      );

      if (response.statusCode == 200) {
        final String audioUrl = 'http://172.20.10.9:8001/outputlive.wav';
        final cacheBuster = DateTime.now().millisecondsSinceEpoch;
        final uniqueUrl = '$audioUrl?cache=$cacheBuster';

        final headResponse = await http.head(Uri.parse(uniqueUrl));
        if (headResponse.statusCode != 200) {
          throw Exception('Audio file not found');
        }

        await _audioPlayer.play(UrlSource(audioUrl));
        print("Audio played successfully");
      } else {
        print("Error generating voice: ${response.body}");
      }
    } catch (e) {
      print("Error in voice generation/playback: $e");
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
        _animationController.stop(); // Stop the animation when recording stops
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
        _animationController.repeat(reverse: true); // Trigger animation when speaking
      }
    } catch (e) {
      print("Error starting recording: $e");
    }
  }

  Future<String?> _sendAudioToBackend(List<int> audioBytes) async {
    final uri = Uri.parse('https://8fd8-102-154-202-95.ngrok-free.app/KiddoAI/chat/transcribe');
    
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
      return responseBody; // Return the raw response as plain text
    }

    print("Error: Failed to send audio to backend.");
    return null;
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

  Widget _buildMessage(Message message) {
    final isUser = message.sender == 'user';
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundImage: AssetImage('assets/spongebob.png'),
              radius: 16,
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
                child: Material(
                  elevation: 1,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: isUser ? Radius.circular(20) : Radius.circular(4),
                    bottomRight: isUser ? Radius.circular(4) : Radius.circular(20),
                  ),
                  color: isUser ? Color(0xFF4CAF50) : Colors.white,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 16,
                        height: 1.4,
                      ),
                      softWrap: true,
                      overflow: TextOverflow.visible,
                    ),
                  ),
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
      backgroundColor: Color.fromARGB(255, 242, 244, 249),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Voice Chat',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => ProfilePage()),
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
          // 1) The ListView behind everything (except the blurred background),
          //    so it can scroll under the SpongeBob card.
          Positioned.fill(
            child: ListView.builder(
              controller: _scrollController,
              // Provide top padding so messages begin below SpongeBob
              padding: EdgeInsets.only(top: 220, bottom: 100),
              itemCount: messages.length,
              itemBuilder: (context, index) => _buildMessage(messages[index]),
            ),
          ),

          // 2) Blurred background for the top area
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  height: 170,
                  color: Colors.transparent,
                ),
              ),
            ),
          ),

          // 3) SpongeBob Image with White Card on top
          Positioned(
            top: 16,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                // If you find this container is clipping your text,
                // you can set clipBehavior: Clip.none here
                clipBehavior: Clip.none,
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(1),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    'assets/spongebob.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
         ),

          // 4) Input Field at the bottom with Microphone Icon
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRect(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
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
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onLongPressStart: (_) => _startRecording(),
                                onLongPressEnd: (_) => _stopRecording(),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 12),
                                  child: ScaleTransition(
                                    scale: _microphoneScaleAnimation,
                                    child: Icon(
                                      _isRecording ? Icons.stop : Icons.mic,
                                      color: _isRecording ? Colors.red : Color(0xFF4CAF50),
                                      size: 28,
                                    ),
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(horizontal: 20),
                                  child: TextField(
                                    controller: _controller,
                                    decoration: InputDecoration(
                                      hintText: 'Type your message...',
                                      border: InputBorder.none,
                                      hintStyle: TextStyle(color: Colors.grey[600]),
                                    ),
                                    style: TextStyle(fontSize: 16),
                                    maxLines: null,
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
