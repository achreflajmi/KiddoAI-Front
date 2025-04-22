import 'package:flutter/material.dart';
import 'package:front_kiddoai/ui/profile_page.dart';
import 'package:front_kiddoai/utils/constants.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../widgets/bottom_nav_bar.dart';
import 'dart:ui' show ImageFilter;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';
import '../models/avatar_settings.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'WhiteboardScreen.dart';
import 'package:google_fonts/google_fonts.dart';


class Message {
  final String sender;
  final String content;
  final bool showAvatar;
  final bool isAudio;
  final bool isImage;
  final DateTime timestamp;

  Message({
    required this.sender,
    required this.content,
    this.showAvatar = false,
    this.isAudio = false,
    this.isImage = false,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'content': content,
      'showAvatar': showAvatar,
      'isAudio': isAudio,
      'isImage': isImage,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      sender: json['sender'],
      content: json['content'],
      showAvatar: json['showAvatar'] ?? false,
      isAudio: json['isAudio'] ?? false,
      isImage: json['isImage'] ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

class ChatPage extends StatefulWidget {
  final String threadId;
  const ChatPage({required this.threadId, super.key});

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _welcomeController;
  late String threadId;
  final TextEditingController _controller = TextEditingController();
  final List<Message> messages = [];
  final ScrollController _scrollController = ScrollController();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final ImagePicker _picker = ImagePicker();
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

  // Avatar settings (using English names for lookup, Arabic for display)
  final List<Map<String, dynamic>> _avatars = [
    {
      'name': 'SpongeBob',
      'displayName': 'سبونج بوب',
      'imagePath': 'assets/avatars/spongebob.png',
      'voicePath': 'assets/voices/SpongeBob.wav',
      'color': const Color(0xFFFFEB3B),
      'gradient': [const Color.fromARGB(255, 206, 190, 46), const Color(0xFFFFF9C4)],
    },
    {
      'name': 'Gumball',
      'displayName': 'غمبول',
      'imagePath': 'assets/avatars/gumball.png',
      'voicePath': 'assets/voices/gumball.wav',
      'color': const Color(0xFF2196F3),
      'gradient': [const Color.fromARGB(255, 48, 131, 198), const Color(0xFFE3F2FD)],
    },
    {
      'name': 'SpiderMan',
      'displayName': 'سبايدرمان',
      'imagePath': 'assets/avatars/spiderman.png',
      'voicePath': 'assets/voices/spiderman.wav',
      'color': const Color.fromARGB(255, 227, 11, 18),
      'gradient': [const Color.fromARGB(255, 203, 21, 39), const Color(0xFFFFEBEE)],
    },
    {
      'name': 'HelloKitty',
      'displayName': 'هيلو كيتي',
      'imagePath': 'assets/avatars/hellokitty.png',
      'voicePath': 'assets/voices/hellokitty.wav',
      'color': const Color(0xFFFF80AB),
      'gradient': [const Color.fromARGB(255, 255, 131, 174), const Color(0xFFFCE4EC)],
    },
  ];

  String _currentAvatarName = '';
  String _currentAvatarDisplayName = '';
  String _currentAvatarImage = '';
  String _currentVoicePath = '';
  Color _currentAvatarColor = Colors.green;
  List<Color> _currentAvatarGradient = [Colors.white, Colors.white];

   final TextStyle _arabicTextStyle = GoogleFonts.tajawal(
    // Line 116: fontSize: 18, // Increased minimum size
    fontSize: 18,
    // Line 117: height: 1.4,
    height: 1.4,
    // Line 118: color: Colors.black87,
    color: Colors.black87,
  );
  // Line 121: final TextStyle _arabicTextStyleUser = GoogleFonts.tajawal( // Use Tajawal
  final TextStyle _arabicTextStyleUser = GoogleFonts.tajawal(
    // Line 122: fontSize: 18, // Increased minimum size
    fontSize: 18,
    // Line 123: height: 1.4,
    height: 1.4,
    // Line 124: color: Colors.white, // User message text color
    color: Colors.white,
  );
  // Line 127: final TextStyle _hintTextStyle = GoogleFonts.tajawal( // Use Tajawal for hint
  final TextStyle _hintTextStyle = GoogleFonts.tajawal(
    // Line 128: fontSize: 16, // Readable size
    fontSize: 16,
    // Line 129: color: Colors.grey[500],
    color: Colors.grey[500],
  );
  // Line 132: final TextStyle _inputTextStyle = GoogleFonts.tajawal( // Use Tajawal for input
  final TextStyle _inputTextStyle = GoogleFonts.tajawal(
    // Line 133: fontSize: 16, // Readable size
    fontSize: 16,
    color: Colors.black87, // Added color for input text
  );
  // Line 136: final TextStyle _statusTextStyle = GoogleFonts.tajawal( // Use Tajawal for status
  final TextStyle _statusTextStyle = GoogleFonts.tajawal(
    // Line 137: fontWeight: FontWeight.bold,
    fontWeight: FontWeight.bold,
    // Line 138: fontSize: 16, // Readable size
    fontSize: 16,
  );
  // Line 140: final TextStyle _tutorialTitleStyle = GoogleFonts.tajawal( // Use Tajawal for tutorial title
  final TextStyle _tutorialTitleStyle = GoogleFonts.tajawal(
    // Line 141: fontWeight: FontWeight.bold,
    fontWeight: FontWeight.bold,
    // Line 142: color: Colors.yellowAccent,
    color: Colors.yellowAccent,
    // Line 143: fontSize: 20,
    fontSize: 20,
  );
  // Line 146: final TextStyle _tutorialDescStyle = GoogleFonts.tajawal( // Use Tajawal for tutorial description
  final TextStyle _tutorialDescStyle = GoogleFonts.tajawal(
    // Line 147: color: Colors.white,
    color: Colors.white,
    // Line 148: fontSize: 16,
    fontSize: 16,
    height: 1.4, // Added height for better readability
  );

  // Tutorial Setup Variables
  TutorialCoachMark? _tutorialCoachMark;
  List<TargetFocus> _targets = [];

  final GlobalKey _keyAvatarTop = GlobalKey();
  final GlobalKey _keyChatArea = GlobalKey();
  final GlobalKey _keyInputFieldContainer = GlobalKey();
  final GlobalKey _keyMicButton = GlobalKey();
  final GlobalKey _keySendButton = GlobalKey();
  final GlobalKey _keyProfileIcon = GlobalKey();
  final GlobalKey _keyWhiteboardButton = GlobalKey();
  final GlobalKey _keyCameraButton = GlobalKey();

  final String _tutorialPreferenceKey = 'chatPageTutorialShown';

  @override
  void initState() {
    super.initState();
    threadId = widget.threadId;
    if (threadId.isEmpty) {
      _getThreadId();
    }
    _loadMessages();
    _loadAvatarSettings();
    _initializeRecorder();

     _welcomeController = AnimationController(
  vsync: this,
  duration: const Duration(milliseconds: 900),
)..forward();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _microphoneScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _controller.addListener(() {
      if (mounted) {
        setState(() {
          _isTyping = _controller.text.isNotEmpty;
        });
      }
    });

    WidgetsBinding.instance.addObserver(this);
    _checkIfTutorialShouldBeShown();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _timer?.cancel();
    _recordingTimer?.cancel();
    _audioRecorder.closeRecorder();
    _animationController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose();
    _welcomeController.dispose();


    if (_tutorialCoachMark?.isShowing ?? false) {
      _tutorialCoachMark!.finish();
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    if (state == AppLifecycleState.paused && (_tutorialCoachMark?.isShowing ?? false)) {
      _tutorialCoachMark?.finish();
    }
  }

  Future<void> _loadAvatarSettings() async {
    try {
      final avatar = await AvatarSettings.getCurrentAvatar();
      final avatarName = avatar['name'] ?? 'SpongeBob';
      final selectedAvatar = _avatars.firstWhere(
        (a) => a['name'] == avatarName,
        orElse: () => _avatars[0],
      );
      if (mounted) {
        setState(() {
          _currentAvatarName = avatarName;
          _currentAvatarDisplayName = selectedAvatar['displayName'];
          _currentAvatarImage = avatar['imagePath'] ?? 'assets/avatars/spongebob.png';
          _currentVoicePath = avatar['voicePath'] ?? 'assets/voices/SpongeBob.wav';
          _currentAvatarColor = selectedAvatar['color'] as Color;
          _currentAvatarGradient = selectedAvatar['gradient'] as List<Color>;
        });
      }
    } catch (e) {
      print("Error loading avatar settings: $e");
      if (mounted) {
        setState(() {
          _currentAvatarName = 'SpongeBob';
          _currentAvatarDisplayName = 'سبونج بوب';
          _currentAvatarImage = 'assets/avatars/spongebob.png';
          _currentVoicePath = 'assets/voices/SpongeBob.wav';
          _currentAvatarColor = const Color(0xFFFFEB3B);
          _currentAvatarGradient = [const Color.fromARGB(255, 206, 190, 46), const Color(0xFFFFF9C4)];
        });
      }
    }
  }

  Future<void> _getThreadId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        threadId = prefs.getString('threadId') ?? '';
      });
    }
  }

