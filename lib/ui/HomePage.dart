import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'LessonPage.dart';
import '../view_models/Lessons_ViewModel.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/SubjectService.dart';
import 'package:front_kiddoai/ui/profile_page.dart';
import '../utils/constants.dart';
import '../models/avatar_settings.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'StoryPage.dart';

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

  final TextStyle _titleTextStyle = GoogleFonts.tajawal(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  final TextStyle _subtitleTextStyle = GoogleFonts.tajawal(
    fontSize: 16,
    color: Colors.white.withOpacity(0.9),
  );
  final TextStyle _cardTitleTextStyle = GoogleFonts.tajawal(
    color: Colors.white,
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
  final TextStyle _cardDescTextStyle = GoogleFonts.tajawal(
    color: Colors.white.withOpacity(0.9),
    fontSize: 15,
  );
  final TextStyle _buttonTextStyle = GoogleFonts.tajawal(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
  final TextStyle _statusTextStyle = GoogleFonts.tajawal(
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );
  final TextStyle _logoTextStyle = GoogleFonts.fredoka(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  String _avatarName = 'SpongeBob';
  String _avatarImage = 'assets/avatars/spongebob.png';
  Color _avatarColor = const Color(0xFFFFEB3B);
  List<Color> _avatarGradient = [
    const Color.fromARGB(255, 206, 190, 46),
    const Color(0xFFFFF9C4),
  ];

  final List<Map<String, dynamic>> _avatars = [
    {
      'name': 'SpongeBob',
      'displayName': 'سبونج بوب',
      'imagePath': 'assets/avatars/spongebob.png',
      'voicePath': 'assets/voices/SpongeBob.wav',
      'color': const Color(0xFFFFEB3B),
      'gradient': [const Color.fromARGB(255, 206, 190, 46), const Color(0xFFFFF9C4)],
    },
    {
      'name': 'Gumball',
      'displayName': 'غمبول',
      'imagePath': 'assets/avatars/gumball.png',
      'voicePath': 'assets/voices/gumball.wav',
      'color': const Color(0xFF2196F3),
      'gradient': [const Color.fromARGB(255, 48, 131, 198), const Color(0xFFE3F2FD)],
    },
    {
      'name': 'SpiderMan',
      'displayName': 'سبايدرمان',
      'imagePath': 'assets/avatars/spiderman.png',
      'voicePath': 'assets/voices/spiderman.wav',
      'color': const Color.fromARGB(255, 227, 11, 18),
      'gradient': [const Color.fromARGB(255, 203, 21, 39), const Color(0xFFFFEBEE)],
    },
    {
      'name': 'HelloKitty',
      'displayName': 'هيلو كيتي',
      'imagePath': 'assets/avatars/hellokitty.png',
      'voicePath': 'assets/voices/hellokitty.wav',
      'color': const Color(0xFFFF80AB),
      'gradient': [const Color.fromARGB(255, 255, 131, 174), const Color(0xFFFCE4EC)],
    },
  ];

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
    _headerAnimationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    );
    _headerAnimationController.forward();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    );
    _subjects = SubjectService(CurrentIP + "/KiddoAI").fetchSubjects();

    _animationController.forward();
    _loadAvatarSettings();
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
          _avatarName = avatarName;
          _avatarImage = avatar['imagePath']?.toString() ?? selectedAvatar['imagePath'] as String;
          _avatarColor = Color(avatarColorValue);
          _avatarGradient = selectedAvatar['gradient'] as List<Color>;
        });
      }
    } catch (e) {
      print("SubjectsPage - Error loading avatar settings: $e");
      if (mounted) {
        setState(() {
          _avatarName = 'SpongeBob';
          _avatarImage = 'assets/avatars/spongebob.png';
          _avatarColor = const Color(0xFFFFEB3B);
          _avatarGradient = [
            const Color.fromARGB(255, 206, 190, 46),
            const Color(0xFFFFF9C4),
          ];
        });
      }
    }
  }

  final List<Color> _subjectColors = [
    Color(0xFF4CAF50),
    Color(0xFF2196F3),
    Color(0xFFF44336),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFF009688),
  ];

  int _colorIndex = 0;

  Map<String, dynamic> _getSubjectAssets(String subject) {
    Color color = _subjectColors[_colorIndex];
    _colorIndex = (_colorIndex + 1) % _subjectColors.length;

    return _subjectAssets[subject] ?? {
      'icon': Icons.school,
      'color': color,
      'animation': 'https://assets9.lottiefiles.com/packages/lf20_5tl1xxnz.json',
      'description': ''
    };
  }

  void _showStoryPromptDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String prompt = '';
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            elevation: 8,
            backgroundColor: Colors.transparent,
            child: Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _avatarGradient,
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Avatar Image
                  CircleAvatar(
                    backgroundImage: AssetImage(_avatarImage),
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  // Lottie Animation
                  Container(
                    width: 60,
                    height: 60,
                    child: Lottie.asset(
                      'assets/book_animation.json',
                      fit: BoxFit.contain,
                    ),
                  ),
                  // Title
                  Text(
                    'فكرة قصتك الممتعة!',
                    style: GoogleFonts.tajawal(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 16),
                  // TextField
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: _avatarColor.withOpacity(0.3),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      onChanged: (value) {
                        prompt = value;
                      },
                      textDirection: TextDirection.rtl,
                      style: GoogleFonts.tajawal(
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                      decoration: InputDecoration(
                        hintText: 'اكتب فكرة قصتك هنا...',
                        hintStyle: GoogleFonts.tajawal(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      maxLines: 3,
                    ),
                  ),
                  SizedBox(height: 20),
                  // Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Cancel Button
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.red.shade300, Colors.red.shade500],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.red.shade300.withOpacity(0.5),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Text(
                            'إلغاء',
                            style: GoogleFonts.tajawal(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Create Story Button
                      GestureDetector(
                        onTap: () {
                          if (prompt.isNotEmpty) {
                            _generateStory(prompt);
                            Navigator.of(context).pop();
                          }
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [Colors.green.shade400, Colors.green.shade600],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(30),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.shade300.withOpacity(0.5),
                                blurRadius: 8,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.auto_stories,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 8),
                              Text(
                                'إنشاء القصة',
                                style: GoogleFonts.tajawal(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _generateStory(String prompt) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Dialog(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(width: 20),
                  Text('جاري إنشاء القصة...'),
                ].reversed.toList(),
              ),
            ),
          ),
        );
      },
    );

    try {
      final response = await http.post(
        Uri.parse('https://76b2-165-50-113-5.ngrok-free.app/generate-story'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'prompt': prompt}),
      );

      Navigator.of(context).pop();

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final story = data['story'];
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StoryPage(
              story: story,
              threadId: widget.threadId,
              avatarImage: _avatarImage,
              avatarColor: _avatarColor,
              avatarGradient: _avatarGradient,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('فشل في إنشاء القصة')),
        );
      }
    } catch (e) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('حدث خطأ أثناء إنشاء القصة')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        backgroundColor: _avatarGradient.last,
        appBar: AppBar(
          backgroundColor: _avatarColor,
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
              AnimatedBuilder(
                animation: _headerAnimationController,
                builder: (context, child) {
                  return ClipRect(
                    child: Align(
                      alignment: Alignment.centerLeft,
                      widthFactor: _headerAnimationController.value,
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
            IconButton(
              icon: Icon(Icons.book),
              onPressed: _showStoryPromptDialog,
            ),
            Padding(
              padding: const EdgeInsets.only(left: 16),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ProfilePage(threadId: widget.threadId)),
                  ).then((_) => _loadAvatarSettings());
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
          top: false,
          child: Container(
            padding: const EdgeInsets.only(top: 90),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _avatarGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Stack(
              children: [
                Column(
                  children: [
                    Container(
                      margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
                      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            _avatarColor.withOpacity(0.8),
                            _avatarColor,
                          ],
                          begin: Alignment.topRight,
                          end: Alignment.bottomLeft,
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _avatarColor.withOpacity(0.4),
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
                                  style: _titleTextStyle,
                                  textDirection: TextDirection.rtl,
                                ),
                                SizedBox(height: 4),
                                Text(
                                  "اختر مادة ممتعة لاستكشافها",
                                  style: _subtitleTextStyle,
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
                                      color: Colors.yellow.shade100,
                                      borderRadius: BorderRadius.circular(30),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.yellow.shade200.withOpacity(0.5),
                                          blurRadius: 8,
                                          offset: Offset(0, 3),
                                        ),
                                      ],
                                    ),
                                    child: Text(
                                      " تحمّيل...",
                                      style: _statusTextStyle.copyWith(color: _avatarColor),
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
                                      style: _statusTextStyle.copyWith(color: Colors.red.shade700),
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
                                      style: _buttonTextStyle,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green.shade600,
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
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: Text(
                                      'لا توجد مواد جاهزة بعد!',
                                      style: _statusTextStyle.copyWith(color: _avatarColor),
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
                                      style: _buttonTextStyle,
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.blue.shade600,
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
                              final assets = _getSubjectAssets(subject);

                              return GestureDetector(
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => LessonsPage(subjectName: subject, threadId: widget.threadId),
                                    ),
                                  );
                                },
                                child: Container(
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        assets['color'].withOpacity(0.9),
                                        assets['color'],
                                      ],
                                      begin: Alignment.topRight,
                                      end: Alignment.bottomLeft,
                                    ),
                                    borderRadius: BorderRadius.circular(24),
                                    boxShadow: [
                                      BoxShadow(
                                        color: assets['color'].withOpacity(0.5),
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
                                            assets['icon'],
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
                                          child: Lottie.asset('assets/sparkles.json'),
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
                                                assets['icon'],
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
                                                style: _cardTitleTextStyle,
                                                textDirection: TextDirection.rtl,
                                              ),
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
                                            color: Colors.yellow.shade300,
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
                                                  color: Colors.green.shade800,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'Comic Sans MS',
                                                ),
                                                textDirection: TextDirection.rtl,
                                              ),
                                              SizedBox(width: 4),
                                              Icon(
                                                Icons.play_circle_fill,
                                                color: Colors.green.shade700,
                                                size: 14,
                                              ),
                                            ].reversed.toList(),
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
          ),
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
}