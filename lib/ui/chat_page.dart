
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
import '../models/avatar_settings.dart'; // Ensure this import is correct

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

  // Avatar settings
  final List<Map<String, dynamic>> _avatars = [
    {
      'name': 'SpongeBob',
      'imagePath': 'assets/avatars/spongebob.png',
      'voicePath': 'assets/voices/spongebob.wav',
      'color': Color(0xFFFFEB3B),
      'gradient': [Color.fromARGB(255, 206, 190, 46), Color(0xFFFFF9C4)],
    },
    {
      'name': 'Gumball',
      'imagePath': 'assets/avatars/gumball.png',
      'voicePath': 'assets/voices/gumball.wav',
      'color': Color(0xFF2196F3),
      'gradient': [Color.fromARGB(255, 48, 131, 198), Color(0xFFE3F2FD)],
    },
    {
      'name': 'SpiderMan',
      'imagePath': 'assets/avatars/spiderman.png',
      'voicePath': 'assets/voices/spiderman.wav',
      'color': Color.fromARGB(255, 227, 11, 18),
      'gradient': [Color.fromARGB(255, 203, 21, 39), Color(0xFFFFEBEE)],
    },
    {
      'name': 'HelloKitty',
      'imagePath': 'assets/avatars/hellokitty.png',
      'voicePath': 'assets/voices/hellokitty.wav',
      'color': Color(0xFFFF80AB),
      'gradient': [Color.fromARGB(255, 255, 131, 174), Color(0xFFFCE4EC)],
    },
  ];

  String _currentAvatarName = '';
  String _currentAvatarImage = '';
  String _currentVoicePath = '';
  Color _currentAvatarColor = Colors.green;
  List<Color> _currentAvatarGradient = [Colors.white, Colors.white];

  @override
  void initState() {
    super.initState();
    threadId = widget.threadId;
    if (threadId.isEmpty) {
      _getThreadId();
    }
    _loadMessages();
    _loadAvatarSettings(); // Load avatar settings
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

  Future<void> _loadAvatarSettings() async {
    final avatar = await AvatarSettings.getCurrentAvatar();
    setState(() {
      _currentAvatarName = avatar['name'] ?? 'SpongeBob';
      _currentAvatarImage = avatar['imagePath'] ?? 'assets/avatars/spongebob.png';
      _currentVoicePath = avatar['voicePath'] ?? 'assets/voices/spongebob.wav';
      final selectedAvatar = _avatars.firstWhere(
        (a) => a['name'] == _currentAvatarName,
        orElse: () => _avatars[0],
      );
      _currentAvatarColor = selectedAvatar['color'];
      _currentAvatarGradient = selectedAvatar['gradient'];
    });
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
          content: 'مرحباً! كيف حالك اليوم؟',
          timestamp: DateTime.now(),
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
    // 👇 Add temporary "typing..." message
    messages.add(Message(sender: 'bot', content: 'typing_indicator', timestamp: DateTime.now()));
  });

  _saveMessages();
  Future.delayed(Duration(milliseconds: 100), () => _scrollToBottom());

  try {
    final response = await http.post(
      Uri.parse('https://7aaf-41-226-166-49.ngrok-free.app/KiddoAI/chat/send'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({'threadId': threadId, 'userInput': message}),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
      String botResponse = jsonResponse['response'];

      if (botResponse.startsWith('"') && botResponse.endsWith('"')) {
        botResponse = botResponse.substring(1, botResponse.length - 1);
      }
      botResponse = botResponse.trim();

      setState(() {
        // Remove the "typing..." indicator
        messages.removeWhere((m) => m.content == 'typing_indicator');
        // Add real bot response
        messages.add(Message(sender: 'bot', content: botResponse, timestamp: DateTime.now()));
        _isSending = false;
      });

      _saveMessages();
      _scrollToBottom();
      _initializeVoice(botResponse);
    } else {
      setState(() {
        _isSending = false;
        messages.removeWhere((m) => m.content == 'typing_indicator');
        messages.add(Message(sender: 'bot', content: "Oops! Please try again!", timestamp: DateTime.now()));
      });
    }
  } catch (e) {
    setState(() {
      _isSending = false;
      messages.removeWhere((m) => m.content == 'typing_indicator');
      messages.add(Message(sender: 'bot', content: "Connection error!", timestamp: DateTime.now()));
    });
  }
}


  Future<void> _initializeVoice(String text) async {
    try {
      final baseUrl = 'https://8f36-160-159-94-45.ngrok-free.app';
      final response = await http.post(
        Uri.parse('$baseUrl/initialize-voice'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "text": text,
          "speaker_wav": "sounds/${_currentAvatarName}.wav",
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final requestId = data['request_id'] as String;
        final totalParts = data['total_parts'] as int;

        int currentPart = 1;
        while (currentPart <= totalParts) {
          String? audioUrl;
          while (audioUrl == null) {
            final statusResponse = await http.get(
              Uri.parse('$baseUrl/part-status/$requestId/$currentPart'),
            );
            if (statusResponse.statusCode == 200) {
              final statusData = jsonDecode(statusResponse.body);
              if (statusData['status'] == 'done') {
                audioUrl = statusData['audio_url'];
              } else {
                await Future.delayed(Duration(seconds: 1));
              }
            } else {
              throw Exception('Error checking status for part $currentPart');
            }
          }

          await _audioPlayer.play(UrlSource(audioUrl));
          await _audioPlayer.onPlayerComplete.first;
          currentPart++;
        }
      } else {
        print("Error initializing voice: ${response.body}");
      }
    } catch (e) {
      print("Error in voice initialization/playback: $e");
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
        _recordingSeconds = 0;
        _recordingDuration = "0:00";
      });
      _animationController.repeat(reverse: true);

      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
        setState(() {
          _recordingSeconds++;
          final minutes = (_recordingSeconds ~/ 60).toString().padLeft(2, '0');
          final seconds = (_recordingSeconds % 60).toString().padLeft(2, '0');
          _recordingDuration = "$minutes:$seconds";
        });
      });
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
        _recordingTimer?.cancel();
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
        _initializeVoice(response);
      }
    } catch (e) {
      print("Error stopping recording: $e");
    }
  }

  Future<String?> _sendAudioToBackend(List<int> audioBytes) async {
    final uri = Uri.parse('https://7aaf-41-226-166-49.ngrok-free.app/KiddoAI/chat/transcribe');

    final request = http.MultipartRequest('POST', uri)
      ..fields['threadId'] = threadId
      ..files.add(http.MultipartFile.fromBytes('audio', audioBytes, filename: 'audio.wav'));

    final response = await request.send();
    if (response.statusCode == 200) {
      return await response.stream.bytesToString();
    }
    return null;
  }