  Future<void> _loadMessages() async {
    if (threadId.isEmpty) {
      await _getThreadId();
      if (threadId.isEmpty) return;
    }

    final prefs = await SharedPreferences.getInstance();
    final savedMessages = prefs.getString('chatMessages_$threadId');

    if (savedMessages != null) {
      try {
        final List<dynamic> decodedMessages = jsonDecode(savedMessages);
        if (mounted) {
          setState(() {
            messages.clear();
            messages.addAll(decodedMessages.map((msg) => Message.fromJson(msg)).toList());
          });
        }
      } catch (e) {
        print("Error decoding saved messages: $e");
        await prefs.remove('chatMessages_$threadId');
        if (mounted) {
          setState(() {
            messages.clear();
            messages.add(Message(sender: 'bot', content: 'مرحباً! كيف حالك اليوم؟', timestamp: DateTime.now()));
          });
        }
      }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && mounted) {
          _scrollToBottom();
        }
      });
    } else {
      if (mounted) {
        setState(() {
          if (messages.isEmpty) {
            messages.add(Message(
              sender: 'bot',
              content: 'مرحباً! كيف حالك اليوم؟',
              timestamp: DateTime.now(),
            ));
          }
        });
      }
    }
  }

  Future<void> _saveMessages() async {
    if (threadId.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    try {
      final encodedMessages = jsonEncode(messages.map((msg) => msg.toJson()).toList());
      await prefs.setString('chatMessages_$threadId', encodedMessages);
    } catch (e) {
      print("Error encoding messages for saving: $e");
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients && mounted) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

Future<void> _sendMessage(String content, {bool isImage = false, String source = 'text'}) async {
  final DateTime timestamp = DateTime.now();

  // Always show the image if it's from user
  if (isImage) {
    setState(() {
      messages.add(Message(sender: 'user', content: content, isImage: true, timestamp: timestamp));
      _isSending = true;
      messages.add(Message(sender: 'bot', content: 'typing_indicator', timestamp: DateTime.now()));
    });

    _saveMessages();
    _scrollToBottom();

    try {
      final response = await _sendImageToBackend(content, source);

      if (response != null && response['message'] != null) {
        final extractedMessage = response['message'].toString().trim();

        if (extractedMessage.isNotEmpty) {
          // 🔁 Trigger actual chat message (bot reply) using OCR message
          await _sendChatInput(extractedMessage);
        } else {
          _showBotError("لم أتمكن من فهم الكتابة. حاول مجددًا!");
        }
      } else {
        _showBotError("حدث خطأ أثناء تحليل الصورة.");
      }
    } catch (e) {
      _showBotError("فشل في إرسال الصورة: $e");
    }
  } else {
    setState(() {
      messages.add(Message(sender: 'user', content: content, timestamp: timestamp));
      _isSending = true;
      messages.add(Message(sender: 'bot', content: 'typing_indicator', timestamp: DateTime.now()));
    });

    _controller.clear();
    _saveMessages();
    _scrollToBottom();

    await _sendChatInput(content);
  }
}

Future<void> _sendChatInput(String userInput) async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    final response = await http.post(
      Uri.parse(CurrentIP + '/KiddoAI/chat/send'),
      headers: {
        "Content-Type": "application/json",
        if (accessToken != null) "Authorization": "Bearer $accessToken",
      },
      body: jsonEncode({'threadId': threadId, 'userInput': userInput}),
    );

    if (response.statusCode == 200) {
      final jsonResponse = jsonDecode(response.body);
      String botReply = jsonResponse['response'].toString().trim();

      setState(() {
        messages.removeWhere((m) => m.content == 'typing_indicator');
        messages.add(Message(sender: 'bot', content: botReply, timestamp: DateTime.now()));
        _isSending = false;
      });

      _saveMessages();
      _scrollToBottom();
      _initializeVoice(botReply);
    } else {
      _showBotError("لم أتمكن من الرد. حاول مرة أخرى!");
    }
  } catch (e) {
    _showBotError("خطأ في الاتصال: $e");
  }
}

