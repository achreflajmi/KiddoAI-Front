// widgets/bottom_nav_bar.dart
import 'package:flutter/material.dart';
import '../ui/chat_page.dart';
import '../ui/webview_screen.dart';
import '../ui/HomePage.dart'; // Fixed import case
import '../ui/profile_page.dart';
import '../ui/iq_test_screen.dart';
class BottomNavBar extends StatelessWidget {
  final String threadId;
  final int currentIndex;

  const BottomNavBar({
    Key? key,
    required this.threadId,
    required this.currentIndex,
  }) : super(key: key);

  Widget _buildNavItem(IconData icon, int index, BuildContext context) {
    final isActive = index == currentIndex;
    return GestureDetector(
      onTap: () => _handleNavigation(index, context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF4CAF50).withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? const Color(0xFF4CAF50) : Colors.grey[600],
              size: 24,
            ),
            if (isActive)
              Container(
                margin: const EdgeInsets.only(top: 4),
                height: 3,
                width: 3,
                decoration: const BoxDecoration(
                  color: Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
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
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
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
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNavItem(Icons.home_rounded, 0, context),
              _buildNavItem(Icons.show_chart_rounded, 1, context),
              _buildNavItem(Icons.chat_bubble_rounded, 2, context),
              _buildNavItem(Icons.person, 3, context),
            ],
          ),
        ),
      ),
    );
  }
}