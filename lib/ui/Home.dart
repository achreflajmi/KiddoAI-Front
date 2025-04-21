import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/bottom_nav_bar.dart';
import 'chat_page.dart';
import '../models/avatar_settings.dart';
import 'profile_page.dart';
import 'HomePage.dart';

class HomePage extends StatefulWidget {
  final String threadId;

  const HomePage({required this.threadId, super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  // Kid-related state
  String _kidName = '';
  String _currentAvatarName = 'SpongeBob';
  String _currentAvatarDisplayName = 'سبونج بوب';
  String _avatarImage = 'assets/avatars/spongebob.png';
  Color _currentAvatarColor = const Color(0xFFFFD600); // Default to SpongeBob's bright yellow

  // Animation controllers
  late final AnimationController _welcomeController;
  late final AnimationController _cardsController;
  late final List<AnimationController> _cardControllers;
  late final AnimationController _bounceController;

  // Avatar settings - updated colors to be more vibrant and child-friendly
  final List<Map<String, dynamic>> _avatars = [
    {
      'name': 'SpongeBob', // English name for lookup
      'displayName': 'سبونج بوب', // Arabic name for display
      'imagePath': 'assets/avatars/spongebob.png',
      'voicePath': 'assets/voices/SpongeBob.wav',
      'color': const Color(0xFFFFD600), // Bright yellow
    },
    {
      'name': 'Gumball',
      'displayName': 'غمبول',
      'imagePath': 'assets/avatars/gumball.png',
      'voicePath': 'assets/voices/gumball.wav',
      'color': const Color(0xFF2979FF), // Bright blue
    },
    {
      'name': 'SpiderMan',
      'displayName': 'سبايدرمان',
      'imagePath': 'assets/avatars/spiderman.png',
      'voicePath': 'assets/voices/spiderman.wav',
      'color': const Color(0xFFD50000), // Bright red
    },
    {
      'name': 'HelloKitty',
      'displayName': 'هيلو كيتي',
      'imagePath': 'assets/avatars/hellokitty.png',
      'voicePath': 'assets/voices/hellokitty.wav',
      'color': const Color(0xFFFF4081), // Bright pink
    },
  ];

  @override
  void initState() {
    super.initState();
    _welcomeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    
    _cardsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    // We only need 2 cards now
    _cardControllers = List.generate(2, (index) => 
      AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 800 + (index * 200)),
      )
    );

    // Add bouncing animation for avatar
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    
    _loadAvatarSettings();
    _loadKidName();
    
    // Sequence the animations
    _welcomeController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _cardsController.forward();
        Future.delayed(const Duration(milliseconds: 300), () {
          for (var i = 0; i < _cardControllers.length; i++) {
            Future.delayed(Duration(milliseconds: i * 200), () {
              _cardControllers[i].forward();
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _welcomeController.dispose();
    _cardsController.dispose();
    _bounceController.dispose();
    for (var controller in _cardControllers) {
      controller.dispose();
    }
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
      final avatarName = avatar['name'] ?? 'SpongeBob';
      final avatarColorValue = avatar['color'] as int? ?? 0xFFFFD600; // Cast to int
      print("HomePage - Loaded avatar name: $avatarName, color: $avatarColorValue"); // Debug log
      final selectedAvatar = _avatars.firstWhere(
        (a) => a['name'] == avatarName,
        orElse: () => _avatars[0],
      );
      if (mounted) {
        setState(() {
          _currentAvatarName = avatarName;
          _currentAvatarDisplayName = selectedAvatar['displayName'] as String;
          _avatarImage = avatar['imagePath'] ?? 'assets/avatars/spongebob.png';
          _currentAvatarColor = Color(avatarColorValue);
        });
      }
    } catch (e) {
      print("HomePage - Error loading avatar settings: $e");
      if (mounted) {
        setState(() {
          _currentAvatarName = 'SpongeBob';
          _currentAvatarDisplayName = 'سبونج بوب';
          _avatarImage = 'assets/avatars/spongebob.png';
          _currentAvatarColor = const Color(0xFFFFD600); // Default to bright yellow
        });
      }
    }
  }

  // Navigation helpers
  void _openChat() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
          ChatPage(threadId: widget.threadId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  void _openSubjects() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => 
          SubjectsPage(threadId: widget.threadId),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  // Card builder with animations - now with more playful design
  Widget _buildNavCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    required int index,
  }) {
    return AnimatedBuilder(
      animation: _cardControllers[index],
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(
            50 * (1 - _cardControllers[index].value) * (index == 0 ? 1 : -1), 
            0
          ),
          child: Opacity(
            opacity: _cardControllers[index].value,
            child: GestureDetector(
              onTap: onTap,
              child: Container(
                height: 120, // Taller cards
                margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_currentAvatarColor.withOpacity(0.85), _currentAvatarColor],
                    begin: Alignment.topRight,
                    end: Alignment.bottomLeft,
                  ),
                  borderRadius: BorderRadius.circular(30), // More rounded corners
                  boxShadow: [
                    BoxShadow(
                      color: _currentAvatarColor.withOpacity(0.5),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(30),
                    splashColor: Colors.white.withOpacity(0.3),
                    onTap: onTap,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 15),
                      child: Row(
                        children: [
                          // Fun icon with bouncy effect
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.3),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 2),
                            ),
                            child: Icon(
                              icon,
                              size: 38,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    fontSize: 22, // Larger font
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: 'Comic Sans MS',
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  subtitle,
                                  style: const TextStyle(
                                    fontSize: 14, // Slightly larger
                                    color: Colors.white,
                                    fontFamily: 'Comic Sans MS',
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                  maxLines: 2,
                                ),
                              ],
                            ),
                          ),
                          Transform.scale(
                            scale: 1.2,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.arrow_forward_ios_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white, // Clean start with white
        appBar: AppBar(
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
                height: 50, // Increased logo size
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
                              const TextSpan(
                                text: 'K',
                                style: TextStyle(color: Colors.white),
                              ),
                              TextSpan(
                                text: 'iddo ',
                                style: TextStyle(color: Colors.white.withOpacity(0.85)),
                              ),
                              const TextSpan(
                                text: 'A',
                                style: TextStyle(color: Colors.yellow),
                              ),
                              TextSpan(
                                text: 'I',
                                style: TextStyle(color: Colors.yellow.withOpacity(0.85)),
                              ),
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilePage(threadId: widget.threadId)),
                  ).then((_) {
                    _loadAvatarSettings();
                    _loadKidName();
                  });
                },
                child: Hero(
                  tag: 'profile_avatar',
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 3,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
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
            ),
          ],
        ),
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Color(0xFFF5F5F5)], // Subtle background
              ),
            ),
            child: Column(
              children: [
                // Welcome card with kid's name - now more vibrant
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 10),
                  child: ScaleTransition(
                    scale: CurvedAnimation(
                      parent: _welcomeController,
                      curve: Curves.elasticOut,
                    ),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [_currentAvatarColor.withOpacity(0.9), _currentAvatarColor],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: _currentAvatarColor.withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: AssetImage(_avatarImage), 
                            radius: 40,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  'مرحبًا، $_kidName! ✨',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Comic Sans MS',
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'أنا $_currentAvatarDisplayName، صديقك الجديد!',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontFamily: 'Comic Sans MS',
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  textAlign: TextAlign.right,
                                ),
                              ],
                            ),
                          ),
                        ].reversed.toList(),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 30),
                
                // Animated avatar (without the blue outline)
                AnimatedBuilder(
                  animation: _bounceController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 5 * _bounceController.value),
                      child: ScaleTransition(
                        scale: CurvedAnimation(
                          parent: _welcomeController,
                          curve: Curves.elasticOut,
                        ),
                        child: Container(
                          height: 160,
                          width: 160,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white,
                            boxShadow: [
                              BoxShadow(
                                color: _currentAvatarColor.withOpacity(0.4),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                            border: Border.all(
                              color: _currentAvatarColor.withOpacity(0.7),
                              width: 6,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              _avatarImage,
                              height: 160,
                              width: 160,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 40),

                // Navigation cards with improved visuals
                Expanded(
                  child: FadeTransition(
                    opacity: _cardsController,
                    child: ListView(
                      padding: const EdgeInsets.only(bottom: 24),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildNavCard(
                          title: 'الدردشة', 
                          subtitle: 'تحب تحكي مع صاحبك كيدو',
                          icon: Icons.chat_bubble_rounded,
                          onTap: _openChat,
                          index: 0,
                        ),
                        _buildNavCard(
                          title: 'المواد', 
                          subtitle: 'هيا نتعلمو مع بعضنا',
                          icon: Icons.school_rounded,
                          onTap: _openSubjects,
                          index: 1,
                        ),
                      ],
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
                blurRadius: 15,
                offset: const Offset(0, -3),
              ),
            ],
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
            child: BottomNavBar(threadId: widget.threadId, currentIndex: 0),
          ),
        ),
      ),
    );
  }
}