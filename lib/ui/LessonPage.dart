import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import '../view_models/Lessons_ViewModel.dart';
import 'package:front_kiddoai/services/lessons_service.dart';
import '../widgets/loading_animation_widget.dart';
import 'webview_activity_widget.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:front_kiddoai/ui/profile_page.dart';

class LessonsPage extends StatefulWidget {
  final String subjectName;

  const LessonsPage({Key? key, required this.subjectName}) : super(key: key);

  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> with TickerProviderStateMixin {
  final LessonsViewModel _viewModel = LessonsViewModel();

  /// For loading states (e.g., creating a thread).
  bool _isLoading = false;

  /// Stores the chatbot messages (user + assistant).
  final List<Map<String, String>> _messages = [];

  /// Controller for the chatbot text input.
  final TextEditingController _chatController = TextEditingController();

  /// Audio player for any TTS or future expansions.
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Animation controllers for list + header.
  late AnimationController _listAnimationController;
  late AnimationController _headerAnimationController;

  /// Toggles whether the chatbot is visible.
  bool _showChatbot = false;

  /// Toggles whether audio is currently playing.
  bool _isPlayingAudio = false;

  /// Subject color is **always** green in the new UI, or you can map by subject if you prefer.
  Color _getSubjectColor() => const Color(0xFF4CAF50);

  /// For demonstration, you can still map icons by subject if desired.
  IconData _getSubjectIcon() {
    final lower = widget.subjectName.toLowerCase();
    if (lower.contains('math') || lower.contains('رياضيات')) {
      return Icons.calculate;
    } else if (lower.contains('science') || lower.contains('علوم')) {
      return Icons.science;
    } else if (lower.contains('english') || lower.contains('انجليزي')) {
      return Icons.menu_book;
    } else if (lower.contains('history') || lower.contains('تاريخ')) {
      return Icons.history_edu;
    } else if (lower.contains('art') || lower.contains('فن')) {
      return Icons.palette;
    } else if (lower.contains('music') || lower.contains('موسيقى')) {
      return Icons.music_note;
    }
    return Icons.school;
  }

  /// Optional background images for each subject (not mandatory).
  final Map<String, String> _subjectBackgrounds = {
    'Math': 'https://img.freepik.com/free-vector/hand-drawn-math-background_23-2148157511.jpg',
    'Science': 'https://img.freepik.com/free-vector/hand-drawn-science-background_23-2148499325.jpg',
    'English': 'https://img.freepik.com/free-vector/hand-drawn-english-background_23-2149483602.jpg',
    'History': 'https://img.freepik.com/free-vector/hand-drawn-history-background_23-2148161527.jpg',
    'Art': 'https://img.freepik.com/free-vector/hand-drawn-art-background_23-2149483554.jpg',
    'Music': 'https://img.freepik.com/free-vector/hand-drawn-music-background_23-2148523557.jpg',
  };

  String _getSubjectBackground() {
    return _subjectBackgrounds[widget.subjectName] ?? '';
  }

  @override
  void initState() {
    super.initState();
    _viewModel.fetchLessons(widget.subjectName);

    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _listAnimationController.forward();
    _headerAnimationController.forward();

    _audioPlayer.onPlayerStateChanged.listen((state) {
      setState(() {
        _isPlayingAudio = (state == PlayerState.playing);
      });
    });
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    _headerAnimationController.dispose();
    _audioPlayer.dispose();
    _chatController.dispose();
    super.dispose();
  }

  // =========================
  //  TTS Initialization (Optional)
  // =========================
  Future<void> _initializeVoice(String text) async {
    try {
      final baseUrl = 'https://f661-196-184-87-113.ngrok-free.app';
      final response = await http.post(
        Uri.parse('$baseUrl/initialize-voice'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "text": text,
          "speaker_wav": "sounds/SpongBob.wav",
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
                await Future.delayed(const Duration(seconds: 1));
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

  // =========================
  //  Chatbot Logic
  // =========================

  /// Called when user clicks "Learn". Creates a new thread, opens chatbot, and sends the first message.
  Future<void> _teachLesson(String lessonName, String subjectName) async {
    setState(() {
      _isLoading = true;
      _messages.clear();
      _showChatbot = false; // reset to hide, then show after success
    });

    try {
      // 1) Create new thread
      final newThreadId = await LessonsService().createThread();

      // 2) Save thread in SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('threadId', newThreadId);

      // 3) Show chatbot UI
      setState(() {
        _showChatbot = true;
        _isLoading = false;
      });

      // 4) Construct and send initial message
      String initialMessage = "اشرحلي درس $lessonName في $subjectName";
      await _sendMessage(initialMessage);
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error creating thread: $e"),
          backgroundColor: Colors.red.shade700,
        ),
      );
    }
  }

  /// Sends a message (user input) to the server, awaits response, and updates the chat.
  Future<void> _sendMessage(String userText) async {
    if (userText.trim().isEmpty) return;

    // 1) Add user message locally
    setState(() {
      _messages.add({"sender": "user", "text": userText});
      _chatController.clear();
    });

    // 2) Retrieve thread ID from local storage
    final prefs = await SharedPreferences.getInstance();
    final threadId = prefs.getString('threadId') ?? '';
    if (threadId.isEmpty) {
      // No thread => show error in chat
      setState(() {
        _messages.add({
          "sender": "assistant",
          "text": "No threadId found. Please login again."
        });
      });
      return;
    }

    // 3) Send user message to server
    final url = Uri.parse('https://2789-41-226-166-49.ngrok-free.app/teach');
    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'thread_id': threadId,
          'text': userText,
        }),
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        String botReply = "";

        // If the JSON has a "response" key, use that; otherwise, fallback to raw body
        if (decoded is Map && decoded.containsKey('response')) {
          botReply = decoded['response'] as String? ?? "No response found.";
        } else {
          botReply = response.body;
        }

        // 4) Add assistant response to chat
        setState(() {
          _messages.add({"sender": "assistant", "text": botReply});
        });

        // Optionally use TTS:
        // _initializeVoice(botReply);

      } else {
        setState(() {
          _messages.add({
            "sender": "assistant",
            "text": "Oops, failed to get response from server."
          });
        });
      }
    } catch (e) {
      setState(() {
        _messages.add({
          "sender": "assistant",
          "text": "Error sending message: $e"
        });
      });
    }
  }

  // =========================
  //  Activity Logic
  // =========================

  Future<void> _checkAndOpenActivity(String lessonName, String subjectName, int level) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoadingAnimationWidget(),
    );

    final activityUrl = "http://172.20.10.13:8083/KiddoAI/Activity/saveProblem";
    final activityPageUrl = "http://172.20.10.13:8080/";

    try {
      final response = await http.post(
        Uri.parse(activityUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "lesson": lessonName,
          "subject": subjectName,
          "level": level,
        }),
      );

      Navigator.pop(context);

      if (response.statusCode == 200) {
        // Open WebView
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => WebViewActivityWidget(activityUrl: activityPageUrl),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Error: Could not prepare activity."),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error loading activity: $e"),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(10),
        ),
      );
    }
  }

  // =========================
  //  Chatbot UI
  // =========================

  Widget _buildChatbotSection(Color subjectColor) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: subjectColor.withOpacity(0.15),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(
          color: subjectColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 10, 15),
            decoration: BoxDecoration(
              color: subjectColor.withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: subjectColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.chat, color: subjectColor, size: 22),
                ),
                const SizedBox(width: 15),
                Text(
                  "Lesson Chatbot",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: subjectColor,
                    fontFamily: 'Comic Sans MS',
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(Icons.close, color: Colors.grey.shade700),
                  onPressed: () {
                    setState(() {
                      _showChatbot = false;
                      _audioPlayer.stop();
                    });
                  },
                ),
              ],
            ),
          ),

          // Messages list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = (msg["sender"] == "user");
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.all(10),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    decoration: BoxDecoration(
                      color: isUser
                          ? subjectColor.withOpacity(0.2)
                          : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      msg["text"] ?? "",
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.black87,
                        fontFamily: 'Comic Sans MS',
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Input field + send button
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _chatController,
                    decoration: const InputDecoration(
                      hintText: "Type your question...",
                      border: InputBorder.none,
                    ),
                    onSubmitted: (value) => _sendMessage(value),
                    style: const TextStyle(fontFamily: 'Comic Sans MS'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: subjectColor),
                  onPressed: () => _sendMessage(_chatController.text),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // =========================
  //  Main Build
  // =========================

  @override
  Widget build(BuildContext context) {
    final Color subjectColor = _getSubjectColor();
    final IconData subjectIcon = _getSubjectIcon();
    final String backgroundImage = _getSubjectBackground();

    return Scaffold(
      backgroundColor: const Color(0xFFF2FFF0), // Light green background
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CAF50),
        elevation: 0,
        centerTitle: true,
        title: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.yellow.shade200,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.yellow.shade300.withOpacity(0.5),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset('assets/spongebob.png', height: 30),
              const SizedBox(width: 8),
              RichText(
                text: const TextSpan(
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Comic Sans MS',
                  ),
                  children: [
                    TextSpan(text: 'K', style: TextStyle(color: Colors.green)),
                    TextSpan(text: 'iddo', style: TextStyle(color: Colors.black)),
                    TextSpan(text: 'A', style: TextStyle(color: Colors.blue)),
                    TextSpan(text: 'i', style: TextStyle(color: Colors.black)),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: GestureDetector(
              onTap: () {
                // Example: Navigate to profile page
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => ProfilePage(threadId: '')),
                );
              },
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.yellow.shade400, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const CircleAvatar(
                  backgroundImage: AssetImage('assets/spongebob.png'),
                  radius: 22,
                ),
              ),
            ),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Repeating SpongeBob background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: backgroundImage.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(backgroundImage),
                        fit: BoxFit.cover,
                        opacity: 0.05,
                      )
                    : null,
              ),
            ),
          ),

          // For a playful repeated pattern, if desired (comment out if not needed):
          // Positioned.fill(
          //   child: Container(
          //     decoration: const BoxDecoration(
          //       image: DecorationImage(
          //         image: AssetImage('assets/spongebob.png'),
          //         repeat: ImageRepeat.repeat,
          //         opacity: 0.1,
          //       ),
          //     ),
          //   ),
          // ),

          // Main scrollable content
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // If we are loading a new lesson thread, show a Sliver with a loading animation
              if (_isLoading)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30.0),
                      child: Column(
                        children: [
                          Lottie.network(
                            'https://assets10.lottiefiles.com/packages/lf20_2LdL1k.json',
                            height: 150,
                            errorBuilder: (context, error, stackTrace) {
                              return CircularProgressIndicator(
                                color: subjectColor,
                                strokeWidth: 3,
                              );
                            },
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Loading your lesson...",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "This might take a moment",
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              // If chatbot is active, show it in a Sliver so it can scroll
              if (_showChatbot)
                SliverToBoxAdapter(
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: _buildChatbotSection(subjectColor),
                  ),
                ),

              // "Available Lessons" title
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        subjectColor.withOpacity(0.9),
                        subjectColor,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: subjectColor.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Let's Learn Together!",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Comic Sans MS',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Explore lessons in ${widget.subjectName}",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                fontFamily: 'Comic Sans MS',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 70,
                        height: 70,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: Lottie.asset(
                          'assets/book_animation.json',
                          width: 60,
                          height: 60,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Lessons list
              ValueListenableBuilder<List<Map<String, dynamic>>>(
                valueListenable: _viewModel.lessons,
                builder: (context, lessons, _) {
                  if (lessons.isEmpty) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Lottie.network(
                              'https://assets10.lottiefiles.com/packages/lf20_wnqlfojb.json',
                              height: 150,
                              errorBuilder: (context, error, stackTrace) {
                                return const Icon(Icons.error, size: 50, color: Colors.red);
                              },
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'No lessons available yet!',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                                fontFamily: 'Comic Sans MS',
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _viewModel.fetchLessons(widget.subjectName);
                                });
                              },
                              icon: const Icon(Icons.refresh),
                              label: Text("Refresh", style: const TextStyle(fontFamily: 'Comic Sans MS')),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: subjectColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final lesson = lessons[index];
                        final name = lesson['name'];
                        final level = lesson['level'];

                        // Staggered animation for each item
                        final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                          CurvedAnimation(
                            parent: _listAnimationController,
                            curve: Interval(
                              (index / lessons.length) * 0.5,
                              ((index + 1) / lessons.length) * 0.5 + 0.5,
                              curve: Curves.easeOut,
                            ),
                          ),
                        );

                        return AnimatedBuilder(
                          animation: animation,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset((1 - animation.value) * 100, 0),
                              child: Opacity(
                                opacity: animation.value,
                                child: child,
                              ),
                            );
                          },
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                              border: Border.all(
                                color: Colors.grey.shade100,
                                width: 1,
                              ),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  _checkAndOpenActivity(name, widget.subjectName, level);
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 60,
                                            height: 60,
                                            decoration: BoxDecoration(
                                              color: subjectColor.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.school,
                                              color: subjectColor,
                                              size: 30,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: const TextStyle(
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black87,
                                                    fontFamily: 'Comic Sans MS',
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.access_time,
                                                      size: 14,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      "10-15 min",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey.shade600,
                                                        fontFamily: 'Comic Sans MS',
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    Container(
                                                      width: 4,
                                                      height: 4,
                                                      decoration: BoxDecoration(
                                                        color: Colors.grey.shade400,
                                                        shape: BoxShape.circle,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    const Icon(
                                                      Icons.star,
                                                      size: 14,
                                                      color: Colors.amber,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      "Beginner",
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: Colors.grey.shade600,
                                                        fontFamily: 'Comic Sans MS',
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 15),
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton.icon(
                                              icon: const Icon(Icons.play_circle_outline, size: 18),
                                              label: Text("Start Activity", style: const TextStyle(fontFamily: 'Comic Sans MS')),
                                              onPressed: () {
                                                _checkAndOpenActivity(name, widget.subjectName, level);
                                              },
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: subjectColor,
                                                side: BorderSide(color: subjectColor),
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: ElevatedButton.icon(
                                              icon: const Icon(Icons.lightbulb_outline, size: 18),
                                              label: Text("Learn", style: const TextStyle(fontFamily: 'Comic Sans MS')),
                                              onPressed: () {
                                                // Open the chatbot UI for this lesson
                                                _teachLesson(name, widget.subjectName);
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: subjectColor,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(vertical: 12),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(10),
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
                            ),
                          ),
                        );
                      },
                      childCount: lessons.length,
                    ),
                  );
                },
              ),

              // Bottom spacing
              SliverToBoxAdapter(child: SizedBox(height: 30)),
            ],
          ),
        ],
      ),
 
    );
  }

  // =========================
  //  Quick Actions Widget
  // =========================

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade700,
              fontFamily: 'Comic Sans MS',
            ),
          ),
        ],
      ),
    );
  }
}
