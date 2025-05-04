import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;

class StoryPage extends StatefulWidget {
  final String story;
  final String threadId;
  final String avatarImage;
  final Color avatarColor;
  final List<Color> avatarGradient;

  StoryPage({
    required this.story,
    required this.threadId,
    required this.avatarImage,
    required this.avatarColor,
    required this.avatarGradient,
  });

  @override
  _StoryPageState createState() => _StoryPageState();
}

class _StoryPageState extends State<StoryPage> with TickerProviderStateMixin {
  late PageController _pageController;
  double _currentPage = 0.0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _pageController.addListener(() {
      setState(() {
        _currentPage = _pageController.page ?? 0.0;
      });
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final pages = splitStoryIntoPages(widget.story);

    // Group pages into pairs for two-page layout
    final pairedPages = <List<String>>[];
    for (int i = 0; i < pages.length; i += 2) {
      final rightPage = pages[i];
      final leftPage = (i + 1 < pages.length) ? pages[i + 1] : '';
      pairedPages.add([rightPage, leftPage]);
    }

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: widget.avatarGradient.last,
        body: RotatedBox(
          quarterTurns: 3, // Rotate 90 degrees counterclockwise
          child: Column(
            children: [
              // Custom AppBar
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: widget.avatarColor,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    Text(
                      'قصتك',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontFamily: 'Comic Sans MS',
                      ),
                    ),
                    SizedBox(width: 48), // Spacer for balance
                  ],
                ),
              ),
              // PageView for story pages
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: widget.avatarGradient,
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  child: PageView.builder(
                    controller: _pageController,
                    itemCount: pairedPages.length,
                    itemBuilder: (context, index) {
                      final pair = pairedPages[index];
                      final pageProgress = (_currentPage - index).clamp(-1.0, 1.0);
                      final rotationAngle = pageProgress * math.pi / 2;

                      return Transform(
                        alignment: Alignment.center,
                        transform: Matrix4.identity()
                          ..setEntry(3, 2, 0.001) // Perspective
                          ..rotateY(rotationAngle), // Rotate around Y-axis for flip
                        child: Center(
                          child: Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.brown[200],
                              borderRadius: BorderRadius.circular(16),
                              gradient: LinearGradient(
                                colors: [
                                  Colors.brown[200]!,
                                  Colors.brown[300]!,
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 12,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                // Right Page
                                Expanded(
                                  child: Container(
                                    margin: EdgeInsets.all(5),
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(12),
                                        bottomLeft: Radius.circular(12),
                                      ),
                                      border: Border.all(
                                        color: Colors.brown[400]!,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 8,
                                          offset: Offset(-2, 2),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        // Notebook lines
                                        CustomPaint(
                                          painter: LinePainter(),
                                          size: Size.infinite,
                                        ),
                                        // Page content
                                        ClipRect(
                                          child: Padding(
                                            padding: const EdgeInsets.only(bottom: 40.0), // Space for page number
                                            child: Center(
                                              child: Text(
                                                pair[0],
                                                style: GoogleFonts.tajawal(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                  height: 2.0,
                                                  color: Colors.black87,
                                                ),
                                                textAlign: TextAlign.center,
                                                textDirection: TextDirection.rtl,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Page number
                                        Positioned(
                                          bottom: 10,
                                          left: 10,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.brown[300],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'صفحة ${index * 2 + 1}',
                                              style: GoogleFonts.tajawal(
                                                fontSize: 12,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                // Book spine
                                Container(
                                  width: 4,
                                  color: Colors.brown[400],
                                ),
                                // Left Page
                                Expanded(
                                  child: Container(
                                    margin: EdgeInsets.all(5),
                                    padding: EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(12),
                                        bottomRight: Radius.circular(12),
                                      ),
                                      border: Border.all(
                                        color: Colors.brown[400]!,
                                        width: 2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.15),
                                          blurRadius: 8,
                                          offset: Offset(2, 2),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        // Notebook lines
                                        CustomPaint(
                                          painter: LinePainter(),
                                          size: Size.infinite,
                                        ),
                                        // Page content
                                        ClipRect(
                                          child: Padding(
                                            padding: const EdgeInsets.only(bottom: 40.0), // Space for page number
                                            child: Center(
                                              child: Text(
                                                pair[1],
                                                style: GoogleFonts.tajawal(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.bold,
                                                  height: 2.0,
                                                  color: Colors.black87,
                                                ),
                                                textAlign: TextAlign.center,
                                                textDirection: TextDirection.rtl,
                                              ),
                                            ),
                                          ),
                                        ),
                                        // Page number
                                        Positioned(
                                          bottom: 10,
                                          right: 10,
                                          child: Container(
                                            padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.brown[300],
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              'صفحة ${index * 2 + 2}',
                                              style: GoogleFonts.tajawal(
                                                fontSize: 12,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> splitStoryIntoPages(String story, {int sentencesPerPage = 3}) {
    final sentenceRegExp = RegExp(r'(?<=[.!?])\s+|(?<=[.!?])$');
    final sentences = story.split(sentenceRegExp).where((s) => s.trim().isNotEmpty).toList();
    List<String> pages = [];

    for (int i = 0; i < sentences.length; i += sentencesPerPage) {
      final pageSentences = sentences.skip(i).take(sentencesPerPage).toList();
      if (pageSentences.isNotEmpty) {
        pages.add(pageSentences.join(' ').trim());
      }
    }

    // Handle any remaining sentences
    if (sentences.length % sentencesPerPage != 0) {
      final remainingSentences = sentences.skip(pages.length * sentencesPerPage).toList();
      if (remainingSentences.isNotEmpty) {
        pages.add(remainingSentences.join(' ').trim());
      }
    }

    return pages;
  }
}

// Custom painter for notebook lines
class LinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[300]!
      ..strokeWidth = 1;

    const lineSpacing = 40.0; // Space between lines, adjusted for large text
    for (double y = lineSpacing; y < size.height - lineSpacing / 2; y += lineSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
