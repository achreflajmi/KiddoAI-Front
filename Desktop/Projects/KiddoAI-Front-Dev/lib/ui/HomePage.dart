import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'LessonPage.dart';
import '../view_models/Lessons_ViewModel.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/SubjectService.dart';

class SubjectsPage extends StatefulWidget {
  final String threadId;

  SubjectsPage({required this.threadId});

  @override
  _SubjectsPageState createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> with TickerProviderStateMixin {
  late Future<List<String>> _subjects;
  late AnimationController _animationController;
  late AnimationController _headerAnimationController;

  // Map of subject names to their respective icons, colors, and animations
  final Map<String, Map<String, dynamic>> _subjectAssets = {
    'Math': {
      'icon': Icons.calculate,
      'color': Color(0xFF4CAF50),
      'animation': 'https://assets9.lottiefiles.com/packages/lf20_aNHhS0.json',
      'description': 'Numbers & Puzzles'
    },
    'Science': {
      'icon': Icons.science,
      'color': Color(0xFF2196F3),
      'animation': 'https://assets9.lottiefiles.com/packages/lf20_rrqimc4b.json',
      'description': 'Discover & Explore'
    },
    'English': {
      'icon': Icons.menu_book,
      'color': Color(0xFFF44336),
      'animation': 'https://assets9.lottiefiles.com/packages/lf20_5tl1xxnz.json',
      'description': 'Words & Stories'
    },
    'History': {
      'icon': Icons.history_edu,
      'color': Color(0xFFFF9800),
      'animation': 'https://assets9.lottiefiles.com/packages/lf20_lmdo3jtk.json',
      'description': 'Past & People'
    },
    'Art': {
      'icon': Icons.palette,
      'color': Color(0xFF9C27B0),
      'animation': 'https://assets9.lottiefiles.com/packages/lf20_syqnfe7c.json',
      'description': 'Create & Imagine'
    },
    'Music': {
      'icon': Icons.music_note,
      'color': Color(0xFF3F51B5),
      'animation': 'https://assets9.lottiefiles.com/packages/lf20_Cc8Bsv.json',
      'description': 'Sounds & Rhythm'
    },
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );

    _subjects = SubjectService("https://8fd8-102-154-202-95.ngrok-free.app/KiddoAI").fetchSubjects();
    
    _animationController.forward();
    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  Map<String, dynamic> _getSubjectAssets(String subject) {
    return _subjectAssets[subject] ?? {
      'icon': Icons.school,
      'color': Color(0xFF795548),
      'animation': 'https://assets9.lottiefiles.com/packages/lf20_5tl1xxnz.json',
      'description': 'Learn & Grow'
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background with subtle pattern
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              image: DecorationImage(
                image: NetworkImage('https://www.transparenttextures.com/patterns/cubes.png'),
                fit: BoxFit.cover,
                opacity: 0.05,
              ),
            ),
          ),
          
          CustomScrollView(
            physics: BouncingScrollPhysics(),
            slivers: [
              // Animated SliverAppBar
              SliverAppBar(
                expandedHeight: 200.0,
                floating: false,
                pinned: true,
                stretch: true,
                backgroundColor: Color(0xFF06C167), // Default green like original
                leading: IconButton(
                  icon: Icon(Icons.menu, color: Colors.white),
                  onPressed: () {}, // Menu action
                ),
                flexibleSpace: FlexibleSpaceBar(
                  titlePadding: EdgeInsets.only(left: 16, bottom: 16),
                  title: AnimatedBuilder(
                    animation: _headerAnimationController,
                    builder: (context, child) {
                      return Opacity(
                        opacity: _headerAnimationController.value,
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Poppins',
                            ),
                            children: [
                              TextSpan(text: 'K', style: TextStyle(color: Colors.yellow)),
                              TextSpan(text: 'iddo', style: TextStyle(color: Colors.white)),
                              TextSpan(text: 'A', style: TextStyle(color: Colors.yellow)),
                              TextSpan(text: 'I', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                            colors: [
                              Color(0xFF06C167),
                              Color(0xFF049a02),
                            ],
                          ),
                        ),
                      ),
                      Opacity(
                        opacity: 0.1,
                        child: Container(
                          decoration: BoxDecoration(
                            image: DecorationImage(
                              image: NetworkImage('https://www.transparenttextures.com/patterns/cubes.png'),
                              repeat: ImageRepeat.repeat,
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        right: -20,
                        bottom: -20,
                        child: AnimatedBuilder(
                          animation: _headerAnimationController,
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: _headerAnimationController.value * 0.1,
                              child: Opacity(
                                opacity: 0.2 * _headerAnimationController.value,
                                child: Icon(
                                  Icons.school,
                                  size: 180,
                                  color: Colors.white,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      Positioned(
                        left: 20,
                        bottom: 60,
                        child: AnimatedBuilder(
                          animation: _headerAnimationController,
                          builder: (context, child) {
                            return Transform.translate(
                              offset: Offset((1 - _headerAnimationController.value) * -50, 0),
                              child: Opacity(
                                opacity: _headerAnimationController.value,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Let's Learn",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 14,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Subjects",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  CircleAvatar(
                    backgroundColor: Colors.white,
                    radius: 20,
                    child: Icon(Icons.person, color: Color(0xFF049a02)),
                  ),
                  SizedBox(width: 16),
                ],
              ),

              // Search bar
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: "Search for subjects...",
                        hintStyle: TextStyle(color: Colors.grey.shade400),
                        prefixIcon: Icon(Icons.search, color: Color(0xFF049a02)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ),
              ),

              // Subjects heading
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 5),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(0xFF049a02).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.book,
                          color: Color(0xFF049a02),
                          size: 20,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        "My Subjects",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      Spacer(),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Color(0xFF049a02).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.filter_list,
                              color: Color(0xFF049a02),
                              size: 16,
                            ),
                            SizedBox(width: 5),
                            Text(
                              "All Grades",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF049a02),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Subjects grid
              SliverPadding(
                padding: const EdgeInsets.all(15.0),
                sliver: SliverToBoxAdapter(
                  child: FutureBuilder<List<String>>(
                    future: _subjects,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Lottie.network(
                                'https://assets9.lottiefiles.com/packages/lf20_kkhbsucc.json',
                                height: 150,
                              ),
                              SizedBox(height: 20),
                              Text(
                                "Loading your subjects...",
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (snapshot.hasError) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Lottie.network(
                                'https://assets9.lottiefiles.com/packages/lf20_qpwbiyxf.json',
                                height: 150,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'Oops! Something went wrong.',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.red.shade700,
                                ),
                              ),
                              SizedBox(height: 8),
                              Container(
                                padding: EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  'Error: ${snapshot.error}',
                                  style: TextStyle(color: Colors.red.shade700),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Lottie.network(
                                'https://assets9.lottiefiles.com/packages/lf20_wnqlfojb.json',
                                height: 150,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No subjects available yet!',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 10),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _subjects = SubjectService("https://8fd8-102-154-202-95.ngrok-free.app/KiddoAI").fetchSubjects();
                                  });
                                },
                                icon: Icon(Icons.refresh),
                                label: Text("Refresh"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF049a02),
                                  foregroundColor: Colors.white,
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      } else {
                        final subjects = snapshot.data!;
                        return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: GridView.builder(
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 15.0,
                              mainAxisSpacing: 15.0,
                              childAspectRatio: 0.85,
                            ),
                            itemCount: subjects.length,
                            itemBuilder: (context, index) {
                              final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                                CurvedAnimation(
                                  parent: _animationController,
                                  curve: Interval(
                                    (index / subjects.length) * 0.5,
                                    ((index + 1) / subjects.length) * 0.5 + 0.5,
                                    curve: Curves.easeOut,
                                  ),
                                ),
                              );

                              final subjectAssets = _getSubjectAssets(subjects[index]);

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
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      PageRouteBuilder(
                                        pageBuilder: (context, animation, secondaryAnimation) =>
                                            LessonsPage(subjectName: subjects[index]),
                                        transitionsBuilder: (context, animation, secondaryAnimation, child) {
                                          var begin = Offset(1.0, 0.0);
                                          var end = Offset.zero;
                                          var curve = Curves.easeInOut;
                                          var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
                                          return SlideTransition(
                                            position: animation.drive(tween),
                                            child: child,
                                          );
                                        },
                                      ),
                                    );
                                  },
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: subjectAssets['color'].withOpacity(0.15),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                      border: Border.all(
                                        color: subjectAssets['color'].withOpacity(0.1),
                                        width: 1,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Container(
                                          width: 70,
                                          height: 70,
                                          decoration: BoxDecoration(
                                            color: subjectAssets['color'].withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(10.0),
                                            child: Lottie.network(
                                              subjectAssets['animation'],
                                              fit: BoxFit.contain,
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 15),
                                        Text(
                                          subjects[index],
                                          style: TextStyle(
                                            color: Colors.black87,
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          subjectAssets['description'],
                                          style: TextStyle(
                                            color: Colors.grey.shade600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        SizedBox(height: 10),
                                        ElevatedButton.icon(
                                          icon: Icon(Icons.play_circle_outline, size: 18),
                                          label: Text("Start"),
                                          onPressed: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) => LessonsPage(subjectName: subjects[index]),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: subjectAssets['color'],
                                            foregroundColor: Colors.white,
                                            padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(10),
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
                        );
                      }
                    },
                  ),
                ),
              ),

              // Bottom padding
              SliverToBoxAdapter(
                child: SizedBox(height: 30),
              ),
            ],
          ),

          // Floating action button
          Positioned(
            bottom: 20,
            right: 20,
            child: FloatingActionButton(
              onPressed: () {
                // Quick actions or refresh
                setState(() {
                  _subjects = SubjectService("https://8fd8-102-154-202-95.ngrok-free.app/KiddoAI").fetchSubjects();
                });
              },
              backgroundColor: Color(0xFF06C167),
              child: Icon(Icons.refresh, color: Colors.white),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavBar(
        threadId: widget.threadId,
        currentIndex: 1,
      ),
    );
  }
}