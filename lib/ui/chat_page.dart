
import 'package:flutter/material.dart';
import 'package:front_kiddoai/ui/profile_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:audioplayers/audioplayers.dart';
import 'dart:async';
import '../widgets/bottom_nav_bar.dart';
// tutorial: Import ImageFilter for blur effect
import 'dart:ui' show ImageFilter;
import 'package:flutter_sound/flutter_sound.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:lottie/lottie.dart';
import '../models/avatar_settings.dart'; // Ensure this import is correct
// tutorial: Import the tutorial_coach_mark package
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';
// tutorial: Import google_fonts for consistent text styling in the tutorial
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

// tutorial: Add WidgetsBindingObserver to detect when the build is complete (optional but good practice)
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

  // --- Tutorial Setup Variables ---
  // tutorial: Declare TutorialCoachMark instance
  TutorialCoachMark? _tutorialCoachMark;
  // tutorial: List to hold the tutorial targets
  List<TargetFocus> _targets = [];

  // tutorial: GlobalKeys to identify widgets for the tutorial
  final GlobalKey _keyAvatarTop = GlobalKey();       // Key for the top avatar image/status area
  final GlobalKey _keyChatArea = GlobalKey();        // Key for the main chat message list container
  final GlobalKey _keyInputFieldContainer = GlobalKey(); // Key for the whole input container at the bottom
  final GlobalKey _keyMicButton = GlobalKey();         // Key for the microphone button
  final GlobalKey _keySendButton = GlobalKey();        // Key for the send button
  final GlobalKey _keyProfileIcon = GlobalKey();       // Key for the profile icon in AppBar

  // tutorial: Preference key to check if tutorial was shown for this specific page
  final String _tutorialPreferenceKey = 'chatPageTutorialShown';
  // --- End Tutorial Setup Variables ---

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
      if (mounted) { // tutorial: Check if mounted before calling setState
        setState(() {
          _isTyping = _controller.text.isNotEmpty;
        });
      }
    });

    // tutorial: Add observer to know when build is complete (optional)
    WidgetsBinding.instance.addObserver(this);
    // tutorial: Check if the tutorial needs to be shown when the page loads
    _checkIfTutorialShouldBeShown();
  }

  // tutorial: Ensure observer is removed when the widget is disposed
   @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // tutorial: Remove observer
    _timer?.cancel();
    _recordingTimer?.cancel();
    _audioRecorder.closeRecorder();
    _animationController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    _audioPlayer.dispose(); // tutorial: Dispose audio player

    // tutorial: Dismiss the tutorial if it's showing when the page is disposed
    if (_tutorialCoachMark?.isShowing ?? false) {
      _tutorialCoachMark!.finish();
    }
    super.dispose();
  }

  // tutorial: Override didChangeAppLifecycleState to handle app pauses during tutorial (optional but good practice)
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // tutorial: If the app is paused while the tutorial is showing, dismiss it.
    if (state == AppLifecycleState.paused && (_tutorialCoachMark?.isShowing ?? false)) {
       _tutorialCoachMark?.finish();
    }
  }

  Future<void> _loadAvatarSettings() async {
    final avatar = await AvatarSettings.getCurrentAvatar();
    // tutorial: Ensure theme is loaded before potentially using its colors in the tutorial
    if (mounted) {
      setState(() {
        _currentAvatarName = avatar['name'] ?? 'SpongeBob';
        _currentAvatarImage = avatar['imagePath'] ?? 'assets/avatars/spongebob.png';
        _currentVoicePath = avatar['voicePath'] ?? 'assets/voices/spongebob.wav';
        final selectedAvatar = _avatars.firstWhere(
          (a) => a['name'] == _currentAvatarName,
          orElse: () => _avatars[0], // Default to first avatar if not found
        );
        _currentAvatarColor = selectedAvatar['color'];
        _currentAvatarGradient = selectedAvatar['gradient'];
      });
    }
  }

  Future<void> _getThreadId() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) { // tutorial: Check mounted before setState
      setState(() {
        threadId = prefs.getString('threadId') ?? '';
      });
    }
  }

  Future<void> _loadMessages() async {
    // Ensure threadId is loaded before trying to load messages
    if (threadId.isEmpty) {
      await _getThreadId();
      if (threadId.isEmpty) return; // Still no threadId, cannot load messages
    }

    final prefs = await SharedPreferences.getInstance();
    final savedMessages = prefs.getString('chatMessages_$threadId');

    if (savedMessages != null) {
      try { // tutorial: Add try-catch for safety during JSON decoding
        final List<dynamic> decodedMessages = jsonDecode(savedMessages);
        if (mounted) { // tutorial: Check mounted before setState
           setState(() {
             messages.clear();
             messages.addAll(decodedMessages.map((msg) => Message.fromJson(msg)).toList());
           });
        }
       } catch (e) {
         print("Error decoding saved messages: $e");
         // Optionally clear corrupted messages or handle error
          await prefs.remove('chatMessages_$threadId'); // Clear corrupted data
          if (mounted) {
            setState(() {
               messages.clear();
               messages.add(Message(sender: 'bot', content: 'مرحباً! كيف حالك اليوم؟', timestamp: DateTime.now()));
            });
          }
       }

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && mounted) { // tutorial: Check mounted
          _scrollToBottom();
        }
      });
    } else {
       if (mounted) { // tutorial: Check mounted before setState
         setState(() {
           // Only add initial message if messages list is truly empty
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
    if (threadId.isEmpty) return; // Don't save if no threadId
    final prefs = await SharedPreferences.getInstance();
    try { // tutorial: Add try-catch for safety during JSON encoding
       final encodedMessages = jsonEncode(messages.map((msg) => msg.toJson()).toList());
       await prefs.setString('chatMessages_$threadId', encodedMessages);
    } catch (e) {
       print("Error encoding messages for saving: $e");
    }
  }


  void _scrollToBottom() {
    // tutorial: Check mounted before accessing scroll controller properties
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
    // 👇 Add temporary "typing..." message
    messages.add(Message(sender: 'bot', content: 'typing_indicator', timestamp: DateTime.now()));
  });

  _saveMessages();
  Future.delayed(Duration(milliseconds: 100), () => _scrollToBottom());

  try {
    // Retrieve the access token from SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    final response = await http.post(
      Uri.parse('https://7aaf-41-226-166-49.ngrok-free.app/KiddoAI/chat/send'),
      headers: {
        "Content-Type": "application/json",
        // Add the Authorization header only if the accessToken exists
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
    // tutorial: Only proceed if audio player is available and component is mounted
       try {
         // Use the currently selected voice path
         final String effectiveVoicePath = _currentVoicePath.isNotEmpty ? _currentVoicePath : 'assets/voices/spongebob.wav';
         // Construct the expected filename based on the path
         final String speakerWavFilename = effectiveVoicePath.split('/').last;

          print("Initializing voice for text: '$text' with speaker: $speakerWavFilename"); // Debug log

         // Replace with your actual TTS endpoint
         final baseUrl = 'https://8f36-160-159-94-45.ngrok-free.app';
         final response = await http.post(
           Uri.parse('$baseUrl/initialize-voice'),
           headers: {"Content-Type": "application/json"},
           body: jsonEncode({
             "text": text,
             // Send the filename, assuming backend expects this format
             "speaker_wav": speakerWavFilename,
           }),
         ).timeout(const Duration(seconds: 15)); // Add timeout

         if (response.statusCode == 200) {
           final data = jsonDecode(response.body);
           final requestId = data['request_id'] as String?;
           final totalParts = data['total_parts'] as int?;

           if (requestId == null || totalParts == null || totalParts <= 0) {
             throw Exception('Invalid response from /initialize-voice');
           }

            print("Request ID: $requestId, Total Parts: $totalParts"); // Debug log

           // Play audio parts sequentially
           for (int currentPart = 1; currentPart <= totalParts; currentPart++) {
             String? audioUrl;
             int attempts = 0;
             while (audioUrl == null && attempts < 10 && mounted) { // Add attempts limit and mounted check
               final statusResponse = await http.get(
                 Uri.parse('$baseUrl/part-status/$requestId/$currentPart'),
               ).timeout(const Duration(seconds: 10)); // Timeout for status check

               if (statusResponse.statusCode == 200) {
                 final statusData = jsonDecode(statusResponse.body);
                 if (statusData['status'] == 'done') {
                   audioUrl = statusData['audio_url'] as String?;
                    print("Part $currentPart Ready: $audioUrl"); // Debug log
                   if (audioUrl == null || audioUrl.isEmpty) {
                      throw Exception('Audio URL is null or empty for part $currentPart');
                   }
                 } else {
                    print("Part $currentPart not ready, waiting..."); // Debug log
                   await Future.delayed(Duration(seconds: 2)); // Wait longer between checks
                 }
               } else {
                 throw Exception('Error checking status for part $currentPart: ${statusResponse.statusCode}');
               }
               attempts++;
             }

              if (audioUrl != null && mounted) { // Check mounted before playing
                await _audioPlayer.play(UrlSource(audioUrl));
                // Wait for playback to complete before fetching the next part
                await _audioPlayer.onPlayerComplete.first;
              } else if (mounted) { // Check mounted before throwing
                 throw Exception('Failed to get audio URL for part $currentPart after multiple attempts.');
              }
           }
         } else {
           print("Error initializing voice: ${response.statusCode} - ${response.body}");
         }
       } on TimeoutException catch (_) {
          print("Voice initialization/playback timed out.");
          // Handle timeout - maybe show a message?
       } catch (e) {
         print("Error in voice initialization/playback: $e");
         // Optionally show an error message in the chat
          // if (mounted) {
          //    setState(() {
          //       messages.add(Message(sender: 'bot', content: "Sorry, I couldn't play the audio response.", timestamp: DateTime.now()));
          //    });
          //    _scrollToBottom();
          // }
       }
    
  }

  Future<void> _initializeRecorder() async {
    try {
      var status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
         throw RecordingPermissionException("Microphone permission not granted");
      }
      // Optionally request storage permission if saving files persistently,
      // but getTemporaryDirectory usually doesn't require explicit storage perms.
      // await Permission.storage.request();

      await _audioRecorder.openRecorder();
       // Set subscription duration for UI updates (optional)
       _audioRecorder.setSubscriptionDuration(const Duration(milliseconds: 500));

    } catch (e) {
      print("Error initializing recorder: $e");
       // Optionally show a message to the user
    }
  }


  Future<void> _requestPermissions() async {
     // Request microphone permission explicitly
     var microphoneStatus = await Permission.microphone.request();
     if (microphoneStatus.isDenied || microphoneStatus.isPermanentlyDenied) {
       print("Microphone permission denied.");
       // Optionally show a dialog asking the user to enable permission in settings
       // openAppSettings();
     }

     // Storage permission might be needed depending on where you save
     // For temporary directory, it might not be strictly required on all platforms/versions
     // var storageStatus = await Permission.storage.request();
     // if (storageStatus.isDenied || storageStatus.isPermanentlyDenied) {
     //    print("Storage permission denied.");
     // }
  }


  Future<void> _startRecording() async {
    // Ensure recorder is open and permissions are granted
    if (!_audioRecorder.isStopped) {
      print("Recorder is not stopped. Cannot start recording.");
      return;
    }
     await _requestPermissions(); // Re-check permissions just in case
     var status = await Permission.microphone.status;
     if (!status.isGranted) {
        print("Cannot record without microphone permission.");
        // Show message to user
        return;
     }


    try {
       // Define the path in a temporary directory
       Directory tempDir = await getTemporaryDirectory();
       String path = '${tempDir.path}/kiddoai_audio_${DateTime.now().millisecondsSinceEpoch}.wav';
       print("Starting recording to: $path"); // Debug log

      await _audioRecorder.startRecorder(
         toFile: path,
         codec: Codec.pcm16WAV, // Use WAV codec
       );

      if (mounted) { // tutorial: Check mounted
         setState(() {
           _isRecording = true;
           _recordingSeconds = 0;
           _recordingDuration = "0:00";
         });
      }
      _animationController.repeat(reverse: true); // Start animation

      _recordingTimer?.cancel(); // Cancel any existing timer
      _recordingTimer = Timer.periodic(Duration(seconds: 1), (timer) {
         if (mounted) { // tutorial: Check mounted
           setState(() {
             _recordingSeconds++;
             // Format duration string MM:SS
             final minutes = (_recordingSeconds ~/ 60);
             final seconds = (_recordingSeconds % 60).toString().padLeft(2, '0');
             _recordingDuration = "$minutes:$seconds";
           });
         } else {
            timer.cancel(); // Stop timer if widget is disposed
         }
      });
    } catch (e) {
      print("Error starting recording: $e");
       if (mounted) { // tutorial: Check mounted
          setState(() { _isRecording = false; }); // Reset recording state on error
       }
       _animationController.stop();
       _recordingTimer?.cancel();
    }
  }

  Future<void> _stopRecording() async {
    // Ensure recorder is actually recording
     if (!_audioRecorder.isRecording) {
       print("Recorder is not recording. Cannot stop.");
        // Ensure UI state is consistent if stop is called unexpectedly
        if (_isRecording && mounted) {
           setState(() { _isRecording = false; });
           _animationController.stop();
           _recordingTimer?.cancel();
        }
       return;
     }

    try {
      String? path = await _audioRecorder.stopRecorder();
       print("Stopped recording. File path: $path"); // Debug log

       // Reset UI state immediately after stopping
       if (mounted) { // tutorial: Check mounted
          setState(() {
            _isRecording = false;
          });
       }
       _animationController.reset(); // Reset animation to start state
       _recordingTimer?.cancel();

      if (path == null) {
         print("Stopping recorder returned null path.");
         return; // No file path means nothing to send
      }

      final audioFile = File(path);
      if (!await audioFile.exists()) {
         print("Audio file does not exist at path: $path");
         return; // File doesn't exist
      }

      final audioBytes = await audioFile.readAsBytes();
      if (audioBytes.isEmpty) {
         print("Audio file is empty.");
         return; // File is empty
      }

       print("Audio file size: ${audioBytes.length} bytes"); // Debug log

       // Indicate processing/sending state
       if (mounted) setState(() => _isSending = true);

      // Send audio to backend for transcription and response
      final transcription = await _sendAudioToBackend(audioBytes);

       // Process the transcription and get bot response
       if (transcription != null && transcription.trim().isNotEmpty) {
          print("Transcription received: $transcription"); // Debug log
          // Add transcription as user message (optional)
          // if (mounted) {
          //    setState(() {
          //       messages.add(Message(sender: 'user', content: transcription, timestamp: DateTime.now()));
          //    });
          //    _scrollToBottom();
          //    _saveMessages();
          // }
          // Send transcription to chat endpoint
          await _sendMessage(transcription);
       } else {
          print("Transcription failed or is empty."); // Debug log
          // Handle failed transcription - show message?
          if (mounted) {
              setState(() {
                 messages.add(Message(sender: 'bot', content: "Sorry, I couldn't hear that clearly.", timestamp: DateTime.now()));
                 _isSending = false; // Reset sending state
              });
              _scrollToBottom();
              _saveMessages();
          }
       }

       // Clean up the temporary audio file
       // await audioFile.delete();
       // print("Deleted temporary audio file: $path");

    } catch (e) {
      print("Error stopping/processing recording: $e");
      if (mounted) { // tutorial: Check mounted
         setState(() {
           _isRecording = false; // Ensure recording state is reset on error
           _isSending = false; // Reset sending state
         });
      }
      _animationController.reset();
      _recordingTimer?.cancel();
    } finally {
       // Ensure sending state is reset if sending didn't start/finish properly
       if (_isSending && mounted) {
          setState(() => _isSending = false);
       }
    }
  }

  // Updated to handle transcription response structure
Future<String?> _sendAudioToBackend(List<int> audioBytes) async {
  final uri = Uri.parse('https://7aaf-41-226-166-49.ngrok-free.app/KiddoAI/chat/transcribe');

  final request = http.MultipartRequest('POST', uri)
    ..fields['threadId'] = threadId
    ..files.add(http.MultipartFile.fromBytes('audio', audioBytes, filename: 'audio.wav'));

  // Retrieve the access token from SharedPreferences
  final prefs = await SharedPreferences.getInstance();
  final accessToken = prefs.getString('accessToken');
  // Add the Authorization header if the token exists
  if (accessToken != null) {
    request.headers['Authorization'] = "Bearer $accessToken";
  }

  final response = await request.send();
  if (response.statusCode == 200) {
    return await response.stream.bytesToString();
  }
  return null;
}

  // Build individual message bubble
  Widget _buildMessage(Message message, int index) {
    // tutorial: This widget builds message bubbles, no tutorial keys needed inside here directly
    final isUser = message.sender == 'user';
    final bool isBot = message.sender == 'bot';

    // Determine if the avatar should be shown (for bot messages, typically the first in a sequence)
    final bool showBotAvatar = isBot && (index == 0 || messages[index - 1].sender != 'bot');
    // Determine if timestamp should be shown (e.g., for the last message or when sender changes)
    // final bool showTimestamp = index == messages.length - 1 || messages[index + 1].sender != message.sender;


    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6), // Adjusted padding
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end, // Align bubbles at the bottom
        children: [
          // Bot Avatar (shown only when needed)
          if (showBotAvatar) ...[
            GestureDetector(
               onTap: () => _initializeVoice(message.content), // Tap avatar to play voice
               child: CircleAvatar(
                 backgroundImage: AssetImage(_currentAvatarImage),
                 radius: 18, // Slightly larger avatar
               ),
            ),
            SizedBox(width: 8),
          ],
          // Placeholder for alignment if avatar isn't shown
          if (isBot && !showBotAvatar)
              SizedBox(width: 18 * 2 + 8), // Width of avatar + padding

          // Message Bubble
          Flexible(
            child: GestureDetector(
              onTap: isBot ? () => _initializeVoice(message.content) : null, // Tap bot message to play
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.7, // Limit max width
                ),
                padding: EdgeInsets.symmetric(horizontal: 14, vertical: 10), // Adjusted padding
                decoration: BoxDecoration(
                  color: isUser ? _currentAvatarColor : Colors.white, // Use theme color for user
                  // Border only for bot messages for distinction
                  border: isBot ? Border.all(color: _currentAvatarColor.withOpacity(0.5), width: 1.5) : null,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    // Pointy corner based on sender
                    bottomLeft: isUser ? Radius.circular(18) : Radius.circular(4),
                    bottomRight: isUser ? Radius.circular(4) : Radius.circular(18),
                  ),
                  boxShadow: [ // Softer shadow
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
                    fontSize: 15.5, // Slightly larger font
                    height: 1.3, // Line height
                  ),
                ),
                 // Optional: Timestamp inside the bubble (can get cluttered)
                // child: Column( ... add timestamp here if desired ... ),
              ),
            ),
          ),

           // User Avatar (optional, usually not shown for user messages)
           // if (isUser) ...[ SizedBox(width: 8), CircleAvatar(...) ],
        ],
      ),
    );
  }


  // --- Tutorial Functions ---

  // tutorial: Checks SharedPreferences to see if the tutorial should be shown.
  void _checkIfTutorialShouldBeShown() async {
    await Future.delayed(Duration.zero); // Ensure context is available
    if (!mounted) return; // tutorial: Check if widget is still mounted

    SharedPreferences prefs = await SharedPreferences.getInstance();
    // tutorial: Default to 'false' if the key doesn't exist
    bool tutorialSeen = prefs.getBool(_tutorialPreferenceKey) ?? false;

    print("Tutorial seen status for '$_tutorialPreferenceKey': $tutorialSeen"); // Debug log

    // tutorial: If tutorial hasn't been seen, initialize and schedule it to show
    if (!tutorialSeen) {
      // tutorial: Ensure the UI frame is rendered before trying to find widgets by keys
      WidgetsBinding.instance.addPostFrameCallback((_) {
         // tutorial: Add a small delay to ensure all elements are definitely built
         Future.delayed(const Duration(milliseconds: 600), () {
           // tutorial: Check if the widget is still mounted before initializing and showing
           if (mounted) {
              _initTargets(); // Prepare the tutorial steps
              // Check if targets were actually created (keys might not be ready)
               if (_targets.isNotEmpty && _keyAvatarTop.currentContext != null) {
                  _showTutorial(); // Show the tutorial sequence
               } else {
                  print("Tutorial aborted: Targets could not be initialized (keys might be missing).");
                  // Optionally mark as seen anyway to prevent retries, or log this error
                  // _markTutorialAsSeen();
               }
           }
        });
      });
    }
  }

  // tutorial: Defines the steps (TargetFocus) for the tutorial.
  void _initTargets() {
    _targets.clear(); // tutorial: Clear previous targets if any

    // Target 1: Top Avatar Area
    if (_keyAvatarTop.currentContext != null) { // tutorial: Check if key context exists
      _targets.add(
        TargetFocus(
          identify: "avatarTop",
          keyTarget: _keyAvatarTop,
          alignSkip: Alignment.bottomRight,
          enableOverlayTab: true,
          contents: [
            TargetContent(
              align: ContentAlign.bottom,
              child: _buildTutorialContent(
                title: "Your Buddy!",
                description: "This is your friendly AI companion! See their status here.",
              ),
            ),
          ],
          shape: ShapeLightFocus.RRect, // Use RRect for the container area
          radius: 20,
        ),
      );
    } else { print("Tutorial key context missing: _keyAvatarTop"); } // Debug log

    // Target 2: Chat Message Area
     if (_keyChatArea.currentContext != null) { // tutorial: Check if key context exists
        _targets.add(
          TargetFocus(
            identify: "chatArea",
            keyTarget: _keyChatArea,
            alignSkip: Alignment.topRight,
            enableOverlayTab: true,
            contents: [
              TargetContent(
                align: ContentAlign.top,
                child: _buildTutorialContent(
                  title: "Chat History",
                  description: "All your messages with your buddy will appear here. Scroll up to see older chats!",
                ),
              ),
            ],
            shape: ShapeLightFocus.RRect,
            radius: 25, // Match container radius
          ),
        );
     } else { print("Tutorial key context missing: _keyChatArea"); } // Debug log


    // Target 3: Input Field Container
     if (_keyInputFieldContainer.currentContext != null) { // tutorial: Check if key context exists
        _targets.add(
          TargetFocus(
            identify: "inputFieldContainer",
            keyTarget: _keyInputFieldContainer,
            alignSkip: Alignment.topRight,
            enableOverlayTab: true,
            contents: [
              TargetContent(
                align: ContentAlign.top,
                child: _buildTutorialContent(
                  title: "Talk Here!",
                  description: "Type your message or question in this box to chat.",
                ),
              ),
            ],
            shape: ShapeLightFocus.RRect,
            radius: 30, // Match container radius
          ),
        );
     } else { print("Tutorial key context missing: _keyInputFieldContainer"); } // Debug log


    // Target 4: Microphone Button
     if (_keyMicButton.currentContext != null) { // tutorial: Check if key context exists
        _targets.add(
          TargetFocus(
            identify: "micButton",
            keyTarget: _keyMicButton,
            alignSkip: Alignment.topRight,
            enableOverlayTab: true,
            contents: [
              TargetContent(
                align: ContentAlign.top,
                child: _buildTutorialContent(
                  title: "Speak Up!",
                  description: "Hold this button to record your voice message instead of typing!",
                ),
              ),
            ],
            shape: ShapeLightFocus.Circle, // Circle shape for the button
          ),
        );
     } else { print("Tutorial key context missing: _keyMicButton"); } // Debug log

    // Target 5: Send Button
     if (_keySendButton.currentContext != null) { // tutorial: Check if key context exists
        _targets.add(
          TargetFocus(
            identify: "sendButton",
            keyTarget: _keySendButton,
            alignSkip: Alignment.topLeft,
            enableOverlayTab: true,
            contents: [
              TargetContent(
                align: ContentAlign.top,
                child: _buildTutorialContent(
                  title: "Send Message!",
                  description: "Tap here to send your typed message to your buddy.",
                ),
              ),
            ],
            shape: ShapeLightFocus.Circle, // Circle shape for the button
          ),
        );
     } else { print("Tutorial key context missing: _keySendButton"); } // Debug log

     // Target 6: Profile Icon (Optional)
     if (_keyProfileIcon.currentContext != null) { // tutorial: Check if key context exists
        _targets.add(
          TargetFocus(
            identify: "profileIcon",
            keyTarget: _keyProfileIcon,
            alignSkip: Alignment.bottomLeft,
            enableOverlayTab: true,
            contents: [
              TargetContent(
                align: ContentAlign.bottom,
                child: _buildTutorialContent(
                  title: "Your Profile!",
                  description: "Check your settings or change your avatar here.",
                ),
              ),
            ],
            shape: ShapeLightFocus.Circle,
          ),
        );
     } else { print("Tutorial key context missing: _keyProfileIcon"); } // Debug log

  }

 // tutorial: Builds the content widget displayed for each tutorial step, styled like the example.
 Widget _buildTutorialContent({required String title, required String description}) {
    // tutorial: Use theme color or fallback, similar to previous examples
    final Color tutorialBackgroundColor = _currentAvatarColor.withOpacity(0.9);
    final Color titleColor = Colors.yellowAccent; // Consistent bright title
    final Color descriptionColor = Colors.white;

    return Container(
      padding: const EdgeInsets.all(16.0),
      // tutorial: Add margin similar to the example page for better spacing
      margin: const EdgeInsets.only(bottom: 20.0, left: 20.0, right: 20.0),
      decoration: BoxDecoration(
        color: tutorialBackgroundColor,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: const [ // tutorial: Add a subtle shadow like the example
           BoxShadow(
             color: Colors.black26,
             blurRadius: 8,
             offset: Offset(0, 4),
           )
        ]
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            // tutorial: Use GoogleFonts for consistent styling or fallback
            style: GoogleFonts.comicNeue( // Example using a playful font
              fontWeight: FontWeight.bold,
              color: titleColor,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8.0),
          Text(
            description,
            // tutorial: Use GoogleFonts for consistent styling or fallback
            style: GoogleFonts.comicNeue(
              color: descriptionColor,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }


  // tutorial: Creates and shows the tutorial coach mark sequence.
  void _showTutorial() {
    // tutorial: Double-check targets are ready and context is valid
     if (_targets.isEmpty || !mounted) {
       print("Tutorial show aborted: Targets empty or widget not mounted.");
       return;
     }

    _tutorialCoachMark = TutorialCoachMark(
      targets: _targets,
      // tutorial: Use a color from the theme for the shadow
      colorShadow: _currentAvatarColor.withOpacity(0.8),
      textSkip: "SKIP", // tutorial: Standard skip text
      paddingFocus: 5, // tutorial: Padding around the highlighted area
      opacityShadow: 0.8, // tutorial: Shadow opacity
      // tutorial: Apply blur effect like the example page
      imageFilter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
      // tutorial: Custom Skip Button styled like the example page
       skipWidget: Container(
         padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
         decoration: BoxDecoration(
            color: Colors.redAccent, // tutorial: Consistent skip button color
            borderRadius: BorderRadius.circular(20),
         ),
         child: const Text("Skip All", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
      onFinish: () {
        print("Chat Page Tutorial Finished");
        // tutorial: Mark as seen when finished
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
        // tutorial: Optionally advance tutorial on overlay click
        // _tutorialCoachMark?.next();
      },
      onSkip: () {
        print("Chat Page Tutorial Skipped");
        // tutorial: Also mark as seen if skipped
        _markTutorialAsSeen();
        return true; // tutorial: Return true to allow skip
      },
    )..show(context: context); // tutorial: Use cascade notation to show immediately
  }

  // tutorial: Saves a flag to SharedPreferences indicating the tutorial has been seen.
  void _markTutorialAsSeen() async {
     SharedPreferences prefs = await SharedPreferences.getInstance();
     await prefs.setBool(_tutorialPreferenceKey, true);
     print("Marked '$_tutorialPreferenceKey' as seen.");
  }
   // --- End Tutorial Functions ---


  @override
  Widget build(BuildContext context) {
    // tutorial: Show loading indicator if threadId or avatar settings aren't ready
    if (threadId.isEmpty || _currentAvatarImage.isEmpty) {
      return Scaffold(
        body: Container(
          // Use gradient from loaded theme if available, else default
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
                LottieBuilder.network( // Loading animation
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
                    "Loading your magical chat...",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _currentAvatarColor, // Use loaded color
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Main Scaffold build
    return Scaffold(
      backgroundColor: _currentAvatarGradient.last, // Use theme gradient
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(70), // Custom AppBar height
        child: AppBar(
         backgroundColor: _currentAvatarColor, // Use theme color
          elevation: 0,
          centerTitle: true,
          shape: RoundedRectangleBorder( // Rounded bottom corners
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(25),
              bottomRight: Radius.circular(25),
            ),
          ),
          title: Row( // Centered title with avatar image
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                _currentAvatarImage, // Use loaded avatar image
                height: 40,
                width: 40,
              ),
              SizedBox(width: 10),
              RichText( // Styled App Name
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Comic Sans MS', // Consistent font
                  ),
                  children: [
                    TextSpan(text: 'K', style: TextStyle(color: Colors.yellow)),
                    TextSpan(text: 'iddo', style: TextStyle(color: Colors.white)),
                    TextSpan(text: 'A', style: TextStyle(color: Colors.yellow)),
                    TextSpan(text: 'i', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: GestureDetector(
                // tutorial: Assign key to profile icon GestureDetector
                key: _keyProfileIcon,
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage(threadId: widget.threadId)),
                ),
                child: Container( // Styled profile icon container
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                   border: Border.all(color: _currentAvatarColor, width: 2), // Theme border
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundImage: AssetImage(_currentAvatarImage), // Use loaded avatar
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
          // Background gradient
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _currentAvatarGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: Stack(
            children: [
              // Faded background image (optional)
              // Positioned.fill(
              //   child: Container(
              //     decoration: BoxDecoration(
              //       image: DecorationImage(
              //         image: AssetImage(_currentAvatarImage),
              //         fit: BoxFit.contain,
              //         opacity: 0.05,
              //         alignment: Alignment.center,
              //       ),
              //     ),
              //   ),
              // ),

              // Main Content Area (Chat list + Input field)
              Column( // Use Column instead of Stack for easier layout
                 children: [
                   // Top Avatar + Status Area
                   Padding(
                      padding: const EdgeInsets.only(top: 15.0), // Spacing from AppBar
                      // tutorial: Assign key to the top avatar/status Column
                      child: Column(
                         key: _keyAvatarTop,
                         children: [
                            // Animated Avatar Container
                           Container(
                             width: 130,
                             height: 130,
                             decoration: BoxDecoration(
                               color: Colors.white,
                               shape: BoxShape.circle,
                               boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 4)) ],
                               border: Border.all(
                                 color: _isRecording ? Colors.red : _isSending ? Colors.blue : _currentAvatarColor, // Dynamic border color
                                 width: 3,
                               ),
                             ),
                             child: Stack( // Stack for Lottie overlay
                               alignment: Alignment.center,
                               children: [
                                 ClipOval( child: Image.asset( _currentAvatarImage, fit: BoxFit.cover, width: 130, height: 130)),
                                 // Lottie animation overlay when recording or sending
                                 if (_isRecording || _isSending)
                                   Positioned.fill(
                                     child: ClipOval(
                                       child: Lottie.network(
                                         'https://assets1.lottiefiles.com/packages/lf20_vctzcozn.json', // Example thinking/listening animation
                                         fit: BoxFit.cover,
                                       ),
                                     ),
                                   ),
                               ],
                             ),
                           ),
                            // Status Text Bubble
                           Container(
                             margin: EdgeInsets.only(top: 10),
                             padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                             decoration: BoxDecoration(
                               color: Colors.white.withOpacity(0.9), // Slightly transparent
                               borderRadius: BorderRadius.circular(25),
                               boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.1), blurRadius: 5, offset: Offset(0, 2)) ],
                               border: Border.all(
                                 color: (_isRecording ? Colors.red : _isSending ? Colors.blue : _currentAvatarColor).withOpacity(0.5), // Dynamic border
                                 width: 2,
                               ),
                             ),
                             child: _buildStatusText(), // Use helper for status text
                           ),
                         ],
                      ),
                   ),
                    SizedBox(height: 15), // Spacing between status and chat area

                   // Chat Message Area (Takes remaining space)
                   Expanded(
                     child: Container(
                       // tutorial: Assign key to the chat message list container
                       key: _keyChatArea,
                       margin: EdgeInsets.symmetric(horizontal: 10),
                       decoration: BoxDecoration(
                         color: Colors.white.withOpacity(0.85), // More opaque background
                         borderRadius: BorderRadius.circular(25),
                         border: Border.all( color: _currentAvatarColor.withOpacity(0.3), width: 2),
                         boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: Offset(0, 4)) ],
                       ),
                       child: ClipRRect( // Clip the list view to rounded corners
                         borderRadius: BorderRadius.circular(23), // Slightly smaller radius than container
                         child: ListView.builder(
                           controller: _scrollController,
                           padding: EdgeInsets.symmetric(vertical: 15), // Padding inside the list
                           itemCount: messages.length,
                           itemBuilder: (context, index) => _buildMessage(messages[index], index),
                         ),
                       ),
                     ),
                   ),
                   SizedBox(height: 5), // Small spacing before input field

                   // Input Field Area
                   // tutorial: Wrap input area Material/Container with a Key
                   Container(
                      key: _keyInputFieldContainer, // tutorial: Assign key here
                      decoration: BoxDecoration(
                         // Optional gradient or background for the input area base
                         gradient: LinearGradient(
                           begin: Alignment.topCenter, end: Alignment.bottomCenter,
                           colors: [ Colors.white.withOpacity(0.0), Colors.white.withOpacity(0.9), Colors.white ],
                           stops: [0.0, 0.3, 1.0] // Adjust stops for gradient effect
                         ),
                      ),
                      child: Padding(
                         padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + MediaQuery.of(context).viewInsets.bottom), // Adjust padding for keyboard
                         child: Material( // Material for elevation and shape
                           elevation: 5,
                           borderRadius: BorderRadius.circular(30),
                           shadowColor: Colors.black.withOpacity(0.2), // Shadow color
                           child: Container(
                             padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6), // Inner padding
                             decoration: BoxDecoration(
                               color: Colors.white, // Solid background for input field container
                               borderRadius: BorderRadius.circular(30),
                               border: Border.all( // Dynamic border based on state
                                 color: _isRecording ? Colors.redAccent : _isTyping ? _currentAvatarColor : Colors.grey.shade300,
                                 width: 1.5,
                               ),
                             ),
                             child: Row(
                               children: [
                                 // Microphone Button
                                 GestureDetector(
                                    // tutorial: Assign key to the mic button GestureDetector
                                   key: _keyMicButton,
                                   onLongPressStart: (_) => _startRecording(),
                                   onLongPressEnd: (_) => _stopRecording(),
                                   child: Container( // Styled mic button container
                                     width: 48, height: 48,
                                     margin: EdgeInsets.only(right: 8),
                                     decoration: BoxDecoration(
                                       color: _isRecording ? Colors.red.withOpacity(0.1) : _currentAvatarColor.withOpacity(0.1),
                                       shape: BoxShape.circle,
                                     ),
                                     child: AnimatedBuilder( // Animation for mic icon
                                       animation: _animationController,
                                       builder: (context, child) {
                                         return Transform.scale(
                                           scale: _isRecording ? _microphoneScaleAnimation.value : 1.0, // Scale animation when recording
                                           child: Icon(
                                             _isRecording ? Icons.stop_rounded : Icons.mic_rounded, // Use rounded icons
                                             color: _isRecording ? Colors.redAccent : _currentAvatarColor,
                                             size: 26,
                                           ),
                                         );
                                       },
                                     ),
                                   ),
                                 ),
                                 // Text Input Field
                                 Expanded(
                                   child: TextField(
                                     controller: _controller,
                                     decoration: InputDecoration(
                                       hintText: _isRecording ? 'Listening...' : 'Type or hold mic...',
                                       border: InputBorder.none,
                                       hintStyle: TextStyle( color: Colors.grey[500], fontFamily: 'Comic Sans MS', fontSize: 15),
                                       contentPadding: EdgeInsets.symmetric(vertical: 10, horizontal: 5), // Adjust padding
                                     ),
                                     style: TextStyle( fontSize: 15, fontFamily: 'Comic Sans MS'),
                                     maxLines: null, // Allows multiline input
                                     textInputAction: TextInputAction.send, // Show send button on keyboard
                                     onSubmitted: (text) { // Send on keyboard action
                                         if (text.isNotEmpty) { _sendMessage(text); }
                                     },
                                     enabled: !_isRecording, // Disable text field while recording
                                   ),
                                 ),
                                 // Send Button
                                 AnimatedContainer( // Animate send button appearance/color
                                   duration: Duration(milliseconds: 200),
                                    // tutorial: Assign key to the send button container
                                   key: _keySendButton,
                                   width: 48, height: 48,
                                   margin: EdgeInsets.only(left: 8), // Margin before send button
                                   decoration: BoxDecoration(
                                     // Use theme color when active, grey when inactive
                                     color: _isTyping ? _currentAvatarColor : Colors.grey.shade300,
                                     shape: BoxShape.circle,
                                   ),
                                   child: IconButton(
                                     icon: Icon( Icons.send_rounded, // Rounded send icon
                                       // White when active, darker grey when inactive
                                       color: _isTyping ? Colors.white : Colors.grey.shade500,
                                     ),
                                     iconSize: 24,
                                     tooltip: "Send Message", // Accessibility
                                     // Enable button only if typing
                                     onPressed: _isTyping ? () { _sendMessage(_controller.text); } : null,
                                   ),
                                 ),
                               ],
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
      // Bottom Navigation Bar (styled)
      bottomNavigationBar: Container(
        decoration: BoxDecoration( // Add shadow and rounded corners
          color: Colors.white,
          boxShadow: [ BoxShadow( color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: Offset(0, -2)) ],
          borderRadius: BorderRadius.only( topLeft: Radius.circular(25), topRight: Radius.circular(25)),
        ),
        child: ClipRRect( // Clip the NavBar content
          borderRadius: BorderRadius.only( topLeft: Radius.circular(25), topRight: Radius.circular(25)),
          child: BottomNavBar(
            threadId: threadId,
            currentIndex: 2, // Set current index for this page
             // tutorial: Add key here if NavBar needs to be targeted by the tutorial
             // key: _keyBottomNav,
          ),
        ),
      ),
    );
  }

   // Helper widget to build the status text dynamically
   Widget _buildStatusText() {
     // tutorial: Helper function, not directly part of tutorial targets
     Widget statusContent;
     Color statusColor;
     String lottieUrl = ''; // Lottie animation URL based on state

     if (_isRecording) {
       statusColor = Colors.redAccent;
       lottieUrl = 'https://assets3.lottiefiles.com/packages/lf20_tzjnbj0d.json'; // Recording Lottie
       statusContent = Text(
         "I'm listening... $_recordingDuration",
         style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Comic Sans MS'),
       );
     } else if (_isSending) {
       statusColor = Colors.blueAccent;
       lottieUrl = 'https://assets9.lottiefiles.com/packages/lf20_nw19osms.json'; // Thinking/Loading Lottie
       statusContent = Text(
         "Hmm, let me think...",
         style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Comic Sans MS'),
       );
     } else {
       statusColor = _currentAvatarColor;
       // No Lottie when idle, just show avatar icon
       statusContent = Text(
         "Ask me anything!", // Default idle text
         style: TextStyle(color: statusColor, fontWeight: FontWeight.bold, fontSize: 16, fontFamily: 'Comic Sans MS'),
       );
     }

     // Build the Row with Lottie/Image and Text
     return Row(
       mainAxisSize: MainAxisSize.min, // Fit content
       children: [
         // Show Lottie if recording/sending, else show static avatar icon
         lottieUrl.isNotEmpty
             ? Lottie.network(lottieUrl, width: 30, height: 30)
             : Image.asset(_currentAvatarImage, width: 24, height: 24),
         SizedBox(width: 8),
         statusContent,
       ],
     );
   }


} // End of _ChatPageState