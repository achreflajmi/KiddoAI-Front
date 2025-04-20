import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/bottom_nav_bar.dart';
import 'chat_page.dart';
import 'HomePage.dart';
import 'LessonPage.dart';
import '../models/avatar_settings.dart';

class HomePage extends StatefulWidget {
  final String threadId;

  HomePage({required this.threadId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // Kid‑related state ---------------------------------------------------------
  String _kidName = '';
  String _avatarImage = 'assets/avatars/spongebob.png';
  Color _primaryColor = const Color(0xFFFFEB3B);
  List<Color> _gradient = [const Color(0xFFFFF59D), const Color(0xFFFFEB3B)];

  // Animation controller for the welcome card
  late final AnimationController _welcomeController;

  @override
  void initState() {
    super.initState();
    _welcomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _loadKidInfo();
  }

  @override
  void dispose() {
    _welcomeController.dispose();
    super.dispose();
  }

  Future<void> _loadKidInfo() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _kidName = prefs.getString('prenom') ?? 'صديقي'; // "Friend" in Arabic
    });

    final avatar = await AvatarSettings.getCurrentAvatar();
    setState(() {
      _avatarImage = avatar['imagePath'] ?? _avatarImage;
      _primaryColor = (avatar['color'] as Color?) ?? _primaryColor;
      _gradient = (avatar['gradient'] is List)
          ? (avatar['gradient'] as List).cast<Color>()
          : _gradient;
    });
  }

  // Navigation helpers --------------------------------------------------------

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

  void _openLessons() => _openSubjects(); // pick subject then lesson

  // Card builder --------------------------------------------------------------

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

  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _gradient.last,
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
                // Welcome card ------------------------------------------------
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
                            color: Colors.black.withOpacity(0.1),
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
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Comic Sans MS',
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ].reversed.toList(),
                      ),
                    ),
                  ),
                ),

                // Navigation grid -------------------------------------------
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
        bottomNavigationBar: BottomNavBar(threadId: widget.threadId, currentIndex: 0),
      ),
    );
  }
}
