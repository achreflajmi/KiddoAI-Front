// Enhanced Bottom Navigation Bar with Themed Avatars and Correct Selection
import 'package:flutter/material.dart';
import '../ui/chat_page.dart';
import '../ui/HomePage.dart';
import '../ui/profile_page.dart';
import '../ui/iq_test_screen.dart';
import '../models/avatar_settings.dart';

class BottomNavBar extends StatelessWidget {
  final String threadId;
  final int currentIndex;

  const BottomNavBar({
    super.key,
    required this.threadId,
    required this.currentIndex,
  });

  Future<Map<String, dynamic>> _getAvatarTheme() async {
    final avatar = await AvatarSettings.getCurrentAvatar();
    switch (avatar['name']) {
      case 'SpongeBob':
        return {
          'color': Color(0xFFFFEB3B),
          'activeColor': Color(0xFFFFC107),
        };
      case 'Gumball':
        return {
          'color': Color(0xFF2196F3),
          'activeColor': Color(0xFF1976D2),
        };
      case 'SpiderMan':
        return {
          'color': Color(0xFFE51C23),
          'activeColor': Color(0xFFB71C1C),
        };
      case 'HelloKitty':
        return {
          'color': Color(0xFFFF80AB),
          'activeColor': Color(0xFFF50057),
        };
      default:
        return {
          'color': Colors.grey,
          'activeColor': Colors.teal,
        };
    }
  }

  void _handleNavigation(int index, BuildContext context) {
    if (index == currentIndex) return;

    Widget page;
    switch (index) {
      case 0:
        page = IQTestScreen(threadId: threadId);
        break;
      case 1:
        page = SubjectsPage(threadId: threadId);
        break;
      case 2:
        page = ChatPage(threadId: threadId);
        break;
      case 3:
        page = ProfilePage(threadId: threadId);
        break;
      default:
        return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _getAvatarTheme(),
      builder: (context, snapshot) {
        final themeColor =
            snapshot.data != null ? snapshot.data!['color'] : Colors.grey;
        final activeColor =
            snapshot.data != null ? snapshot.data!['activeColor'] : Colors.blue;

        return Container(
          decoration: BoxDecoration(
            color: themeColor.withOpacity(0.1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(Icons.home_rounded, 0, context, activeColor),
                  _buildNavItem(
                      Icons.show_chart_rounded, 1, context, activeColor),
                  _buildNavItem(
                      Icons.chat_bubble_rounded, 2, context, activeColor),
                  _buildNavItem(Icons.person, 3, context, activeColor),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNavItem(
      IconData icon, int index, BuildContext context, Color activeColor) {
    final isActive = index == currentIndex;

    return GestureDetector(
      onTap: () => _handleNavigation(index, context),
      child: AnimatedContainer(
        duration: Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withOpacity(0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? activeColor : Colors.grey[600],
              size: isActive ? 26 : 22,
            ),
            if (isActive)
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                margin: const EdgeInsets.only(top: 4),
                height: 4,
                width: 4,
                decoration: BoxDecoration(
                  color: activeColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
