import 'dart:math' as math; // Needed for max() in progress calculation

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart'; // Keep if needed for future effects
import 'package:shared_preferences/shared_preferences.dart';
import '../widgets/bottom_nav_bar.dart';
import 'chat_page.dart'; // Needed for BottomNavBar potentially
import '../models/avatar_settings.dart';
import 'profile_page.dart';
import 'HomePage.dart'; // Assuming this is the correct path for Subjects/other pages referenced by BottomNavBar

// --- Data Structure for Achievements (Static for now) ---
class Achievement {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool unlocked;

  Achievement({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    this.unlocked = true, // Assume unlocked for static display
  });
}

// --- HomePage Widget ---
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
  String _avatarImage = 'assets/avatars/spongebob.png';
  Color _currentAvatarColor = const Color(0xFFFFEB3B);
  List<Color> _currentAvatarGradient = [
    const Color.fromARGB(255, 206, 190, 46),
    const Color(0xFFFFF9C4)
  ];

  // --- Static Achievement Data ---
  // (Keep your existing achievement data)
  final List<Achievement> _achievements = [
    Achievement(
      title: 'المستكشف الأول',
      description: 'أكملت أول درس لك بنجاح!',
      icon: Icons.explore_rounded,
      color: Colors.greenAccent.shade400,
      unlocked: true,
    ),
    Achievement(
      title: 'بطل الرياضيات',
      description: 'حصلت على 5 نجوم في تحدي الجمع.',
      icon: Icons.star_rounded,
      color: Colors.blueAccent.shade400,
      unlocked: true,
    ),
    Achievement(
      title: 'راوي القصص',
      description: 'استمعت إلى 3 قصص ممتعة.',
      icon: Icons.menu_book_rounded,
      color: Colors.orangeAccent.shade400,
      unlocked: true,
    ),
    Achievement(
      title: 'صديق كيدو',
      description: 'أجريت أول محادثة مع صديقك الذكي.',
      icon: Icons.chat_bubble_rounded,
      color: Colors.purpleAccent.shade400,
      unlocked: true,
    ),
    Achievement(
      title: 'الفضولي الصغير',
      description: 'طرحت 10 أسئلة ذكية!',
      icon: Icons.lightbulb_rounded,
      color: Colors.yellowAccent.shade700,
      unlocked: false, // Example of a locked achievement
    ),
    Achievement(
      title: 'فنان الألوان',
      description: 'أكملت تحدي تلوين الأشكال.',
      icon: Icons.color_lens_rounded,
      color: Colors.pinkAccent.shade400,
      unlocked: true,
    ),
    Achievement(
      title: 'المتعلم اليومي',
      description: 'استخدمت التطبيق 3 أيام متتالية.',
      icon: Icons.calendar_today_rounded,
      color: Colors.tealAccent.shade400,
      unlocked: false, // Example of a locked achievement
    ),
     Achievement(
      title: 'خبير الحروف',
      description: 'تعرفت على جميع الحروف الهجائية!',
      icon: Icons.abc_rounded,
      color: Colors.redAccent.shade400,
      unlocked: true,
    ),
  ];

  // --- Avatar settings ---
  // (Keep your existing avatar data)
  final List<Map<String, dynamic>> _avatars = [
     {
      'name': 'SpongeBob',
      'displayName': 'سبونج بوب',
      'imagePath': 'assets/avatars/spongebob.png',
      'color': const Color(0xFFFFEB3B),
      'gradient': [const Color.fromARGB(255, 206, 190, 46), const Color(0xFFFFF9C4)],
    },
    {
      'name': 'Gumball',
      'displayName': 'غمبول',
      'imagePath': 'assets/avatars/gumball.png',
      'color': const Color(0xFF2196F3),
      'gradient': [const Color.fromARGB(255, 48, 131, 198), const Color(0xFFE3F2FD)],
    },
    // Add other avatars if needed...
  ];

  @override
  void initState() {
    super.initState();
    _loadAvatarSettings();
    _loadKidName();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadKidName() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          // Use a friendly fallback if name is empty or null
          _kidName = prefs.getString('prenom')?.isNotEmpty ?? false
              ? prefs.getString('prenom')!
              : 'صديقي';
        });
      }
    } catch (e) {
      print("HomePage - Error loading kid name: $e");
      if (mounted) {
        setState(() {
          _kidName = 'صديقي'; // Fallback name
        });
      }
    }
  }


  Future<void> _loadAvatarSettings() async {
     try {
      final avatar = await AvatarSettings.getCurrentAvatar();
      final avatarName = avatar['name']?.toString() ?? 'SpongeBob';
      final selectedAvatar = _avatars.firstWhere(
        (a) => a['name'] == avatarName,
        orElse: () => _avatars[0],
      );

      int avatarColorValue;
      if (avatar['color'] is int) {
        avatarColorValue = avatar['color'] as int;
      } else if (avatar['color'] is String) {
        String colorString = avatar['color'] as String;
        if (colorString.startsWith('0x')) {
          colorString = colorString.replaceFirst('0x', '');
        }
        avatarColorValue = int.tryParse(colorString, radix: 16) ?? (selectedAvatar['color'] as Color).value;
      } else {
        avatarColorValue = (selectedAvatar['color'] as Color).value;
      }

      if (mounted) {
        setState(() {
          _currentAvatarName = avatarName;
          _avatarImage = avatar['imagePath']?.toString() ?? selectedAvatar['imagePath'] as String;
          _currentAvatarColor = Color(avatarColorValue);
          _currentAvatarGradient = selectedAvatar['gradient'] as List<Color>;
        });
      }
    } catch (e) {
      print("HomePage - Error loading avatar settings: $e");
       if (mounted) {
        // Set default fallback avatar if loading fails
        setState(() {
          _currentAvatarName = 'SpongeBob';
          _avatarImage = 'assets/avatars/spongebob.png';
          _currentAvatarColor = const Color(0xFFFFEB3B);
          _currentAvatarGradient = [const Color.fromARGB(255, 206, 190, 46), const Color(0xFFFFF9C4)];
        });
      }
    }
  }

  // --- Widget Builder for Achievement Card (Keep existing) ---
  Widget _buildAchievementCard(Achievement achievement) {
     return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(achievement.unlocked ? 0.85 : 0.5), // Dim if locked
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
        border: Border.all(
          color: achievement.unlocked ? achievement.color.withOpacity(0.7) : Colors.grey.withOpacity(0.5),
          width: 2.5,
        ),
      ),
      child: ClipRRect( // Clip potential overflow from Stack
          borderRadius: BorderRadius.circular(22.5), // Slightly smaller than container radius
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Background pattern (optional)
              Positioned.fill(
                  child: Container(
                      decoration: BoxDecoration(
                          gradient: LinearGradient(
                              colors: [
                                achievement.color.withOpacity(achievement.unlocked ? 0.1 : 0.05),
                                Colors.white.withOpacity(0.1),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight
                          )
                      )
                  )
              ),

              Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      achievement.unlocked ? achievement.icon : Icons.lock_outline_rounded,
                      size: 45,
                      color: achievement.unlocked ? achievement.color : Colors.grey.shade600,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      achievement.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Comic Sans MS', // Use a playful font
                        color: achievement.unlocked ? Colors.black87 : Colors.grey.shade700,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      achievement.description,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        fontFamily: 'Comic Sans MS',
                        color: achievement.unlocked ? Colors.black54 : Colors.grey.shade600,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Little star or checkmark if unlocked (optional visual flair)
              if (achievement.unlocked)
                Positioned(
                  top: 8,
                  left: 8, // Adjusted for potential RTL context
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: _currentAvatarColor.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_outline, // Or Icons.star_border_rounded
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
            ],
          ),
      ),
    );
  }

  // --- NEW: Widget Builder for Achievement Progress Bar ---
  Widget _buildAchievementProgressBar(BuildContext context) {
    final int unlockedCount = _achievements.where((a) => a.unlocked).length;
    final int totalAchievements = _achievements.isNotEmpty ? _achievements.length : 1; // Avoid division by zero
    final double progress = unlockedCount / totalAchievements;
    const double barHeight = 28.0;
    final Color progressColor = Colors.amber.shade600; // Example color
    final Color trackColor = Colors.white.withOpacity(0.3);
    final BorderRadius borderRadius = BorderRadius.circular(barHeight / 2);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30.0, vertical: 15.0),
      child: Column(
        children: [
           Text(
            '🌟 مستوى تقدمك 🌟', // Added label for clarity
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              fontFamily: 'Comic Sans MS',
              color: Colors.white.withOpacity(0.95),
               shadows: const [
                 Shadow(
                   blurRadius: 3.0,
                   color: Colors.black38,
                   offset: Offset(1.0, 1.0),
                 ),
               ]
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: barHeight,
            child: Stack(
              children: [
                // Track
                Container(
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: borderRadius,
                     boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                        spreadRadius: 1,
                      )
                    ]
                  ),
                ),
                // Progress Fill
                LayoutBuilder(
                  builder: (context, constraints) {
                    return FractionallySizedBox(
                      alignment: Alignment.centerRight, // For RTL
                      widthFactor: progress,
                      child: Container(
                        decoration: BoxDecoration(
                          // Optional: Add a subtle gradient to the progress
                          gradient: LinearGradient(
                            colors: [progressColor, Color.lerp(progressColor, Colors.yellow.shade600, 0.5)!],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          // color: progressColor, // Use gradient instead if desired
                          borderRadius: borderRadius,
                           boxShadow: [
                            BoxShadow(
                              color: progressColor.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ]
                        ),
                      ),
                    );
                  }
                ),
                // Percentage Text Overlay
                Center(
                  child: Text(
                    '${(progress * 100).toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Colors.black87, // Ensure contrast
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      fontFamily: 'Comic Sans MS',
                       shadows: [ // Subtle shadow for readability
                         Shadow(
                           blurRadius: 2.0,
                           color: Colors.white54,
                           offset: Offset(0.5, 0.5),
                         ),
                       ]
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Calculate total unlocked achievements (used in progress bar now)
    // final int unlockedCount = _achievements.where((a) => a.unlocked).length; // Moved calculation inside the builder

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: Colors.white, // Base background
        // --- AppBar (Keep Existing) ---
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
                height: 50,
              ),
              const SizedBox(width: 10),
              RichText(
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
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(left: 16), // Adjusted for RTL
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
        // --- Body ---
        body: SafeArea(
          top: false, // Since we extend body behind app bar
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.only(top: 100), // Adjust top padding below AppBar
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: _currentAvatarGradient, // Use the avatar's gradient
              ),
            ),
            // --- Main Dashboard Content ---
            child: Column(
              children: [
                // --- NEW: Welcome Message ---
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10), // Reduced vertical padding
                  child: Text(
                    'أهلاً بك يا $_kidName!', // Simple Welcome Message
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 30, // Make it prominent
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Comic Sans MS', // Kid-friendly font
                      color: Colors.white,
                      shadows: [
                         Shadow(
                           blurRadius: 6.0,
                           color: Colors.black38, // Slightly stronger shadow
                           offset: Offset(2.0, 2.0),
                        ),
                      ]
                    ),
                  ),
                ),

                // --- NEW: Horizontal Achievement Progress Bar ---
                _buildAchievementProgressBar(context), // Add the progress bar widget

                // --- Achievements Grid (Keep Existing) ---
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.only(left: 20, right: 20, top: 5, bottom: 10), // Adjust padding slightly
                    physics: const BouncingScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 18,
                      mainAxisSpacing: 18,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: _achievements.length,
                    itemBuilder: (context, index) {
                      return _buildAchievementCard(_achievements[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
         // --- Bottom Navigation Bar (Keep Existing) ---
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
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
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