Widget _buildMessage(Message message, int index) {
  final isUser = message.sender == 'user';
  final isTypingIndicator = message.content == 'typing_indicator';
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
            onTap: () => _initializeVoice(message.content),
            child: CircleAvatar(
              backgroundImage: AssetImage(_currentAvatarImage),
              radius: 16,
            ),
          ),
          SizedBox(width: 8),
        ],
        Flexible(
          child: GestureDetector(
            onTap: !isUser && !isTypingIndicator ? () => _initializeVoice(message.content) : null,
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? Color(0xFF4CAF50) : Colors.white,
                border: isUser ? null : Border.all(color: _currentAvatarColor, width: 2),
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
              child: isTypingIndicator
                  ? Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(3, (i) {
                        final controller = AnimationController(
                          vsync: this,
                          duration: Duration(milliseconds: 600),
                        )..repeat(reverse: true);

                        final delay = i * 200;

                        return AnimatedBuilder(
                          animation: controller,
                          builder: (context, child) {
                            final value = Curves.easeInOut.transform(controller.value);
                            return Container(
                              margin: EdgeInsets.symmetric(horizontal: 3),
                              child: Transform.translate(
                                offset: Offset(0, -6 * value * (i == 1 ? 1.2 : 1.0)),
                                child: Container(
                                  width: 8,
                                  height: 8,
                                  decoration: BoxDecoration(
                                    color: Colors.grey,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      }),
                    )
                  : Column(
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
  Widget build(BuildContext context) {
if (threadId.isEmpty) {
  return Scaffold(
    body: Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: _currentAvatarGradient,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            LottieBuilder.network(
                'assets/loadingChat.json',
              onLoaded: (composition) {
                debugPrint("✅ Lottie loaded: ${composition.duration}");
              },
              errorBuilder: (context, error, stackTrace) {
                debugPrint("❌ Lottie load failed: $error");
                debugPrint("🧠 Stack trace: $stackTrace");
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.warning, size: 40, color: Colors.red),
                    Text('Animation failed.', style: TextStyle(color: Colors.red)),
                  ],
                );
              },
            ),
            SizedBox(height: 20),
            Text(
              "Loading your magical chat...",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _currentAvatarColor,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  

    return Scaffold(
      backgroundColor: _currentAvatarGradient.last,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70),
        child: AppBar(
         backgroundColor: _currentAvatarColor,
          elevation: 0,
          centerTitle: true,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                _currentAvatarImage,
                height: 40,
                width: 40,
              ),
              SizedBox(width: 10),
              RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Comic Sans MS',
                  ),
                  children: [
                    TextSpan(
                      text: 'K',
                      style: TextStyle(color: Colors.yellow),
                    ),
                    TextSpan(
                      text: 'iddo',
                      style: TextStyle(color: Colors.white),
                    ),
                    TextSpan(
                      text: 'A',
                      style: TextStyle(color: Colors.yellow),
                    ),
                    TextSpan(
                      text: 'i',
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage(threadId: widget.threadId)),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                   border: Border.all(color: _currentAvatarColor, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundImage: AssetImage(_currentAvatarImage),
                    radius: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _currentAvatarGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: AssetImage(_currentAvatarImage),
                      fit: BoxFit.contain,
                      opacity: 0.05,
                      alignment: Alignment.center,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Container(
                  margin: EdgeInsets.only(top: 175, bottom: 85),
                  child: Container(
                    margin: EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: _currentAvatarColor.withOpacity(0.3),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(23),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.only(top: 15, bottom: 15),
                        itemCount: messages.length,
                        itemBuilder: (context, index) => _buildMessage(messages[index], index),
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                top: 5,
                left: 0,
                right: 0,
                child: Center(
                  child: Column(
                    children: [
                      Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                          border: Border.all(
                            color: _isRecording 
                                ? Colors.red 
                                : _isSending 
                                    ? Colors.blue 
                                    : _currentAvatarColor,
                            width: 3,
                          ),
                        ),
                        child: Stack(
                          children: [
                            ClipOval(
                              child: Image.asset(
                                _currentAvatarImage,
                                fit: BoxFit.cover,
                                width: 130,
                                height: 130,
                              ),
                            ),
                            if (_isRecording || _isSending)
                              Positioned.fill(
                                child: ClipOval(
                                  child: Lottie.network(
                                     'assets/loadingChat.json',
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        margin: EdgeInsets.only(top: 10),
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 5,
                              offset: Offset(0, 2),
                            ),
                          ],
                          border: Border.all(
                            color: _isRecording 
                                ? Colors.red.withOpacity(0.5) 
                                : _isSending 
                                    ? Colors.blue.withOpacity(0.5)
                                    : _currentAvatarColor.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                        child: _isRecording
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                LottieBuilder.network(
   'assets/loadingChat.json',
  onLoaded: (composition) {
    debugPrint("✅ Lottie loaded: ${composition.duration}");
  },
  errorBuilder: (context, error, stackTrace) {
    debugPrint("❌ Lottie load failed: $error");
    debugPrint("🧠 Stack trace: $stackTrace");
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.warning, size: 40, color: Colors.red),
        Text('Animation failed.', style: TextStyle(color: Colors.red)),
      ],
    );
  },
),

                                ],
                              )
                            : _isSending
                                ? Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                     LottieBuilder.network(
  'https://lottie.host/68b34055-5678-4629-996e-e97d3d801d2b/SY8CEFTaQe.json',
  onLoaded: (composition) {
    debugPrint("✅ Lottie loaded: ${composition.duration}");
  },
  errorBuilder: (context, error, stackTrace) {
    debugPrint("❌ Lottie load failed: $error");
    debugPrint("🧠 Stack trace: $stackTrace");
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.warning, size: 40, color: Colors.red),
        Text('Animation failed.', style: TextStyle(color: Colors.red)),
      ],
    );
  },
),

                                    ],
                                  )
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Image.asset(
                                        _currentAvatarImage,
                                        width: 24,
                                        height: 24,
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        "Let's have fun learning!",
                                        style: TextStyle(
                                          color: _currentAvatarColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          fontFamily: 'Comic Sans MS',
                                        ),
                                      ),
                                    ],
                                  ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.9),
                        Colors.white,
                      ],
                    ),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 16),
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(30),
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white,
                                Color(0xFFE8F5E9),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(
                              color: _isRecording
                                  ? Colors.red
                                  : _isTyping
                                      ? _currentAvatarColor
                                      : Colors.transparent,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                spreadRadius: 1,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              GestureDetector(
                                onLongPressStart: (_) => _startRecording(),
                                onLongPressEnd: (_) => _stopRecording(),
                                child: Container(
                                  width: 50,
                                  height: 50,
                                  margin: EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: _isRecording 
                                        ? Colors.red.withOpacity(0.1) 
                                        : _currentAvatarColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: AnimatedBuilder(
                                    animation: _animationController,
                                    builder: (context, child) {
                                      return Transform.scale(
                                        scale: _isRecording
                                            ? 1.0 + 0.2 * _microphoneScaleAnimation.value
                                            : 1.0,
                                        child: Icon(
                                          _isRecording ? Icons.stop : Icons.mic,
                                          color: _isRecording ? Colors.red : _currentAvatarColor,
                                          size: 28,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              Expanded(
                                child: TextField(
                                  controller: _controller,
                                  decoration: InputDecoration(
                                    hintText: _isRecording 
                                        ? 'Listening to you...' 
                                        : 'Type your message...',
                                    border: InputBorder.none,
                                    hintStyle: TextStyle(
                                      color: _isRecording 
                                          ? Colors.red.withOpacity(0.6) 
                                          : Colors.grey[600],
                                      fontFamily: 'Comic Sans MS',
                                      fontSize: 16,
                                    ),
                                    contentPadding: EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Comic Sans MS',
                                  ),
                                  maxLines: null,
                                  enabled: !_isRecording,
                                ),
                              ),
                              AnimatedContainer(
                                duration: Duration(milliseconds: 300),
                                width: 50,
                                height: 50,
                                decoration: BoxDecoration(
                                  color: _controller.text.isNotEmpty
                                      ? _currentAvatarColor
                                      : Color(0xFFE0E0E0),
                                  shape: BoxShape.circle,
                                ),
                                child: IconButton(
                                  icon: Icon(
                                    Icons.send_rounded,
                                    color: _controller.text.isNotEmpty
                                        ? Colors.white
                                        : Colors.grey[400],
                                  ),
                                  iconSize: 24,
                                  onPressed: () {
                                    if (_controller.text.isNotEmpty) {
                                      _sendMessage(_controller.text);
                                      _controller.clear();
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, -2),
            ),
          ],
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
          child: BottomNavBar(
            threadId: threadId,
            currentIndex: 2,
          ),
        ),
      ),
    );
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
}