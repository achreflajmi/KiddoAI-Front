import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/bottom_nav_bar.dart';
import 'chat_page.dart';
import 'HomePage.dart';
import '../models/avatar_settings.dart';

import 'profile_page.dart';

class HomePage extends StatefulWidget {
  final String threadId;

  HomePage({required this.threadId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // Kid-related state
  String _kidName = '';
  String _currentAvatarName = 'سبونج بوب';
  String _avatarImage = 'assets/avatars/spongebob.png';
  Color _primaryColor = const Color(0xFFFFEB3B);
  List<Color> _gradient = [const Color.fromARGB(255, 206, 190, 46), const Color(0xFFFFF9C4)];

  // Animation controller for the welcome card
  late final AnimationController _welcomeController;

  // Avatar settings
  final List<Map<String, dynamic>> _avatars = [
    {
      'name': 'سبونج بوب',
      'imagePath': 'assets/avatars/spongebob.png',
      'voicePath': 'assets/voices/SpongeBob.wav',
      'color': Color(0xFFFFEB3B),
      'gradient': [Color.fromARGB(255, 206, 190, 46), Color(0xFFFFF9C4)],
    },
    {
      'name': 'غمبول',
      'imagePath': 'assets/avatars/gumball.png',
      'voicePath': 'assets/voices/gumball.wav',
      'color': Color(0xFF2196F3),
      'gradient': [Color.fromARGB(255, 48, 131, 198), Color(0xFFE3F2FD)],
    },
    {
      'name': 'سبايدرمان',
      'imagePath': 'assets/avatars/spiderman.png',
      'voicePath': 'assets/voices/spiderman.wav',
      'color': Color.fromARGB(255, 227, 11, 18),
      'gradient': [Color.fromARGB(255, 203, 21, 39), Color(0xFFFFEBEE)],
    },
    {
      'name': 'هيلو كيتي',
      'imagePath': 'assets/avatars/hellokitty.png',
      'voicePath': 'assets/voices/hellokitty.wav',
      'color': Color(0xFFFF80AB),
      'gradient': [Color.fromARGB(255, 255, 131, 174), Color(0xFFFCE4EC)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _welcomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _loadAvatarSettings();
    _loadKidName();
  }

  @override
  void dispose() {
    _welcomeController.dispose();
    super.dispose();
  }

  Future<void> _loadKidName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _kidName = prefs.getString('prenom') ?? 'صديقي';
        });
      }
    } catch (e) {
      print("HomePage - Error loading kid name: $e");
      if (mounted) {
        setState(() {
          _kidName = 'صديقي';
        });
      }
    }
  }

  Future<void> _loadAvatarSettings() async {
    try {
      final avatar = await AvatarSettings.getCurrentAvatar();
      final avatarName = avatar['name'] ?? 'سبونج بوب';
      print("HomePage - Loaded avatar name: $avatarName"); // Debug log
      final selectedAvatar = _avatars.firstWhere(
        (a) => a['name'] == avatarName,
        orElse: () => _avatars[0],
      );
      if (mounted) {
        setState(() {
          _currentAvatarName = avatarName;
          _avatarImage = avatar['imagePath'] ?? 'assets/avatars/spongebob.png';
          _primaryColor = selectedAvatar['color'] as Color;
          _gradient = selectedAvatar['gradient'] as List<Color>;
        });
      }
    } catch (e) {
      print("HomePage - Error loading avatar settings: $e");
      if (mounted) {
        setState(() {
          _currentAvatarName = 'سبونج بوب';
          _avatarImage = 'assets/avatars/spongebob.png';
          _primaryColor = Color(0xFFFFEB3B);
          _gradient = [Color.fromARGB(255, 206, 190, 46), Color(0xFFFFF9C4)];
        });
      }
    }
  }

  // Navigation helpers
  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ChatPage(threadId: widget.threadId)),
    );
  }

  void _openSubjects() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => SubjectsPage(threadId: widget.threadId)),
    );
  }

  void _openLessons() => _openSubjects(); // Pick subject then lesson

  // Card builder
  Widget _buildNavCard({
    required String title,
    required String lottieAsset,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [_primaryColor.withOpacity(0.85), _primaryColor],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: _primaryColor.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -20,
              child: Opacity(
                opacity: 0.2,
                child: Lottie.asset(lottieAsset, width: 120, fit: BoxFit.cover),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Lottie.asset(lottieAsset, width: 100, height: 100),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontFamily: 'Comic Sans MS',
                    ),
                    textDirection: TextDirection.rtl,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _gradient.last,
        appBar: AppBar(
          backgroundColor: _primaryColor,
          elevation: 0,
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                _avatarImage,
                height: 30,
              ),
              const SizedBox(width: 8),
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Comic Sans MS',
                  ),
                  children: [
                    TextSpan(
                      text: 'K',
                      style: TextStyle(color: Colors.white),
                    ),
                    TextSpan(
                      text: 'iddo',
                      style: TextStyle(color: Colors.black),
                    ),
                    TextSpan(
                      text: 'A',
                      style: TextStyle(color: Colors.white),
                    ),
                    TextSpan(
                      text: 'i',
                      style: TextStyle(color: Colors.black),
                    ),
                  ],
                ),
              ),
            ].reversed.toList(),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilePage(threadId: widget.threadId)),
                  ).then((_) => _loadAvatarSettings());
                },
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _primaryColor,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundImage: AssetImage(_avatarImage),
                    radius: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _gradient,
              ),
            ),
            child: Column(
              children: [
                // Welcome card
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _welcomeController,
                      curve: Curves.elasticOut,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(25),
                        boxShadow: [
                          BoxShadow(
                            color: _primaryColor.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(backgroundImage: AssetImage(_avatarImage), radius: 36),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'مرحبًا، $_kidName! ✨',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Comic Sans MS',
                                color: _primaryColor,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ].reversed.toList(),
                      ),
                    ),
                  ),
                ),

                // Navigation grid
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                    children: [
                      _buildNavCard(title: 'الدردشة', lottieAsset: 'assets/chat.json', onTap: _openChat),
                      _buildNavCard(title: 'المواد', lottieAsset: 'assets/subjects.json', onTap: _openSubjects),
                      _buildNavCard(title: 'الدروس', lottieAsset: 'assets/lesson.json', onTap: _openLessons),
                    ],
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
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              topRight: Radius.circular(25),
            ),
            child: BottomNavBar(threadId: widget.threadId, currentIndex: 0),
          ),
        ),
      ),
    );
  }
}