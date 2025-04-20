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
        messages.add(Message(sender: 'bot', content: 'typing_indicator', timestamp: DateTime.now()));
      });

      _controller.clear(); // Clear input after sending
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
            messages.removeWhere((m) => m.content == 'typing_indicator');
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
            messages.add(Message(sender: 'bot', content: "عفوًا! حاول مرة أخرى!", timestamp: DateTime.now()));
          });
        }
      } catch (e) {
        setState(() {
          _isSending = false;
          messages.removeWhere((m) => m.content == 'typing_indicator');
          messages.add(Message(sender: 'bot', content: "خطأ في الاتصال!", timestamp: DateTime.now()));
        });
      }
    }

    Future<void> _initializeVoice(String text) async {
      try {
        final String effectiveVoicePath = _currentVoicePath.isNotEmpty ? _currentVoicePath : 'assets/voices/SpongeBob.wav';
        final String speakerWavFilename = effectiveVoicePath.split('/').last;

        final baseUrl = 'http://192.168.100.88:8000';
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
                  audioUrl = 'http://192.168.100.88:8000${statusData['audio_url']}';
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
      final uri = Uri.parse('https://e59e-41-230-204-2.ngrok-free.app/KiddoAI/chat/transcribe');

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
        textDirection: TextDirection.rtl, // Added for RTL
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Row(
            mainAxisAlignment: isUser ? MainAxisAlignment.start : MainAxisAlignment.end, // Reversed for RTL
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Bot Avatar (shown only when needed)
              if (showBotAvatar) ...[
                GestureDetector(
                  onTap: () => _initializeVoice(message.content),
                  child: CircleAvatar(
                    backgroundImage: AssetImage(_currentAvatarImage),
                    radius: 18,
                  ),
                ),
                SizedBox(width: 8),
              ],
              // Placeholder for alignment if avatar isn't shown
              if (isBot && !showBotAvatar)
                SizedBox(width: 18 * 2 + 8),

              // Message Bubble
              Flexible(
                child: GestureDetector(
                  onTap: isBot ? () => _initializeVoice(message.content) : null,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser ? _currentAvatarColor : Colors.white,
                      border: isBot ? Border.all(color: _currentAvatarColor.withOpacity(0.5), width: 1.5) : null,
                      borderRadius: BorderRadius.only(
                        topRight: Radius.circular(18), // Reversed for RTL
                        topLeft: Radius.circular(18),
                        bottomRight: isUser ? Radius.circular(18) : Radius.circular(4),
                        bottomLeft: isUser ? Radius.circular(4) : Radius.circular(18),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      message.content,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 15.5,
                        height: 1.3,
                      ),
                      textDirection: TextDirection.rtl, // Added for RTL
                    ),
                  ),
                ),
              ),
            ].reversed.toList(), // Reversed for RTL
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
                  description: "اضغط هذا الزر لتسجيل رسالتك الصوتية بدلاً من الكتابة!", // Translated
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
      final Color titleColor = Colors.yellowAccent;
      final Color descriptionColor = Colors.white;

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
                title,
                style: GoogleFonts.tajawal( // Changed to Arabic font
                  fontWeight: FontWeight.bold,
                  color: titleColor,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                description,
                style: GoogleFonts.tajawal(
                  color: descriptionColor,
                  fontSize: 16,
                ),
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
          child: const Text(
            "تخطى الكل", // Translated: Skip All
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
                    LottieBuilder.network(
                      'https://assets9.lottiefiles.com/packages/lf20_kkhbsucc.json',
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
                        style: TextStyle(
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
        child: Scaffold(
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
                        TextSpan(text: 'K', style: TextStyle(color: Colors.yellow)),
                        TextSpan(text: 'iddo', style: TextStyle(color: Colors.white)),
                        TextSpan(text: 'A', style: TextStyle(color: Colors.yellow)),
                        TextSpan(text: 'i', style: TextStyle(color: Colors.white)),
                      ],
                    ),
                  ),
                ].reversed.toList(), // Reversed for RTL
              ),
              actions: [
                Padding(
                  padding: EdgeInsets.only(left: 16), // Adjusted for RTL
                  child: GestureDetector(
                    key: _keyProfileIcon,
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
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 4))],
                                border: Border.all(
                                  color: _isRecording ? Colors.red : _isSending ? Colors.blue : _currentAvatarColor,
                                  width: 3,
                                ),
                              ),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  ClipOval(child: Image.asset(_currentAvatarImage, fit: BoxFit.cover, width: 130, height: 130)),
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
                              margin: EdgeInsets.only(top: 10),
                              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(25),
                                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: Offset(0, 2))],
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
                      SizedBox(height: 15),
                      Expanded(
                        child: Container(
                          key: _keyChatArea,
                          margin: EdgeInsets.symmetric(horizontal: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(25),
                            border: Border.all(color: _currentAvatarColor.withOpacity(0.3), width: 2),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 4))],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(23),
                            child: ListView.builder(
                              controller: _scrollController,
                              padding: EdgeInsets.symmetric(vertical: 15),
                              itemCount: messages.length,
                              itemBuilder: (context, index) => _buildMessage(messages[index], index),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 5),
                      Container(
                        key: _keyInputFieldContainer,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.white.withOpacity(0.0), Colors.white.withOpacity(0.9), Colors.white],
                            stops: [0.0, 0.3, 1.0],
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + MediaQuery.of(context).viewInsets.bottom),
                          child: Material(
                            elevation: 5,
                            borderRadius: BorderRadius.circular(30),
                            shadowColor: Colors.black.withOpacity(0.2),
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: _isRecording ? Colors.redAccent : _isTyping ? _currentAvatarColor : Colors.grey.shade300,
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                children: [
                                  // Send Button
                                  AnimatedContainer(
                                    duration: Duration(milliseconds: 200),
                                    key: _keySendButton,
                                    width: 48,
                                    height: 48,
                                    margin: EdgeInsets.only(right: 8), // Adjusted for RTL
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
                                      tooltip: "أرسل الرسالة", // Translated: Send Message
                                      onPressed: _isTyping ? () { _sendMessage(_controller.text); } : null,
                                    ),
                                  ),
                                  // Text Input Field
                                  Expanded(
                                    child: TextField(
                                      controller: _controller,
                                      decoration: InputDecoration(
                                        hintText: _isRecording ? 'أستمع...' : 'اكتب أو سجل!', // Translated
                                        border: InputBorder.none,
                                        hintStyle: TextStyle(color: Colors.grey[500], fontFamily: 'Comic Sans MS', fontSize: 15),
                                        contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 5),
                                      ),
                                      style: TextStyle(fontSize: 15, fontFamily: 'Comic Sans MS'),
                                      maxLines: null,
                                      textInputAction: TextInputAction.send,
                                      onSubmitted: (text) {
                                        if (text.isNotEmpty) { _sendMessage(text); }
                                      },
                                      enabled: !_isRecording,
                                      textDirection: TextDirection.rtl, // Added for RTL
                                    ),
                                  ),
                                  // Microphone Button
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
                                ].reversed.toList(), // Reversed for RTL
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
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: Offset(0, -2))],
              borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.only(topLeft: Radius.circular(25), topRight: Radius.circular(25)),
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
          "أنا أستمع... $_recordingDuration", // Translated: I'm listening...
          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Comic Sans MS'),
          textDirection: TextDirection.rtl,
        );
      } else if (_isSending) {
        statusColor = Colors.blueAccent;
        lottieUrl = 'https://assets9.lottiefiles.com/packages/lf20_nw19osms.json';
        statusContent = Text(
          "همم، دعني أفكر...", // Translated: Hmm, let me think...
          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Comic Sans MS'),
          textDirection: TextDirection.rtl,
        );
      } else {
        statusColor = _currentAvatarColor;
        statusContent = Text(
          "اسألني أي شيء!", // Translated: Ask me anything!
          style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Comic Sans MS'),
          textDirection: TextDirection.rtl,
        );
      }

      return Directionality(
        textDirection: TextDirection.rtl, // Added for RTL
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            lottieUrl.isNotEmpty
                ? Lottie.network(lottieUrl, width: 30, height: 30)
                : Image.asset(_currentAvatarImage, width: 24, height: 24),
            SizedBox(width: 8),
            statusContent,
          ].reversed.toList(), // Reversed for RTL
        ),
      );
    }
  }
