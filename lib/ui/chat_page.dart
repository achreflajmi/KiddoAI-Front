import 'package:flutter/material.dart';
import 'package:front_kiddoai/ui/profile_page.dart';
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
// Line 34: import 'package:google_fonts/google_fonts.dart'; // Import GoogleFonts
import 'package:google_fonts/google_fonts.dart';

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

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin, WidgetsBindingObserver {
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
      'name': 'سبونج بوب', // Translated: SpongeBob
      'imagePath': 'assets/avatars/spongebob.png',
      'voicePath': 'assets/voices/SpongeBob.wav',
      'color': Color(0xFFFFEB3B),
      'gradient': [Color.fromARGB(255, 206, 190, 46), Color(0xFFFFF9C4)],
    },
    {
      'name': 'غمبول', // Translated: Gumball
      'imagePath': 'assets/avatars/gumball.png',
      'voicePath': 'assets/voices/gumball.wav',
      'color': Color(0xFF2196F3),
      'gradient': [Color.fromARGB(255, 48, 131, 198), Color(0xFFE3F2FD)],
    },
    {
      'name': 'سبايدرمان', // Translated: SpiderMan
      'imagePath': 'assets/avatars/spiderman.png',
      'voicePath': 'assets/voices/spiderman.wav',
      'color': Color.fromARGB(255, 227, 11, 18),
      'gradient': [Color.fromARGB(255, 203, 21, 39), Color(0xFFFFEBEE)],
    },
    {
      'name': 'هيلو كيتي', // Translated: HelloKitty
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

  // Define Text Styles using GoogleFonts.tajawal
  // Line 115: final TextStyle _arabicTextStyle = GoogleFonts.tajawal( // Use Tajawal
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
    final avatar = await AvatarSettings.getCurrentAvatar();
    if (mounted) {
      setState(() {
        _currentAvatarName = avatar['name'] ?? 'سبونج بوب';
        _currentAvatarImage = avatar['imagePath'] ?? 'assets/avatars/spongebob.png';
        _currentVoicePath = avatar['voicePath'] ?? 'assets/voices/SpongeBob.wav';
        final selectedAvatar = _avatars.firstWhere(
          (a) => a['name'] == _currentAvatarName,
          orElse: () => _avatars[0],
        );
        _currentAvatarColor = selectedAvatar['color'];
        _currentAvatarGradient = selectedAvatar['gradient'];
      });
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
        // Line 231: // Remove focus from text field when scrolling
        // Line 232: FocusScope.of(context).unfocus(); // Moved this logic to _scrollToBottom
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
      // Line 219: // Filter out temporary typing indicators before saving
      // Line 220: final messagesToSave = messages.where((m) => m.content != 'typing_indicator').toList();
      final messagesToSave = messages.where((m) => m.content != 'typing_indicator').toList();
      // Line 222: jsonEncode(messagesToSave.map((msg) => msg.toJson()).toList());
      final encodedMessages = jsonEncode(messagesToSave.map((msg) => msg.toJson()).toList());
      await prefs.setString('chatMessages_$threadId', encodedMessages);
    } catch (e) {
      print("Error encoding messages for saving: $e");
    }
  }

  void _scrollToBottom() {
    // Line 231: // Remove focus from text field when scrolling
    // Line 232: FocusScope.of(context).unfocus();
    if (mounted) FocusScope.of(context).unfocus(); // Unfocus here
    if (_scrollController.hasClients && mounted) {
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
      // Line 250: // Remove previous typing indicator if any
      // Line 251: messages.removeWhere((m) => m.content == 'typing_indicator');
      messages.removeWhere((m) => m.content == 'typing_indicator');
      // Line 255: // Add the visual typing indicator message
      // Line 256: messages.add(Message(sender: 'bot', content: 'typing_indicator', timestamp: DateTime.now()));
      messages.add(Message(sender: 'bot', content: 'typing_indicator', timestamp: DateTime.now()));
    });

    _controller.clear(); // Clear input after sending
    // Line 259: _saveMessages(); // Save user message immediately
    _saveMessages();
    Future.delayed(Duration(milliseconds: 100), () => _scrollToBottom());

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken');

      final response = await http.post(
        Uri.parse('https://e59e-41-230-204-2.ngrok-free.app/KiddoAI/chat/send'),
        headers: {
          "Content-Type": "application/json",
          if (accessToken != null) "Authorization": "Bearer $accessToken",
        },
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
          // Line 289: // Remove the typing indicator message
          // Line 290: messages.removeWhere((m) => m.content == 'typing_indicator');
          messages.removeWhere((m) => m.content == 'typing_indicator');
          messages.add(Message(sender: 'bot', content: botResponse, timestamp: DateTime.now()));
          _isSending = false;
        });

        // Line 294: _saveMessages(); // Save bot response
        _saveMessages();
        _scrollToBottom();
        _initializeVoice(botResponse);
      } else {
        setState(() {
          // Line 298: _isSending = false;
          _isSending = false;
          // Line 299: // Remove the typing indicator message
          // Line 300: messages.removeWhere((m) => m.content == 'typing_indicator');
          messages.removeWhere((m) => m.content == 'typing_indicator');
          // Line 301: messages.add(Message(sender: 'bot', content: "عفوًا! حاول مرة أخرى!", timestamp: DateTime.now()));
          messages.add(Message(sender: 'bot', content: "عفوًا! حاول مرة أخرى!", timestamp: DateTime.now()));
        });
         // Line 303: _saveMessages(); // Save error message
         _saveMessages();
      }
    } catch (e) {
      setState(() {
        _isSending = false;
        // Line 308: // Remove the typing indicator message
        // Line 309: messages.removeWhere((m) => m.content == 'typing_indicator');
        messages.removeWhere((m) => m.content == 'typing_indicator');
        // Line 310: messages.add(Message(sender: 'bot', content: "خطأ في الاتصال!", timestamp: DateTime.now()));
        messages.add(Message(sender: 'bot', content: "خطأ في الاتصال!", timestamp: DateTime.now()));
      });
       // Line 312: _saveMessages(); // Save connection error message
       _saveMessages();
    }
  }

  Future<void> _initializeVoice(String text) async {
    try {
      final String effectiveVoicePath = _currentVoicePath.isNotEmpty ? _currentVoicePath : 'assets/voices/SpongeBob.wav';
      final String speakerWavFilename = effectiveVoicePath.split('/').last;

      final baseUrl = 'http://192.168.1.22:8000';
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
                audioUrl = 'http://192.168.1.22:8000${statusData['audio_url']}';
                if (audioUrl == null || audioUrl.isEmpty) {
                  throw Exception('Audio URL is null or empty for part $currentPart');
                }
              } else {
                await Future.delayed(Duration(seconds: 2));
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
      _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
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

      if (mounted) {
        // Line 417: if (mounted) {
        setState(() {
          // Line 418: setState(() {
          // Line 419: _isSending = true; // For status text
          _isSending = true;
          // Line 420: // Add visual typing indicator message
          // Line 421: messages.add(Message(sender: 'bot', content: 'typing_indicator', timestamp: DateTime.now()));
          messages.add(Message(sender: 'bot', content: 'typing_indicator', timestamp: DateTime.now()));
        });
         // Line 423: Future.delayed(Duration(milliseconds: 100), _scrollToBottom);
         Future.delayed(Duration(milliseconds: 100), _scrollToBottom);
      }

      final transcription = await _sendAudioToBackend(audioBytes);

       // Line 428: // Remove thinking indicator before processing response
       if (mounted) {
         // Line 429: if (mounted) {
         setState(() {
           // Line 430: setState(() {
           // Line 431: messages.removeWhere((m) => m.content == 'typing_indicator');
           messages.removeWhere((m) => m.content == 'typing_indicator');
         });
       }

      if (transcription != null && transcription.trim().isNotEmpty) {
        await _sendMessage(transcription);
      } else {
        print("Transcription failed or is empty.");
        if (mounted) {
          setState(() {
            messages.add(Message(sender: 'bot', content: "آسف، لم أسمع ذلك بوضوح.", timestamp: DateTime.now()));
            // Line 440: _isSending = false; // Reset sending status
            _isSending = false;
          });
          _scrollToBottom();
          // Line 443: _saveMessages(); // Save the apology message
          _saveMessages();
        }
      }
    } catch (e) {
      print("Error stopping/processing recording: $e");
      if (mounted) {
        setState(() {
          _isRecording = false;
          _isSending = false;
          // Line 450: // Remove typing indicator on error
          // Line 451: messages.removeWhere((m) => m.content == 'typing_indicator');
          messages.removeWhere((m) => m.content == 'typing_indicator');
        });
      }
      _animationController.reset();
      _recordingTimer?.cancel();
    } finally {
       // This might run before async _sendMessage completes, ensure _isSending is handled there too.
      // if (_isSending && mounted) {
      //   setState(() => _isSending = false);
      // }
    }
  }

  Future<String?> _sendAudioToBackend(List<int> audioBytes) async {
    final uri = Uri.parse('https://e59e-41-230-204-2.ngrok-free.app/KiddoAI/chat/transcribe');

    final request = http.MultipartRequest('POST', uri)
      ..fields['threadId'] = threadId
      ..files.add(http.MultipartFile.fromBytes('audio', audioBytes, filename: 'audio.wav'));

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');
    if (accessToken != null) {
      request.headers['Authorization'] = "Bearer $accessToken";
    }

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        // Line 483: // Decode the JSON response and extract the transcription
        // Line 484: final decodedResponse = jsonDecode(responseBody);
        // Line 485: return decodedResponse['transcription'] as String?;
        final decodedResponse = jsonDecode(responseBody);
        return decodedResponse['transcription'] as String?;
      } else {
        // Line 487: print("Transcription request failed with status: ${response.statusCode}");
        print("Transcription request failed with status: ${response.statusCode}");
        // Line 488: print("Response body: ${await response.stream.bytesToString()}"); // Log error response
        print("Response body: $responseBody"); // Log error response
        return null;
      }
    } catch (e) {
      print("Error sending audio to backend: $e");
      return null;
    }
  }

  // Line 496: // Updated _buildMessage to handle typing indicator and add InkWell
  Widget _buildMessage(Message message, int index) {
    final isUser = message.sender == 'user';
    final bool isBot = message.sender == 'bot';
    // Line 499: final isTypingIndicator = message.content == 'typing_indicator';
    final isTypingIndicator = message.content == 'typing_indicator';

    // Line 501: final bool showBotAvatar = isBot && !isTypingIndicator && (index == 0 || messages[index - 1].sender != 'bot' || messages[index - 1].content == 'typing_indicator');
    final bool showBotAvatar = isBot && !isTypingIndicator && (index == 0 || messages[index - 1].sender != 'bot' || messages[index - 1].content == 'typing_indicator');

    // Line 504: return Align(
    return Align(
      // Line 505: alignment: isUser ? Alignment.centerLeft : Alignment.centerRight, // Reversed for RTL
      alignment: isUser ? Alignment.centerLeft : Alignment.centerRight,
      child: Padding(
        // Line 507: padding: EdgeInsets.only(
        padding: EdgeInsets.only(
          // Line 508: left: isUser ? 12 : 50, // More padding on the opposite side
          left: isUser ? 12 : 50,
          // Line 509: right: isUser ? 50 : 12, // More padding on the opposite side
          right: isUser ? 50 : 12,
          // Line 510: top: 4,
          top: 4,
          // Line 511: bottom: 4,
          bottom: 4,
        ),
        child: Row(
          // Line 514: mainAxisSize: MainAxisSize.min, // Row takes minimum space needed
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Line 518: // Bot Avatar (shown only when needed and not typing indicator)
            if (showBotAvatar) ...[
              // Line 520: InkWell( // Added InkWell for ripple
              InkWell(
                // Line 521: onTap: () => _initializeVoice(message.content),
                onTap: () => _initializeVoice(message.content),
                // Line 522: customBorder: CircleBorder(),
                customBorder: CircleBorder(),
                // Line 523: child: CircleAvatar(
                child: CircleAvatar(
                  // Line 524: backgroundImage: AssetImage(_currentAvatarImage),
                  backgroundImage: AssetImage(_currentAvatarImage),
                  // Line 525: radius: 20, // Slightly larger avatar
                  radius: 20,
                ),
              ),
              SizedBox(width: 10),
            ],
            // Line 529: // Message Bubble or Typing Indicator
            Flexible(
              // Line 531: child: Material( // Use Material for InkWell effect on container
              child: Material(
                // Line 532: color: Colors.transparent, // Make Material transparent
                color: Colors.transparent,
                borderRadius: BorderRadius.only( // Match container border radius for clipping InkWell
                    topRight: const Radius.circular(22),
                    topLeft: const Radius.circular(22),
                    bottomRight: isUser ? const Radius.circular(22) : const Radius.circular(6),
                    bottomLeft: isUser ? const Radius.circular(6) : const Radius.circular(22),
                  ),
                clipBehavior: Clip.antiAlias, // Clip the InkWell effect
                // Line 533: child: InkWell(
                child: InkWell(
                  // Line 534: onTap: isBot && !isTypingIndicator ? () => _initializeVoice(message.content) : null,
                  onTap: isBot && !isTypingIndicator ? () => _initializeVoice(message.content) : null,
                  // Line 535: borderRadius: BorderRadius.only( ... ), // Applied to Material instead
                  // Line 540: splashColor: _currentAvatarColor.withOpacity(0.3), // Custom splash color
                  splashColor: _currentAvatarColor.withOpacity(0.3),
                  // Line 541: highlightColor: _currentAvatarColor.withOpacity(0.1), // Custom highlight color
                  highlightColor: _currentAvatarColor.withOpacity(0.1),
                  // Line 542: child: Container(
                  child: Container(
                    // Line 543: padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10), // Adjusted padding
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      // Line 545: color: isTypingIndicator
                      color: isTypingIndicator
                      // Line 546: ? Colors.grey.shade200 // Different background for typing
                          ? Colors.grey.shade200
                      // Line 547: : isUser ? _currentAvatarColor : Colors.white,
                          : isUser ? _currentAvatarColor : Colors.white,
                      // Line 548: border: isBot && !isTypingIndicator
                      border: isBot && !isTypingIndicator
                          ? Border.all(color: _currentAvatarColor.withOpacity(0.4), width: 1.0)
                          : null,
                      borderRadius: BorderRadius.only(
                        topRight: const Radius.circular(22),
                        topLeft: const Radius.circular(22),
                        bottomRight: isUser ? const Radius.circular(22) : const Radius.circular(6),
                        bottomLeft: isUser ? const Radius.circular(6) : const Radius.circular(22),
                      ),
                       boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          spreadRadius: 1,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    // Line 566: child: isTypingIndicator
                    child: isTypingIndicator
                        // Line 567: ? Lottie.asset( // Use a Lottie animation for typing
                        ? Lottie.asset(
                            // Line 568: 'assets/lottie/typing_dots.json', // Replace with your Lottie asset path
                            'assets/lottie/typing_dots.json', // Ensure this asset exists
                            // Line 569: width: 50,
                            width: 50,
                            // Line 570: height: 20, // Adjust size as needed
                            height: 20,
                            // Line 571: fit: BoxFit.contain,
                            fit: BoxFit.contain,
                          )
                        // Line 573: : Text(
                        : Text(
                            // Line 574: message.content,
                            message.content,
                            // Line 575: style: isUser ? _arabicTextStyleUser : _arabicTextStyle, // Use defined styles
                            style: isUser ? _arabicTextStyleUser : _arabicTextStyle,
                            // Line 576: textDirection: TextDirection.rtl, // Explicit RTL for text
                            textDirection: TextDirection.rtl,
                          ),
                  ),
                ),
              ),
            ),
            // Placeholder for user side alignment
            if (isUser) SizedBox(width: 20 * 2 + 10), // Placeholder to balance avatar width+spacing
          // Line 588: ].reversed.toList(), // Ensure Row children are reversed for RTL layout
          ].reversed.toList(),
        ),
      ),
    );
  }


  // Tutorial Functions
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
               _markTutorialAsSeen(); // Avoid getting stuck
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
          alignSkip: Alignment.bottomLeft, // Adjusted for RTL
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: _buildTutorialContent(
                title: "صديقك!", // Translated: Your Buddy!
                description: "هذا صديقك الذكي! شاهد حالته هنا.", // Translated
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
          alignSkip: Alignment.topLeft, // Adjusted for RTL
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: _buildTutorialContent(
                title: "سجل الدردشة", // Translated: Chat History
                description: "جميع رسائلك مع صديقك ستظهر هنا. مرر للأعلى لرؤية الدردشات القديمة!", // Translated
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
          alignSkip: Alignment.topLeft, // Adjusted for RTL
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: _buildTutorialContent(
                title: "تحدث هنا!", // Translated: Talk Here!
                description: "اكتب رسالتك أو سؤالك في هذا الصندوق للدردشة.", // Translated
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
          alignSkip: Alignment.topLeft, // Adjusted for RTL
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: _buildTutorialContent(
                title: "تحدث بصوتك!", // Translated: Speak Up!
                // Line 644: description: "اضغط مطولاً هنا لتسجيل رسالتك الصوتية بدلاً من الكتابة!", // Adjusted instruction
                description: "اضغط مطولاً هنا لتسجيل رسالتك الصوتية بدلاً من الكتابة!",
              ),
            ),
          ],
          shape: ShapeLightFocus.Circle,
        ),
      );
    } else {
      print("Tutorial key context missing: _keyMicButton");
    }

    if (_keySendButton.currentContext != null) {
      _targets.add(
        TargetFocus(
          identify: "sendButton",
          keyTarget: _keySendButton,
          alignSkip: Alignment.topRight, // Adjusted for RTL
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.top,
              child: _buildTutorialContent(
                title: "أرسل الرسالة!", // Translated: Send Message!
                description: "اضغط هنا لإرسال رسالتك المكتوبة إلى صديقك.", // Translated
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
          alignSkip: Alignment.bottomRight, // Adjusted for RTL
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: _buildTutorialContent(
                title: "ملفك الشخصي!", // Translated: Your Profile!
                description: "تحقق من إعداداتك أو غيّر شخصيتك هنا.", // Translated
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
    // Removed local titleColor and descriptionColor as they are defined in the styles

    return Directionality(
      textDirection: TextDirection.rtl, // Added for RTL
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
          crossAxisAlignment: CrossAxisAlignment.end, // Adjusted for RTL
          children: <Widget>[
            Text(
              // Line 700: title,
              title,
              // Line 701: style: _tutorialTitleStyle, // Use defined style
              style: _tutorialTitleStyle,
              // Line 702: textAlign: TextAlign.right, // Ensure text aligns right
              textAlign: TextAlign.right,
            ),
            const SizedBox(height: 8.0),
            Text(
              // Line 705: description,
              description,
              // Line 706: style: _tutorialDescStyle, // Use defined style
              style: _tutorialDescStyle,
              // Line 707: textAlign: TextAlign.right, // Ensure text aligns right
              textAlign: TextAlign.right,
            ),
          ],
        ),
      ),
    );
  }


  void _showTutorial() {
    if (_targets.isEmpty || !mounted) {
      print("Tutorial show aborted: Targets empty or widget not mounted.");
      _markTutorialAsSeen(); // Mark as seen if it can't be shown
      return;
    }

    _tutorialCoachMark = TutorialCoachMark(
      targets: _targets,
      colorShadow: Colors.black.withOpacity(0.8),
      textSkip: "تخطى", // Translated: SKIP
      paddingFocus: 5,
      opacityShadow: 0.8,
      imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      skipWidget: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(20),
        ),
        // Line 726: child: Text( // Use Text widget directly for skip button
        child: Text(
          "تخطى الكل", // Translated: Skip All
          // Line 728: style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold), // Use Tajawal
          style: GoogleFonts.tajawal(color: Colors.white, fontWeight: FontWeight.bold),
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
        // Line 745: return true; // Return true to indicate skip was handled
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
        textDirection: TextDirection.rtl, // Added for RTL
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
                  // Line 765: Lottie.network( // Changed Lottie source
                  Lottie.network(
                    'https://assets6.lottiefiles.com/packages/lf20_p8bfn5to.json', // Thinking/loading animation
                    height: 180,
                  ),
                  SizedBox(height: 24),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      "جارٍ تحميل دردشتك السحرية...", // Translated: Loading your magical chat...
                      // Line 778: style: GoogleFonts.tajawal( // Use Tajawal
                      style: GoogleFonts.tajawal(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: _currentAvatarColor,
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
      textDirection: TextDirection.rtl, // Added for RTL
      // Line 789: backgroundColor: _currentAvatarGradient.last,
      child: Scaffold(
        backgroundColor: _currentAvatarGradient.last,
        // Line 791: preferredSize: Size.fromHeight(70), // Increased height slightly
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(70),
          child: AppBar(
            // Line 793: backgroundColor: Colors.transparent, // Make AppBar transparent
            backgroundColor: Colors.transparent,
            // Line 794: elevation: 0, // Remove shadow
            elevation: 0,
            centerTitle: true,
            // Line 795: flexibleSpace: Container( // Apply gradient to AppBar background
            flexibleSpace: Container(
              decoration: BoxDecoration(
                // Line 797: gradient: LinearGradient(
                gradient: LinearGradient(
                  // Line 798: colors: [_currentAvatarGradient.first.withOpacity(0.8), _currentAvatarGradient.first],
                  colors: _currentAvatarGradient.isNotEmpty
                    ? [_currentAvatarGradient.first.withOpacity(0.8), _currentAvatarGradient.first]
                    : [Colors.blue.shade300, Colors.blue], // Fallback gradient
                  // Line 799: begin: Alignment.topCenter,
                  begin: Alignment.topCenter,
                  // Line 800: end: Alignment.bottomCenter,
                  end: Alignment.bottomCenter,
                ),
                // Line 802: borderRadius: BorderRadius.only(
                borderRadius: BorderRadius.only(
                  // Line 803: bottomLeft: Radius.circular(30), // More rounded corners
                  bottomLeft: Radius.circular(30),
                  // Line 804: bottomRight: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
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
                 // Line 820: // Using GoogleFonts for the logo title
                 // Line 821: RichText(
                 RichText(
                   text: TextSpan(
                     // Line 823: style: GoogleFonts.fredokaOne( // Playful font for logo
                     style: GoogleFonts.fredoka(
                       // Line 824: fontSize: 26, // Slightly larger logo font
                       fontSize: 26,
                       fontWeight: FontWeight.bold,
                       color: Colors.white, // Base color
                     ),
                     children: [
                       // Line 827: TextSpan(text: 'K', style: TextStyle(color: Colors.yellow.shade600)),
                       TextSpan(text: 'K', style: TextStyle(color: Colors.yellow.shade600)),
                       TextSpan(text: 'iddo', style: TextStyle(color: Colors.white)),
                       // Line 830: TextSpan(text: 'A', style: TextStyle(color: Colors.yellow.shade600)),
                       TextSpan(text: 'A', style: TextStyle(color: Colors.yellow.shade600)),
                       TextSpan(text: 'i', style: TextStyle(color: Colors.white)),
                     ],
                   ),
                 ),
              ].reversed.toList(), // Reversed for RTL
            ),
            actions: [
              Padding(
                padding: EdgeInsets.only(left: 16), // Adjusted for RTL
                 // Line 837: child: Material( // Wrap with Material for InkWell
                 child: Material(
                   // Line 838: color: Colors.transparent,
                   color: Colors.transparent,
                   // Line 839: shape: CircleBorder(),
                   shape: CircleBorder(),
                   // Line 840: clipBehavior: Clip.antiAlias,
                   clipBehavior: Clip.antiAlias,
                   // Line 841: child: InkWell( // Add InkWell for ripple
                   child: InkWell(
                      key: _keyProfileIcon, // Move key here if needed for InkWell target
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ProfilePage(threadId: widget.threadId)),
                      ),
                      child: Container(
                        // Line 847: padding: EdgeInsets.all(2), // Padding for border effect
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: _currentAvatarColor, width: 2),
                          boxShadow: [
                            BoxShadow(
                              // Line 851: color: Colors.black.withOpacity(0.15), // Slightly stronger shadow
                              color: Colors.black.withOpacity(0.15),
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
              ),
            ],
          ),
        ),
        // Line 863: // Apply main gradient to the body container as well
        body: Container(
          // Line 864: decoration: BoxDecoration(
          decoration: BoxDecoration(
            // Line 865: gradient: LinearGradient(
            gradient: LinearGradient(
              // Line 866: colors: _currentAvatarGradient,
              colors: _currentAvatarGradient.isNotEmpty ? _currentAvatarGradient : [Colors.white, Colors.grey.shade200],
              // Line 867: begin: Alignment.topCenter,
              begin: Alignment.topCenter,
              // Line 868: end: Alignment.bottomCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          // Line 871: child: Column( // Changed Stack to Column for simpler layout
          child: Column(
            children: [
              // Line 874: // Top Avatar and Status Section
              // Line 875: Padding(
              Padding(
                // Line 876: padding: const EdgeInsets.only(top: 20.0, bottom: 15.0), // Adjusted padding
                padding: const EdgeInsets.only(top: 20.0, bottom: 15.0),
                child: Column(
                  key: _keyAvatarTop,
                  children: [
                    Container(
                      // Line 880: width: 120, // Slightly smaller top avatar
                      width: 120,
                      // Line 881: height: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 4))],
                        border: Border.all(
                          color: _isRecording ? Colors.red : _isSending ? Colors.blue : _currentAvatarColor,
                          // Line 885: width: 3.5, // Slightly thicker border
                          width: 3.5,
                        ),
                      ),
                      // Line 888: child: ClipOval( // Use ClipOval for perfect circle image
                      child: ClipOval(
                        // Line 889: child: Stack(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                             Image.asset(_currentAvatarImage, fit: BoxFit.cover, width: 118, height: 118), // Adjust inner size
                             // Line 896: // Conditionally show overlay animation
                             // Line 897: if (_isRecording || _isSending)
                             if (_isRecording || _isSending)
                               // Line 898: Positioned.fill(
                               Positioned.fill(
                                 // Line 899: child: Container(
                                 child: Container(
                                   // Line 900: decoration: BoxDecoration(
                                   decoration: BoxDecoration(
                                     // Line 901: shape: BoxShape.circle,
                                     shape: BoxShape.circle,
                                     // Line 902: color: (_isRecording ? Colors.redAccent : Colors.blueAccent).withOpacity(0.3), // Tint overlay
                                     color: (_isRecording ? Colors.redAccent : Colors.blueAccent).withOpacity(0.3),
                                   ),
                                   // Line 904: child: Lottie.asset( // Local asset is faster
                                   child: Lottie.asset(
                                     // Line 905: 'assets/lottie/listening_wave.json', // Replace with your wave/activity Lottie
                                     'assets/lottie/listening_wave.json', // Ensure this asset exists
                                     fit: BoxFit.cover,
                                   ),
                                 ),
                               ),
                          ],
                        ),
                      ),
                    ),
                    // Line 913: SizedBox(height: 12), // Increased spacing
                    SizedBox(height: 12),
                    // Line 915: Container(
                    Container(
                      // Line 916: padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8), // Adjusted padding
                      padding: EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      decoration: BoxDecoration(
                        // Line 918: color: Colors.white.withOpacity(0.95), // Slightly less transparent
                        color: Colors.white.withOpacity(0.95),
                        // Line 919: borderRadius: BorderRadius.circular(25), // Fully rounded corners
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: Offset(0, 2))],
                        border: Border.all(
                           // Line 921: color: (_isRecording ? Colors.redAccent : _isSending ? Colors.blueAccent : _currentAvatarColor).withOpacity(0.6), // Stronger border opacity
                           color: (_isRecording ? Colors.redAccent : _isSending ? Colors.blueAccent : _currentAvatarColor).withOpacity(0.6),
                           // Line 922: width: 1.5,
                           width: 1.5,
                        ),
                      ),
                      // Line 925: child: _buildStatusText(), // Use helper for status text
                      child: _buildStatusText(),
                    ),
                  ],
                ),
              ),
              // Line 931: // Chat Area
              Expanded(
                child: Container(
                  key: _keyChatArea,
                  // Line 934: margin: EdgeInsets.symmetric(horizontal: 10), // Keep horizontal margin
                  margin: EdgeInsets.symmetric(horizontal: 10),
                  // Line 935: padding: EdgeInsets.only(top: 5), // Add padding above list
                  padding: EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    // Line 937: color: Colors.white.withOpacity(0.80), // Slightly more transparent background
                    color: Colors.white.withOpacity(0.80),
                    // Line 938: borderRadius: BorderRadius.vertical(top: Radius.circular(30)), // Rounded top corners only
                    borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                    // Line 939: border: Border.all(color: _currentAvatarColor.withOpacity(0.2), width: 1.5),
                    border: Border.all(color: _currentAvatarColor.withOpacity(0.2), width: 1.5),
                    // Line 940: boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, -2))], // Shadow adjusted
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, -2))],
                  ),
                  // Line 942: child: ClipRRect( // Clip the list view
                  child: ClipRRect(
                    // Line 943: borderRadius: BorderRadius.vertical(top: Radius.circular(28)), // Match decoration rounding
                    borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
                    // Line 944: child: Stack( // Stack to add background character image
                    child: Stack(
                      children: [
                        // Line 946: // Background Character Image (Subtle)
                        // Line 947: Positioned.fill(
                        Positioned.fill(
                          // Line 948: child: Opacity(
                          child: Opacity(
                            // Line 949: opacity: 0.08, // Very subtle opacity
                            opacity: 0.08,
                            // Line 950: child: Image.asset(
                            child: Image.asset(
                              // Line 951: _currentAvatarImage,
                              _currentAvatarImage,
                              // Line 952: fit: BoxFit.contain, // Contain to see more of the character
                              fit: BoxFit.contain,
                              // Line 953: alignment: Alignment.center,
                              alignment: Alignment.center,
                            ),
                          ),
                        ),
                        // Line 958: // Message List
                        // Line 959: ListView.builder(
                        ListView.builder(
                          controller: _scrollController,
                          // Line 961: padding: EdgeInsets.only(top: 10, bottom: 10, left: 5, right: 5), // Adjusted list padding
                          padding: EdgeInsets.only(top: 10, bottom: 10, left: 5, right: 5),
                          itemCount: messages.length,
                          itemBuilder: (context, index) => _buildMessage(messages[index], index),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              // Input Area Container
              Container(
                key: _keyInputFieldContainer,
                decoration: BoxDecoration(
                  // Line 971: gradient: LinearGradient(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    // Line 974: _currentAvatarGradient.last.withOpacity(0.0), // Match background fade
                    colors: _currentAvatarGradient.isNotEmpty
                       ? [
                          _currentAvatarGradient.last.withOpacity(0.0),
                          // Line 975: _currentAvatarGradient.last.withOpacity(0.7),
                          _currentAvatarGradient.last.withOpacity(0.7),
                          // Line 976: _currentAvatarGradient.last
                          _currentAvatarGradient.last
                         ]
                       : [Colors.transparent, Colors.grey.shade200, Colors.grey.shade300], // Fallback
                    stops: [0.0, 0.3, 1.0],
                  ),
                ),
                child: Padding(
                  // Line 981: padding: EdgeInsets.fromLTRB(12, 8, 12, 12), // Adjusted padding
                  padding: EdgeInsets.fromLTRB(12, 8, 12, 16),
                  // Line 982: child: Material( // Use Material for elevation and shape
                  child: Material(
                    // Line 983: elevation: 6, // Increased elevation
                    elevation: 6,
                    // Line 984: borderRadius: BorderRadius.circular(35), // More rounded input field
                    borderRadius: BorderRadius.circular(35),
                    // Line 985: shadowColor: Colors.black.withOpacity(0.25),
                    shadowColor: Colors.black.withOpacity(0.25),
                    // Line 986: child: Container(
                    child: Container(
                      // Line 988: padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Inner padding
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        // Line 990: color: Colors.white,
                        color: Colors.white,
                        // Line 991: borderRadius: BorderRadius.circular(35),
                        borderRadius: BorderRadius.circular(35),
                        // Line 992: border: Border.all(
                        border: Border.all(
                          color: _isRecording ? Colors.redAccent : _isTyping ? _currentAvatarColor : Colors.grey.shade300,
                          // Line 994: width: 2, // Thicker border
                          width: 2,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Line 999: // Send Button (Animated)
                          // Line 1000: AnimatedContainer(
                          AnimatedContainer(
                            // Line 1001: duration: Duration(milliseconds: 250), // Smooth animation
                            duration: Duration(milliseconds: 250),
                            // Line 1002: curve: Curves.easeInOut,
                            curve: Curves.easeInOut,
                            key: _keySendButton,
                            width: 48,
                            height: 48,
                            // Line 1005: margin: EdgeInsets.only(right: 8), // Standard margin (Adjusted for RTL later)
                            margin: EdgeInsets.only(right: 8), // Adjusted for RTL by parent Row reversal
                            decoration: BoxDecoration(
                              color: _isTyping ? _currentAvatarColor : Colors.grey.shade300,
                              shape: BoxShape.circle,
                               // Line 1008: boxShadow: _isTyping ? [ // Add glow effect when active
                               boxShadow: _isTyping ? [
                                 // Line 1009: BoxShadow(
                                 BoxShadow(
                                   // Line 1010: color: _currentAvatarColor.withOpacity(0.5),
                                   color: _currentAvatarColor.withOpacity(0.5),
                                   // Line 1011: blurRadius: 8,
                                   blurRadius: 8,
                                   // Line 1012: spreadRadius: 1,
                                   spreadRadius: 1,
                                 )
                               ] : [],
                            ),
                             // Line 1015: child: Material( // Material for InkWell
                             child: Material(
                               // Line 1016: color: Colors.transparent,
                               color: Colors.transparent,
                               // Line 1017: shape: CircleBorder(),
                               shape: CircleBorder(),
                               // Line 1018: clipBehavior: Clip.antiAlias,
                               clipBehavior: Clip.antiAlias,
                               // Line 1019: child: InkWell( // Add InkWell
                               child: InkWell(
                                 // Line 1020: onTap: _isTyping ? () { _sendMessage(_controller.text); } : null,
                                 onTap: _isTyping ? () { _sendMessage(_controller.text); } : null,
                                 // Line 1021: splashColor: Colors.white.withOpacity(0.5),
                                 splashColor: Colors.white.withOpacity(0.5),
                                 // Line 1022: child: Center(
                                 child: Center(
                                   // Line 1023: child: Icon(
                                   child: Icon(
                                     Icons.send_rounded,
                                     // Line 1025: color: _isTyping ? Colors.white : Colors.grey.shade500,
                                     color: _isTyping ? Colors.white : Colors.grey.shade500,
                                     // Line 1026: size: 26, // Standardized icon size
                                     size: 26,
                                   ),
                                 ),
                               ),
                             ),
                          ),
                          // Text Input Field
                          Expanded(
                            child: TextField(
                              controller: _controller,
                              decoration: InputDecoration(
                                // Line 1034: hintText: _isRecording ? 'أستمع...' : 'اكتب أو سجل!', // Translated
                                hintText: _isRecording ? 'أستمع...' : 'اكتب أو سجل!',
                                // Line 1035: border: InputBorder.none, // Clean look
                                border: InputBorder.none,
                                // Line 1036: hintStyle: _hintTextStyle, // Use defined style
                                hintStyle: _hintTextStyle,
                                // Line 1037: contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10), // Adjusted padding
                                contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                              ),
                              // Line 1039: style: _inputTextStyle, // Use defined style
                              style: _inputTextStyle,
                              // Line 1040: maxLines: 1, // Keep it single line for consistency
                              maxLines: 1,
                              textInputAction: TextInputAction.send,
                              onSubmitted: (text) {
                                if (text.isNotEmpty) { _sendMessage(text); }
                              },
                              enabled: !_isRecording,
                              // Line 1045: textDirection: TextDirection.rtl, // Explicit RTL
                              textDirection: TextDirection.rtl,
                            ),
                          ),
                          // Line 1048: // Microphone Button
                          // Line 1049: SizedBox( // Add spacing between text field and mic button
                          SizedBox(
                            // Line 1050: width: 4,
                            width: 4,
                          ),
                           // Line 1052: Material( // Wrap with Material for InkWell effect
                           GestureDetector(
                                  key: _keyMicButton,
                                  onLongPressStart: (_) => _startRecording(),
                                  onLongPressEnd: (_) => _stopRecording(),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    margin: EdgeInsets.only(left: 8), // Adjusted for RTL
                                    decoration: BoxDecoration(
                                      color: _isRecording ? Colors.red.withOpacity(0.1) : _currentAvatarColor.withOpacity(0.1),
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
                        // Line 1085: ].reversed.toList(), // Reversed for RTL layout
                        ].reversed.toList(),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        // Line 1091: // Bottom Navigation Bar (Stylized)
        // Line 1092: bottomNavigationBar: Container(
        bottomNavigationBar: Container(
          // Line 1093: decoration: BoxDecoration(
          decoration: BoxDecoration(
            // Line 1094: color: Colors.white, // Solid white background
            color: Colors.white,
            // Line 1095: boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: Offset(0, -2))],
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: Offset(0, -2))],
            // Line 1096: borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)), // More rounded corners
            borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
          ),
          // Line 1098: child: ClipRRect( // Clip the NavBar content
          child: ClipRRect(
            // Line 1099: borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(30), topRight: Radius.circular(30)),
            child: BottomNavBar(
              threadId: threadId,
              currentIndex: 2,
            ),
          ),
        ),
      ),
    );
  }

   // Line 1107: // Helper widget for status text with Lottie animation integration
   // Line 1108: Widget _buildStatusText() {
   Widget _buildStatusText() {
     // Line 1110: Color statusColor;
     Color statusColor;
     // Line 1111: Widget statusIcon;
     Widget statusIcon;
     Widget statusContent; // Keep statusContent Text separate

     if (_isRecording) {
       statusColor = Colors.redAccent;
       // Line 1115: // Use a Lottie animation for listening
       // Line 1116: statusIcon = Lottie.asset(
       statusIcon = Lottie.asset(
         // Line 1117: 'assets/lottie/listening_pulse.json', // Replace with your listening Lottie
         'assets/lottie/listening_pulse.json', // Ensure this asset exists
         // Line 1118: width: 24, height: 24
         width: 24, height: 24
       );
       statusContent = Text(
         "أنا أستمع... $_recordingDuration",
         // Line 1120: style: _statusTextStyle.copyWith(color: statusColor), // Use defined style
         style: _statusTextStyle.copyWith(color: statusColor),
         textDirection: TextDirection.rtl,
       );
     } else if (_isSending) {
       statusColor = Colors.blueAccent;
       // Line 1124: // Use a Lottie animation for thinking
       // Line 1125: statusIcon = Lottie.asset(
       statusIcon = Lottie.asset(
         // Line 1126: 'assets/lottie/thinking_gears.json', // Replace with your thinking Lottie
         'assets/lottie/thinking_gears.json', // Ensure this asset exists
         // Line 1127: width: 28, height: 28 // Slightly larger thinking icon
         width: 28, height: 28
       );
       statusContent = Text(
         // Line 1129: "همم، أفكر...", // Changed text slightly
         "همم، أفكر...",
         // Line 1130: style: _statusTextStyle.copyWith(color: statusColor), // Use defined style
         style: _statusTextStyle.copyWith(color: statusColor),
         textDirection: TextDirection.rtl,
       );
     } else {
       statusColor = _currentAvatarColor;
       // Line 1135: // Use the avatar image when idle
       // Line 1136: statusIcon = Image.asset(_currentAvatarImage, width: 24, height: 24);
       statusIcon = Image.asset(_currentAvatarImage, width: 24, height: 24);
       statusContent = Text(
         "اسألني أي شيء!",
         // Line 1138: style: _statusTextStyle.copyWith(color: statusColor), // Use defined style
         style: _statusTextStyle.copyWith(color: statusColor),
         textDirection: TextDirection.rtl,
       );
     }

     return Directionality(
       textDirection: TextDirection.rtl,
       // Line 1143: child: Row(
       child: Row(
         // Line 1144: mainAxisSize: MainAxisSize.min,
         mainAxisSize: MainAxisSize.min,
         // Line 1145: children: [
         children: [
           // Line 1146: statusIcon, // Display the icon/animation
           statusIcon,
           // Line 1147: SizedBox(width: 8),
           SizedBox(width: 8),
           // Line 1148: statusContent, // Display the text
           statusContent,
         // Line 1149: ].reversed.toList(), // Reversed for RTL
         ].reversed.toList(),
       ),
     );
   }

}