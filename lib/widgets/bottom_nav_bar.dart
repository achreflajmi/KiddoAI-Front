import 'package:flutter/material.dart';
import 'package:front_kiddoai/ui/HomePage.dart';
import '../ui/chat_page.dart';
import '../ui/webview_screen.dart';

class BottomNavBar extends StatelessWidget {
  final String threadId;
  final int currentIndex;

  const BottomNavBar({
    Key? key,
    required this.threadId,
    required this.currentIndex,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      child: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            IconButton(
              icon: Icon(Icons.home_outlined),
              color: currentIndex == 0 ? Colors.blue : Colors.grey,
              onPressed: () {
                if (currentIndex != 0) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          WebViewIQTestScreen(threadId: threadId),
                    ),
                  );
                }
              },
            ),
            IconButton(
      icon: Icon(Icons.videogame_asset),
      color: currentIndex == 1 ? Colors.blue : Colors.grey,
      onPressed: () {
        if (currentIndex != 1) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => SubjectsPage(),
            ),
          );
        }
      },
    ),
            IconButton(
              icon: Icon(Icons.chat_bubble_outline),
              color: currentIndex == 2 ? Colors.blue : Colors.grey,
              onPressed: () {
                if (currentIndex != 2) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatPage(threadId: threadId),
                    ),
                  );
                }
              },
            ),
            IconButton(
              icon: Icon(Icons.calendar_today),
              color: Colors.grey,
              onPressed: () {},
            ),
            IconButton(
              icon: Icon(Icons.settings),
              color: Colors.grey,
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
