import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:front_kiddoai/ui/LessonPage.dart';
import '../view_models/Lessons_ViewModel.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/SubjectService.dart';
import 'package:front_kiddoai/ui/profile_page.dart';
import '../utils/constants.dart';
import '../models/avatar_settings.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  String _currentAvatarName = 'سبونج بوب';
  String _currentAvatarImage = 'assets/avatars/spongebob.png';
  Color _currentAvatarColor = Color(0xFFFFEB3B);
  List<Color> _currentAvatarGradient = [Color.fromARGB(255, 206, 190, 46), Color(0xFFFFF9C4)];

  // Map of subject names to their respective icons, colors, and animations
  final Map<String, Map<String, dynamic>> _subjectAssets = {
    'الرياضيات': {
      'icon': Icons.calculate,
      'color': Color(0xFF4CAF50),
      'animation': 'https://assets9.lottiefiles.com/packages/lf20_aNHhS0.json',
      'description': 'الأرقام والألغاز'
    },
    'العلوم': {
      'icon': Icons.science,
      'color': Color(0xFF2196F3),
      'animation': 'https://assets9.lottiefiles.com/packages/lf20_rrqimc4b.json',
      'description': 'اكتشف واستكشف'
    },
    'الإنجليزية': {
      'icon': Icons.menu_book,
      'color': Color(0xFFF44336),
      'animation': 'https://assets9.lottiefiles.com/packages/lf20_5tl1xxnz.json',
      'description': 'الكلمات والقصص'
    },
    'التاريخ': {
      'icon': Icons.history_edu,
      'color': Color(0xFFFF9800),
      'animation': 'https://assets9.lottiefiles.com/packages/lf20_lmdo3jtk.json',
      'description': 'الماضي والناس'
    },
    'الفن': {
      'icon': Icons.palette,
      'color': Color(0xFF9C27B0),
      'animation': 'https://assets9.lottiefiles.com/packages/lf20_syqnfe7c.json',
      'description': 'ابتكر وتخيّل'
    },
    'الموسيقى': {
      'icon': Icons.music_note,
      'color': Color(0xFF3F51B5),
      'animation': 'https://assets9.lottiefiles.com/packages/lf20_Cc8Bsv.json',
      'description': 'الأصوات والإيقاع'
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

    _subjects = SubjectService(CurrentIP + "/KiddoAI").fetchSubjects();
    _loadAvatarSettings();

    _animationController.forward();
    _headerAnimationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _headerAnimationController.dispose();
    super.dispose();
  }

  Future<void> _loadAvatarSettings() async {
    try {
      final avatar = await AvatarSettings.getCurrentAvatar();
      final avatarName = avatar['name'] ?? 'سبونج بوب';
      print("SubjectsPage - Loaded avatar name: $avatarName"); // Debug log
      final selectedAvatar = _avatars.firstWhere(
        (a) => a['name'] == avatarName,
        orElse: () => _avatars[0],
      );
      if (mounted) {
        setState(() {
          _currentAvatarName = avatarName;
          _currentAvatarImage = avatar['imagePath'] ?? 'assets/avatars/spongebob.png';
          _currentAvatarColor = selectedAvatar['color'] as Color;
          _currentAvatarGradient = selectedAvatar['gradient'] as List<Color>;
        });
      }
    } catch (e) {
      print("SubjectsPage - Error loading avatar settings: $e");
      if (mounted) {
        setState(() {
          _currentAvatarName = 'سبونج بوب';
          _currentAvatarImage = 'assets/avatars/spongebob.png';
          _currentAvatarColor = Color(0xFFFFEB3B);
          _currentAvatarGradient = [Color.fromARGB(255, 206, 190, 46), Color(0xFFFFF9C4)];
        });
      }
    }
  }

  Map<String, dynamic> _getSubjectAssets(String subject) {
    return _subjectAssets[subject] ?? {
      'icon': Icons.school,
      'color': Color(0xFF795548),
      'animation': 'https://assets9.lottiefiles.com/packages/lf20_5tl1xxnz.json',
      'description': 'تعلّم وانمو'
    };
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: _currentAvatarGradient.last,
        appBar: AppBar(
          backgroundColor: _currentAvatarColor,
          elevation: 0,
          centerTitle: true,
          title: Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _currentAvatarColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(30),
              boxShadow: [
                BoxShadow(
                  color: _currentAvatarColor.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Image.asset(
                  _currentAvatarImage,
                  height: 30,
                ),
                SizedBox(width: 8),
                RichText(
                  text: TextSpan(
                    style: TextStyle(
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
          ),
          actions: [
            Padding(
              padding: EdgeInsets.only(left: 16),
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
                      color: _currentAvatarColor,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    backgroundImage: AssetImage(_currentAvatarImage),
                    radius: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
        body: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(_currentAvatarImage),
                    repeat: ImageRepeat.repeat,
                    opacity: 0.15,
                  ),
                ),
              ),
            ),
            Positioned(
              top: -40,
              left: -30,
              child: Image.asset(
                _currentAvatarImage,
                width: 150,
                opacity: AlwaysStoppedAnimation(0.2),
              ),
            ),
            Positioned(
              bottom: -50,
              right: -30,
              child: Image.asset(
                _currentAvatarImage,
                width: 180,
                opacity: AlwaysStoppedAnimation(0.15),
              ),
            ),
            Column(
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: _currentAvatarGradient,
                      begin: Alignment.topRight,
                      end: Alignment.bottomLeft,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: _currentAvatarColor.withOpacity(0.4),
                        blurRadius: 10,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
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
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              "نتعلم معًا!",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Comic Sans MS',
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                            SizedBox(height: 4),
                            Text(
                              "اختر مادة ممتعة لاستكشافها",
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.9),
                                fontSize: 16,
                                fontFamily: 'Comic Sans MS',
                              ),
                              textDirection: TextDirection.rtl,
                            ),
                          ],
                        ),
                      ),
                    ].reversed.toList(),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<List<String>>(
                    future: _subjects,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/loading.gif',
                                height: 180,
                              ),
                              SizedBox(height: 20),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: _currentAvatarColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(30),
                                  boxShadow: [
                                    BoxShadow(
                                      color: _currentAvatarColor.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  "السحر يتحمّل...",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _currentAvatarColor,
                                    fontFamily: 'Comic Sans MS',
                                  ),
                                  textDirection: TextDirection.rtl,
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
                              Image.asset(
                                'assets/error.png',
                                height: 180,
                              ),
                              SizedBox(height: 16),
                              Container(
                                margin: EdgeInsets.symmetric(horizontal: 32),
                                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Text(
                                  'عفوًا! مغامرة التعلم متوقفة.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red.shade700,
                                    fontFamily: 'Comic Sans MS',
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ),
                              SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _subjects = SubjectService(CurrentIP + "/KiddoAI").fetchSubjects();
                                  });
                                },
                                icon: Icon(Icons.refresh, color: Colors.white),
                                label: Text(
                                  "حاول مرة أخرى",
                                  style: TextStyle(
                                    fontFamily: 'Comic Sans MS',
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _currentAvatarColor,
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 5,
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
                              Lottie.asset(
                                'assets/empty.json',
                                height: 180,
                              ),
                              SizedBox(height: 16),
                              Container(
                                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  color: _currentAvatarColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: _currentAvatarColor.withOpacity(0.5)),
                                ),
                                child: Text(
                                  'لا توجد مواد جاهزة بعد!',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: _currentAvatarColor,
                                    fontFamily: 'Comic Sans MS',
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ),
                              SizedBox(height: 20),
                              ElevatedButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _subjects = SubjectService(CurrentIP + "/KiddoAI").fetchSubjects();
                                  });
                                },
                                icon: Icon(Icons.refresh, color: Colors.white),
                                label: Text(
                                  "تحديث المواد",
                                  style: TextStyle(
                                    fontFamily: 'Comic Sans MS',
                                    fontSize: 18,
                                    color: Colors.white,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _currentAvatarColor,
                                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  elevation: 5,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      final subjects = snapshot.data!;
                      return GridView.builder(
                        padding: EdgeInsets.fromLTRB(16, 8, 16, 16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.85,
                        ),
                        itemCount: subjects.length,
                        itemBuilder: (context, index) {
                          final subject = subjects[index];
                          final Color cardColor = _getSubjectAssets(subject)['color'] as Color;
                          final IconData subjectIcon = _getSubjectAssets(subject)['icon'] as IconData;
                          final String description = _getSubjectAssets(subject)['description'] as String;

                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => LessonsPage(subjectName: subjects[index]),
                                ),
                              );
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    cardColor.withOpacity(0.9),
                                    cardColor,
                                  ],
                                  begin: Alignment.topRight,
                                  end: Alignment.bottomLeft,
                                ),
                                borderRadius: BorderRadius.circular(24),
                                boxShadow: [
                                  BoxShadow(
                                    color: _currentAvatarColor.withOpacity(0.5),
                                    blurRadius: 10,
                                    offset: Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Stack(
                                children: [
                                  Positioned(
                                    left: -25,
                                    top: -25,
                                    child: Opacity(
                                      opacity: 0.2,
                                      child: Icon(
                                        subjectIcon,
                                        size: 110,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 10,
                                    left: 10,
                                    child: Container(
                                      width: 50,
                                      height: 50,
                                      child: Lottie.asset(
                                        'assets/sparkles.json',
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        Container(
                                          padding: EdgeInsets.all(12),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.25),
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: Colors.black.withOpacity(0.1),
                                                blurRadius: 5,
                                                offset: Offset(0, 3),
                                              ),
                                            ],
                                          ),
                                          child: Icon(
                                            subjectIcon,
                                            size: 40,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(height: 16),
                                        Container(
                                          padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                          decoration: BoxDecoration(
                                            color: Colors.white.withOpacity(0.2),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            subject,
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Comic Sans MS',
                                            ),
                                            textDirection: TextDirection.rtl,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          description,
                                          style: TextStyle(
                                            color: Colors.white.withOpacity(0.9),
                                            fontSize: 14,
                                            fontFamily: 'Comic Sans MS',
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                          textDirection: TextDirection.rtl,
                                        ),
                                      ],
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    child: Container(
                                      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: _currentAvatarColor.withOpacity(0.3),
                                        borderRadius: BorderRadius.only(
                                          topRight: Radius.circular(12),
                                          bottomLeft: Radius.circular(24),
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black.withOpacity(0.1),
                                            blurRadius: 3,
                                            offset: Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            "نبدأ التعلم",
                                            style: TextStyle(
                                              color: _currentAvatarColor,
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              fontFamily: 'Comic Sans MS',
                                            ),
                                            textDirection: TextDirection.rtl,
                                          ),
                                          SizedBox(width: 4),
                                          Icon(
                                            Icons.play_circle_fill,
                                            color: _currentAvatarColor,
                                            size: 14,
                                          ),
                                        ].reversed.toList(),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    bottom: 70,
                                    left: -20,
                                    child: Transform.scale(
                                      scale: 0.5,
                                      child: Image.asset(
                                        _currentAvatarImage,
                                        width: 80,
                                        opacity: AlwaysStoppedAnimation(0.4),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: BottomNavBar(
            threadId: widget.threadId,
            currentIndex: 1,
          ),
        ),
      ),
    );
  }

  Color _getSubjectColor(String subject, int index) {
    final subjectAssets = _getSubjectAssets(subject);
    return subjectAssets['color'] as Color;
  }

  IconData _getSubjectIcon(String subject) {
    final subjectAssets = _getSubjectAssets(subject);
    return subjectAssets['icon'] as IconData;
  }

  String _getSubjectDescription(String subject) {
    final subjectAssets = _getSubjectAssets(subject);
    return subjectAssets['description'] as String;
  }
}