void _showBotError(String errorMessage) {
  setState(() {
    _isSending = false;
    messages.removeWhere((m) => m.content == 'typing_indicator');
    messages.add(Message(sender: 'bot', content: errorMessage, timestamp: DateTime.now()));
  });
  _scrollToBottom();
  _saveMessages();
}



  Future<Map<String, dynamic>?> _sendImageToBackend(String imagePath, String source) async {
    try {
      final file = File(imagePath);
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://fbd2-102-30-245-171.ngrok-free.app/ocr'), // Replace with your backend URL
      );
      request.fields['source'] = source;
      request.files.add(await http.MultipartFile.fromPath('image', file.path));
      final response = await request.send();
      final responseData = await response.stream.bytesToString();
      return jsonDecode(responseData);
    } catch (e) {
      print('Error sending image to backend: $e');
      return null;
    }
  }

  Future<void> _initializeVoice(String text) async {
    try {
      final String effectiveVoicePath = _currentVoicePath.isNotEmpty ? _currentVoicePath : 'assets/voices/SpongeBob.wav';
      final String speakerWavFilename = effectiveVoicePath.split('/').last;

      const baseUrl = 'https://30d7-102-30-245-171.ngrok-free.app';
      final response = await http.post(
        Uri.parse('$baseUrl/initialize-voice'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "text": text,
          "speaker_wav": speakerWavFilename,
        }),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final requestId = data['request_id'] as String?;
        final totalParts = data['total_parts'] as int?;

        if (requestId == null || totalParts == null || totalParts <= 0) {
          throw Exception('Invalid response from /initialize-voice');
        }

        for (int currentPart = 1; currentPart <= totalParts; currentPart++) {
          String? audioUrl;
          int attempts = 0;
          while (audioUrl == null && attempts < 10 && mounted) {
            final statusResponse = await http.get(
              Uri.parse('$baseUrl/part-status/$requestId/$currentPart'),
            ).timeout(const Duration(seconds: 10));

            if (statusResponse.statusCode == 200) {
              final statusData = jsonDecode(statusResponse.body);
              if (statusData['status'] == 'done') {
                audioUrl = 'http://172.20.10.11:8001${statusData['audio_url']}';
                if (audioUrl == null || audioUrl.isEmpty) {
                  throw Exception('Audio URL is null or empty for part $currentPart');
                }
              } else {
                await Future.delayed(const Duration(seconds: 2));
              }
            } else {
              throw Exception('Error checking status for part $currentPart: ${statusResponse.statusCode}');
            }
            attempts++;
          }

          if (audioUrl != null && mounted) {
            await _audioPlayer.play(UrlSource(audioUrl));
            await _audioPlayer.onPlayerComplete.first;
          } else if (mounted) {
            throw Exception('Failed to get audio URL for part $currentPart after multiple attempts.');
          }
        }
      } else {
        print("Error initializing voice: ${response.statusCode} - ${response.body}");
      }
    } on TimeoutException catch (_) {
      print("Voice initialization/playback timed out.");
    } catch (e) {
      print("Error in voice initialization/playback: $e");
    }
  }

  Future<void> _initializeRecorder() async {
    try {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        throw RecordingPermissionException("Microphone permission not granted");
      }
      await _audioRecorder.openRecorder();
      _audioRecorder.setSubscriptionDuration(const Duration(milliseconds: 500));
    } catch (e) {
      print("Error initializing recorder: $e");
    }
  }

  Future<void> _requestPermissions() async {
    var microphoneStatus = await Permission.microphone.request();
    if (microphoneStatus.isDenied || microphoneStatus.isPermanentlyDenied) {
      print("Microphone permission denied.");
    }
  }

  Future<void> _startRecording() async {
    if (!_audioRecorder.isStopped) {
      print("Recorder is not stopped. Cannot start recording.");
      return;
    }
    await _requestPermissions();
    var status = await Permission.microphone.status;
    if (!status.isGranted) {
      print("Cannot record without microphone permission.");
      return;
    }

    try {
      Directory tempDir = await getTemporaryDirectory();
      String path = '${tempDir.path}/kiddoai_audio_${DateTime.now().millisecondsSinceEpoch}.wav';

      await _audioRecorder.startRecorder(
        toFile: path,
        codec: Codec.pcm16WAV,
      );

      if (mounted) {
        setState(() {
          _isRecording = true;
          _recordingSeconds = 0;
          _recordingDuration = "0:00";
        });
      }
      _animationController.repeat(reverse: true);

      _recordingTimer?.cancel();
      _recordingTimer = Timer.periodic(const Duration(milliseconds: 1000), (timer) {
        if (mounted) {
          setState(() {
            _recordingSeconds++;
            final minutes = (_recordingSeconds ~/ 60);
            final seconds = (_recordingSeconds % 60).toString().padLeft(2, '0');
            _recordingDuration = "$minutes:$seconds";
          });
        } else {
          timer.cancel();
        }
      });
    } catch (e) {
      print("Error starting recording: $e");
      if (mounted) {
        setState(() { _isRecording = false; });
      }
      _animationController.stop();
      _recordingTimer?.cancel();
    }
  }

  Future<void> _stopRecording() async {
    if (!_audioRecorder.isRecording) {
      print("Recorder is not recording. Cannot stop.");
      if (_isRecording && mounted) {
        setState(() { _isRecording = false; });
        _animationController.stop();
        _recordingTimer?.cancel();
      }
      return;
    }

    try {
      String? path = await _audioRecorder.stopRecorder();
      print("Stopped recording. File path: $path");

      if (mounted) {
        setState(() {
          _isRecording = false;
        });
      }
      _animationController.reset();
      _recordingTimer?.cancel();

      if (path == null) {
        print("Stopping recorder returned null path.");
        return;
      }

      final audioFile = File(path);
      if (!await audioFile.exists()) {
        print("Audio file does not exist at path: $path");
        return;
      }

      final audioBytes = await audioFile.readAsBytes();
      if (audioBytes.isEmpty) {
        print("Audio file is empty.");
        return;
      }

      if (mounted) setState(() => _isSending = true);

      final transcription = await _sendAudioToBackend(audioBytes);

      if (transcription != null && transcription.trim().isNotEmpty) {
        await _sendMessage(transcription);
      } else {
        print("Transcription failed or is empty.");
        if (mounted) {
          setState(() {
            messages.add(Message(sender: 'bot', content: "آسف، لم أسمع ذلك بوضوح.", timestamp: DateTime.now()));
            _isSending = false;
          });
          _scrollToBottom();
          _saveMessages();
        }
      }
    } catch (e) {
      print("Error stopping/processing recording: $e");
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isSending = false;
        });
      }
      _animationController.reset();
      _recordingTimer?.cancel();
    } finally {
      if (_isSending && mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  Future<String?> _sendAudioToBackend(List<int> audioBytes) async {
    final uri = Uri.parse(CurrentIP+'/KiddoAI/chat/transcribe');

    final request = http.MultipartRequest('POST', uri)
      ..fields['threadId'] = threadId
      ..files.add(http.MultipartFile.fromBytes('audio', audioBytes, filename: 'audio.wav'));

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    if (accessToken != null) {
      request.headers['Authorization'] = "Bearer $accessToken";
    }

    final response = await request.send();
    if (response.statusCode == 200) {
      return await response.stream.bytesToString();
    }
    return null;
  }

  Widget _buildMessage(Message message, int index) {
    final isUser = message.sender == 'user';
    final bool isBot = message.sender == 'bot';

    final bool showBotAvatar = isBot && (index == 0 || messages[index - 1].sender != 'bot');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Row(
          mainAxisAlignment: isUser ? MainAxisAlignment.start : MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (showBotAvatar) ...[
              GestureDetector(
                onTap: () => _initializeVoice(message.content),
                child: CircleAvatar(
                  backgroundImage: AssetImage(_currentAvatarImage),
                  radius: 18,
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (isBot && !showBotAvatar)
              const SizedBox(width: 18 * 2 + 8),
            Flexible(
              child: GestureDetector(
                onTap: isBot ? () => _initializeVoice(message.content) : null,
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isUser ? _currentAvatarColor : Colors.white,
                    border: isBot ? Border.all(color: _currentAvatarColor.withOpacity(0.5), width: 1.5) : null,
                    borderRadius: const BorderRadius.only(
                      topRight: Radius.circular(18),
                      topLeft: Radius.circular(18),
                      bottomRight: Radius.circular(4),
                      bottomLeft: Radius.circular(18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: message.content == 'typing_indicator'
                    ? Lottie.network(
                        'https://assets4.lottiefiles.com/packages/lf20_usmfx6bp.json', // Three dots typing animation
                        width: 50,
                        height: 30,
                        repeat: true,
                      )
                    : message.isImage
                        ? Image.file(
                            File(message.content),
                            height: 100,
                            fit: BoxFit.cover,
                          )
                        : Text(
                            message.content,
                            style: TextStyle(
                              color: isUser ? Colors.white : Colors.black87,
                              fontSize: 15.5,
                              height: 1.3,
                              fontFamily: 'Comic Sans MS',
                            ),
                            textDirection: TextDirection.rtl,
                          ),

                ),
              ),
            ),
          ].reversed.toList(),
        ),
      ),
    );
  }

  void _checkIfTutorialShouldBeShown() async {
    await Future.delayed(Duration.zero);
    if (!mounted) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    bool tutorialSeen = prefs.getBool(_tutorialPreferenceKey) ?? false;

    if (!tutorialSeen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Future.delayed(const Duration(milliseconds: 600), () {
          if (mounted) {
            _initTargets();
            if (_targets.isNotEmpty && _keyAvatarTop.currentContext != null) {
              _showTutorial();
            } else {
              print("Tutorial aborted: Targets could not be initialized.");
            }
          }
        });
      });
    }
  }

  void _initTargets() {
    _targets.clear();

    if (_keyAvatarTop.currentContext != null) {
      _targets.add(
        TargetFocus(
          identify: "avatarTop",
          keyTarget: _keyAvatarTop,
          alignSkip: Alignment.bottomLeft,
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: _buildTutorialContent(
                title: "صديقك!",
                description: "هذا صديقك الذكي! شاهد حالته هنا.",
              ),
            ),
          ],
          shape: ShapeLightFocus.RRect,
          radius: 20,
        ),
      );
    } else {
      print("Tutorial key context missing: _keyAvatarTop");
    }

    if (_keyChatArea.currentContext != null) {
      _targets.add(
        TargetFocus(
          identify: "chatArea",
          keyTarget: _keyChatArea,
          alignSkip: Alignment.topLeft,
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: _buildTutorialContent(
                title: "سجل الدردشة",
                description: "جميع رسائلك مع صديقك ستظهر هنا. مرر للأعلى لرؤية الدردشات القديمة!",
              ),
            ),
          ],
          shape: ShapeLightFocus.RRect,
          radius: 25,
        ),
      );
    } else {
      print("Tutorial key context missing: _keyChatArea");
    }

    if (_keyInputFieldContainer.currentContext != null) {
      _targets.add(
        TargetFocus(
          identify: "inputFieldContainer",
          keyTarget: _keyInputFieldContainer,
          alignSkip: Alignment.topLeft,
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: _buildTutorialContent(
                title: "تحدث هنا!",
                description: "اكتب رسالتك أو سؤالك في هذا الصندوق للدردشة.",
              ),
            ),
          ],
          shape: ShapeLightFocus.RRect,
          radius: 30,
        ),
      );
    } else {
      print("Tutorial key context missing: _keyInputFieldContainer");
    }

    if (_keyMicButton.currentContext != null) {
      _targets.add(
        TargetFocus(
          identify: "micButton",
          keyTarget: _keyMicButton,
          alignSkip: Alignment.topLeft,
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: _buildTutorialContent(
                title: "تحدث بصوتك!",
                description: "اضغط هذا الزر لتسجيل رسالتك الصوتية بدلاً من الكتابة!",
              ),
            ),
          ],
          shape: ShapeLightFocus.Circle,
        ),
      );
    } else {
      print("Tutorial key context missing: _keyMicButton");
    }

    if (_keyWhiteboardButton.currentContext != null) {
      _targets.add(
        TargetFocus(
          identify: "whiteboardButton",
          keyTarget: _keyWhiteboardButton,
          alignSkip: Alignment.topLeft,
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: _buildTutorialContent(
                title: "ارسم على السبورة!",
                description: "اضغط هنا لفتح السبورة البيضاء وارسم ما تريد!",
              ),
            ),
          ],
          shape: ShapeLightFocus.Circle,
        ),
      );
    } else {
      print("Tutorial key context missing: _keyWhiteboardButton");
    }

    if (_keyCameraButton.currentContext != null) {
      _targets.add(
        TargetFocus(
          identify: "cameraButton",
          keyTarget: _keyCameraButton,
          alignSkip: Alignment.topLeft,
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: _buildTutorialContent(
                title: "التقط صورة!",
                description: "اضغط هنا لالتقاط صورة باستخدام الكاميرا!",
              ),
            ),
          ],
          shape: ShapeLightFocus.Circle,
        ),
      );
    } else {
      print("Tutorial key context missing: _keyCameraButton");
    }

    if (_keySendButton.currentContext != null) {
      _targets.add(
        TargetFocus(
          identify: "sendButton",
          keyTarget: _keySendButton,
          alignSkip: Alignment.topRight,
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: _buildTutorialContent(
                title: "أرسل الرسالة!",
                description: "اضغط هنا لإرسال رسالتك المكتوبة إلى صديقك.",
              ),
            ),
          ],
          shape: ShapeLightFocus.Circle,
        ),
      );
    } else {
      print("Tutorial key context missing: _keySendButton");
    }

    if (_keyProfileIcon.currentContext != null) {
      _targets.add(
        TargetFocus(
          identify: "profileIcon",
          keyTarget: _keyProfileIcon,
          alignSkip: Alignment.bottomRight,
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: _buildTutorialContent(
                title: "ملفك الشخصي!",
                description: "تحقق من إعداداتك أو غيّر شخصيتك هنا.",
              ),
            ),
          ],
          shape: ShapeLightFocus.Circle,
        ),
      );
    } else {
      print("Tutorial key context missing: _keyProfileIcon");
    }
  }

  Widget _buildTutorialContent({required String title, required String description}) {
    final Color tutorialBackgroundColor = _currentAvatarColor.withOpacity(0.9);
    const Color titleColor = Colors.yellowAccent;
    const Color descriptionColor = Colors.white;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        margin: const EdgeInsets.only(bottom: 20.0, left: 20.0, right: 20.0),
        decoration: BoxDecoration(
          color: tutorialBackgroundColor,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              blurRadius: 8,
              offset: Offset(0, 4),
            )
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            Text(
              title,
              style: _tutorialTitleStyle,
            ),
            const SizedBox(height: 8.0),
            Text(
              description,
              style: _tutorialDescStyle,
            ),
          ],
        ),
      ),
    );
  }

  void _showTutorial() {
    if (_targets.isEmpty || !mounted) {
      print("Tutorial show aborted: Targets empty or widget not mounted.");
      return;
    }

    _tutorialCoachMark = TutorialCoachMark(
      targets: _targets,
      colorShadow: Colors.black.withOpacity(0.8),
      textSkip: "تخطى",
      paddingFocus: 5,
      opacityShadow: 0.8,
      imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      skipWidget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text(
          "تخطى الكل",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textDirection: TextDirection.rtl,
        ),
      ),
      onFinish: () {
        print("Chat Page Tutorial Finished");
        _markTutorialAsSeen();
      },
      onClickTarget: (target) {
        print('onClickTarget: ${target.identify}');
      },
      onClickTargetWithTapPosition: (target, tapDetails) {
        print("target: ${target.identify}");
        print("clicked at position local: ${tapDetails.localPosition} - global: ${tapDetails.globalPosition}");
      },
      onClickOverlay: (target) {
        print('onClickOverlay: ${target.identify}');
      },
      onSkip: () {
        print("Chat Page Tutorial Skipped");
        _markTutorialAsSeen();
        return true;
      },
    )..show(context: context);
  }

  void _markTutorialAsSeen() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_tutorialPreferenceKey, true);
    print("Marked '$_tutorialPreferenceKey' as seen.");
  }

  @override
  Widget build(BuildContext context) {
    if (threadId.isEmpty || _currentAvatarImage.isEmpty) {
      return Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          body: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _currentAvatarGradient.isNotEmpty ? _currentAvatarGradient : [Colors.blue.shade100, Colors.blue.shade300],
              ),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  LottieBuilder.network(
                    'https://assets9.lottiefiles.com/packages/lf20_kkhbsucc.json',
                    height: 180,
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      "جارٍ تحميل دردشتك السحرية...",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _currentAvatarColor,
                        fontFamily: 'Comic Sans MS',
                      ),
                      textDirection: TextDirection.rtl,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _currentAvatarGradient.last,
          extendBodyBehindAppBar: true,

                  appBar: PreferredSize(
                    preferredSize: const Size.fromHeight(70),
                    child: AppBar(
                      backgroundColor: _currentAvatarColor,
                      elevation: 0,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(30),
                        ),
                      ),
                      centerTitle: true,
                      title: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Image.asset(
                            'assets/logo.png',
                            height: 50,
                          ),
                          AnimatedBuilder(
                            animation: _welcomeController,
                            builder: (context, child) {
                              return ClipRect(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: _welcomeController.value,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 10),
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          fontSize: 26,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: 'Comic Sans MS',
                                        ),
                                        children: [
                                          const TextSpan(text: 'K', style: TextStyle(color: Colors.white)),
                                          TextSpan(text: 'iddo ', style: TextStyle(color: Colors.white.withOpacity(0.85))),
                                          const TextSpan(text: 'A', style: TextStyle(color: Colors.yellow)),
                                          TextSpan(text: 'I', style: TextStyle(color: Colors.yellow.withOpacity(0.85))),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),

                        ],
                      ),
                      actions: [
                        Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: GestureDetector(
                            key: _keyProfileIcon,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ProfilePage(threadId: widget.threadId)),
                            ).then((_) => _loadAvatarSettings()),
                            child: Hero(
                              tag: 'profile_avatar',
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 3),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  backgroundImage: AssetImage(_currentAvatarImage),
                                  radius: 22,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
        body: SafeArea(
           top: false,
          child: Container(
                padding: const EdgeInsets.only(top: 90), // height of your AppBar
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _currentAvatarGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 15.0),
                      child: Column(
                        key: _keyAvatarTop,
                        children: [
                          Container(
                            width: 130,
                            height: 130,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
                              ],
                              border: Border.all(
                                color: _isRecording ? Colors.red : _isSending ? Colors.blue : _currentAvatarColor,
                                width: 3,
                              ),
                            ),
                            child: Stack(
                              alignment: Alignment.center,
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
                                        'https://assets1.lottiefiles.com/packages/lf20_vctzcozn.json',
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Container(
                            margin: const EdgeInsets.only(top: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.9),
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: const Offset(0, 2)),
                              ],
                              border: Border.all(
                                color: (_isRecording ? Colors.red : _isSending ? Colors.blue : _currentAvatarColor).withOpacity(0.5),
                                width: 2,
                              ),
                            ),
                            child: _buildStatusText(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      child: Container(
                        key: _keyChatArea,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(color: _currentAvatarColor.withOpacity(0.3), width: 2),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(23),
                          child: ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            itemCount: messages.length,
                            itemBuilder: (context, index) => _buildMessage(messages[index], index),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      key: _keyInputFieldContainer,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.white.withOpacity(0.0),
                            Colors.white.withOpacity(0.9),
                            Colors.white,
                          ],
                          stops: const [0.0, 0.3, 1.0],
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                        child: Material(
                          elevation: 5,
                          borderRadius: BorderRadius.circular(30),
                          shadowColor: Colors.black.withOpacity(0.2),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: _isRecording
                                    ? Colors.redAccent
                                    : _isTyping
                                        ? _currentAvatarColor
                                        : Colors.grey.shade300,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              children: [
                               
                                Container(
                                  width: 48,
                                  height: 48,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: _currentAvatarColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    key: _keyCameraButton,
                                    icon: Icon(
                                      Icons.camera_alt,
                                      color: _currentAvatarColor,
                                      size: 26,
                                    ),
                                    onPressed: () async {
                                      final XFile? photo = await _picker.pickImage(
                                        source: ImageSource.camera,
                                        imageQuality: 100,
                                      );
                                      if (photo != null) {
                                        _sendMessage(photo.path, isImage: true, source: 'camera');
                                      }
                                    },
                                  ),
                                ),
                                Container(
                                  width: 48,
                                  height: 48,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: _currentAvatarColor.withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    key: _keyWhiteboardButton,
                                    icon: Icon(
                                      Icons.brush,
                                      color: _currentAvatarColor,
                                      size: 26,
                                    ),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => WhiteboardScreen(
                                            onImageSaved: (imagePath) {
                                              _sendMessage(imagePath, isImage: true, source: 'whiteboard');
                                            },
                                            avatarImagePath: _currentAvatarImage,
                                            avatarColor: _currentAvatarColor,
                                            avatarGradient: _currentAvatarGradient,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                 GestureDetector(
                                  key: _keyMicButton,
                                  onLongPressStart: (_) => _startRecording(),
                                  onLongPressEnd: (_) => _stopRecording(),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    margin: const EdgeInsets.only(left: 8),
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
                                          scale: _isRecording ? _microphoneScaleAnimation.value : 1.0,
                                          child: Icon(
                                            _isRecording ? Icons.stop_rounded : Icons.mic_rounded,
                                            color: _isRecording ? Colors.redAccent : _currentAvatarColor,
                                            size: 26,
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
                                      hintText: _isRecording ? 'أستمع...' : 'اكتب أو سجل!',
                                      border: InputBorder.none,
                                       hintStyle: _hintTextStyle,
                                      contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                                    ),
                                    style: _inputTextStyle,
                                    maxLines: null,
                                    textInputAction: TextInputAction.send,
                                    onSubmitted: (text) {
                                      if (text.isNotEmpty) {
                                        _sendMessage(text);
                                      }
                                    },
                                    enabled: !_isRecording,
                                    textDirection: TextDirection.rtl,
                                  ),
                                ),
                               
                                 AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  key: _keySendButton,
                                  width: 48,
                                  height: 48,
                                  margin: const EdgeInsets.only(right: 8),
                                  decoration: BoxDecoration(
                                    color: _isTyping ? _currentAvatarColor : Colors.grey.shade300,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.send_rounded,
                                      color: _isTyping ? Colors.white : Colors.grey.shade500,
                                    ),
                                    iconSize: 24,
                                    tooltip: "أرسل الرسالة",
                                    onPressed: _isTyping ? () => _sendMessage(_controller.text) : null,
                                  ),
                                ),
                              ].reversed.toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, -2)),
            ],
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
            child: BottomNavBar(
              threadId: threadId,
              currentIndex: 2,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusText() {
    Widget statusContent;
    Color statusColor;
    String lottieUrl = '';

    if (_isRecording) {
      statusColor = Colors.redAccent;
      lottieUrl = 'https://assets3.lottiefiles.com/packages/lf20_tzjnbj0d.json';
      statusContent = Text(
        "أنا أستمع... $_recordingDuration",
        style: _statusTextStyle.copyWith(color: statusColor),
        textDirection: TextDirection.rtl,
      );
    } else if (_isSending) {
      statusColor = Colors.blueAccent;
      lottieUrl = 'https://assets9.lottiefiles.com/packages/lf20_nw19osms.json';
      statusContent = Text(
        "همم، دعني أفكر...",
        style: _statusTextStyle.copyWith(color: statusColor),
        textDirection: TextDirection.rtl,
      );
    } else {
      statusColor = _currentAvatarColor;
      statusContent = Text(
        "اسألني أي شيء!",
        style:_statusTextStyle.copyWith(color: statusColor),
        textDirection: TextDirection.rtl,
      );
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
  statusContent,
],

      ),
    );
  }
}