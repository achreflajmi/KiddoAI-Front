import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../view_models/Lessons_ViewModel.dart';
import '../widgets/loading_animation_widget.dart';
import 'webview_activity_widget.dart';

class LessonsPage extends StatefulWidget {
  final String subjectName;

  const LessonsPage({super.key, required this.subjectName});

  @override
  State<LessonsPage> createState() => _LessonsPageState();
}

class _LessonsPageState extends State<LessonsPage> with TickerProviderStateMixin {
  late final LessonsViewModel _viewModel;
  late AnimationController _listAnimationController;
  late AnimationController _explanationAnimationController;
  late AnimationController _headerAnimationController;

  @override
  void initState() {
    super.initState();
    _viewModel = LessonsViewModel()..fetchLessons(widget.subjectName);

    _listAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _explanationAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _headerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
  }

  @override
  void dispose() {
    _listAnimationController.dispose();
    _explanationAnimationController.dispose();
    _headerAnimationController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Map<String, dynamic>>(
      valueListenable: ValueNotifier(_viewModel.getSubjectAttributes(widget.subjectName)),
      builder: (context, subjectAttrs, _) {
        final Color subjectColor = Color(subjectAttrs['color']);
        final IconData subjectIcon = _getIconFromString(subjectAttrs['icon']);
        final String backgroundImage = subjectAttrs['background'];

        return Scaffold(
          body: Stack(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  image: backgroundImage.isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(backgroundImage),
                          fit: BoxFit.cover,
                          opacity: 0.05,
                        )
                      : null,
                ),
              ),
              CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  _buildSliverAppBar(subjectColor, subjectIcon),
                  ValueListenableBuilder<bool>(
                    valueListenable: _viewModel.isLoading,
                    builder: (context, isLoading, _) => isLoading
                        ? _buildLoadingSliver(subjectColor)
                        : const SliverToBoxAdapter(),
                  ),
                  ValueListenableBuilder<bool>(
                    valueListenable: _viewModel.showExplanation,
                    builder: (context, showExplanation, _) => showExplanation
                        ? _buildExplanationSliver(subjectColor)
                        : const SliverToBoxAdapter(),
                  ),
                  _buildLessonsHeader(subjectColor),
                  _buildLessonsList(subjectColor),
                  const SliverToBoxAdapter(child: SizedBox(height: 30)),
                ],
              ),
              _buildFloatingActionButton(subjectColor),
            ],
          ),
        );
      },
    );
  }

  SliverAppBar _buildSliverAppBar(Color subjectColor, IconData subjectIcon) {
    return SliverAppBar(
      expandedHeight: 200.0,
      floating: false,
      pinned: true,
      stretch: true,
      backgroundColor: subjectColor,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        title: AnimatedBuilder(
          animation: _headerAnimationController,
          builder: (context, child) => Opacity(
            opacity: _headerAnimationController.value,
            child: Text(
              "${widget.subjectName} Lessons",
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                  colors: [subjectColor, subjectColor.withOpacity(0.7)],
                ),
              ),
            ),
            Opacity(
              opacity: 0.1,
              child: Container(
                decoration: const BoxDecoration(
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
                builder: (context, child) => Transform.rotate(
                  angle: _headerAnimationController.value * 0.1,
                  child: Opacity(
                    opacity: 0.2 * _headerAnimationController.value,
                    child: Icon(subjectIcon, size: 180, color: Colors.white),
                  ),
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 60,
              child: AnimatedBuilder(
                animation: _headerAnimationController,
                builder: (context, child) => Transform.translate(
                  offset: Offset((1 - _headerAnimationController.value) * -50, 0),
                  child: Opacity(
                    opacity: _headerAnimationController.value,
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(subjectIcon, size: 30, color: Colors.white),
                        ),
                        const SizedBox(width: 15),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Let's explore",
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.subjectName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.info_outline, color: Colors.white),
          onPressed: () => _showInfoDialog(subjectColor, subjectIcon),
        ),
        IconButton(
          icon: const Icon(Icons.bookmark_border, color: Colors.white),
          onPressed: () => _viewModel.bookmarkSubject(context),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  SliverToBoxAdapter _buildLoadingSliver(Color subjectColor) {
    return SliverToBoxAdapter(
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            children: [
              Lottie.network(
                'https://assets10.lottiefiles.com/packages/lf20_2LdL1k.json',
                height: 150,
                errorBuilder: (context, error, stackTrace) => CircularProgressIndicator(
                  color: subjectColor,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                "Loading your lesson...",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              Text(
                "This might take a moment",
                style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      ),
    );
  }

SliverToBoxAdapter _buildExplanationSliver(Color subjectColor) {
  return SliverToBoxAdapter(
    child: AnimatedBuilder(
      animation: _explanationAnimationController,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, (1 - _explanationAnimationController.value) * 50),
        child: Opacity(
          opacity: _explanationAnimationController.value,
          child: child,
        ),
      ),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: subjectColor.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 5))],
          border: Border.all(color: subjectColor.withOpacity(0.1), width: 1),
        ),
        child: SingleChildScrollView( // Add this
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.fromLTRB(20, 20, 10, 15),
                decoration: BoxDecoration(
                  color: subjectColor.withOpacity(0.05),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: subjectColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.lightbulb, color: subjectColor, size: 22),
                    ),
                    const SizedBox(width: 15),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Lesson Explanation",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: subjectColor),
                        ),
                        Text(
                          "Listen and learn",
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.grey.shade700),
                      onPressed: _viewModel.hideExplanation,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ValueListenableBuilder<bool>(
                      valueListenable: _viewModel.isPlayingAudio,
                      builder: (context, isPlaying, _) => isPlaying
                          ? Container(
                              margin: const EdgeInsets.only(bottom: 15),
                              padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
                              decoration: BoxDecoration(
                                color: subjectColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(color: subjectColor, shape: BoxShape.circle),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Audio playing...",
                                    style: TextStyle(
                                      color: subjectColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : const SizedBox(),
                    ),
                    ValueListenableBuilder<String>(
                      valueListenable: _viewModel.lessonExplanation,
                      builder: (context, explanation, _) => Text(
                        explanation,
                        style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 20),
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.volume_up, color: subjectColor, size: 22),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              "Audio narration",
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey),
                            ),
                          ),
                          ValueListenableBuilder<bool>(
                            valueListenable: _viewModel.isPlayingAudio,
                            builder: (context, isPlaying, _) => isPlaying
                                ? ElevatedButton.icon(
                                    icon: const Icon(Icons.pause, size: 18),
                                    label: const Text("Pause"),
                                    onPressed: _viewModel.pauseAudio,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: subjectColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  )
                                : ElevatedButton.icon(
                                    icon: const Icon(Icons.play_arrow, size: 18),
                                    label: const Text("Play"),
                                    onPressed: _viewModel.playAudio,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: subjectColor,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

  SliverToBoxAdapter _buildLessonsHeader(Color subjectColor) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 5),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: subjectColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.book, color: subjectColor, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              "Available Lessons",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: subjectColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Icon(Icons.filter_list, color: subjectColor, size: 16),
                  const SizedBox(width: 5),
                  Text(
                    "Filter",
                    style: TextStyle(fontSize: 12, color: subjectColor, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLessonsList(Color subjectColor) {
    return ValueListenableBuilder<List<Map<String, dynamic>>>(
      valueListenable: _viewModel.lessons,
      builder: (context, lessons, _) {
        if (lessons.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.network(
                    'https://assets10.lottiefiles.com/packages/lf20_wnqlfojb.json',
                    height: 150,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error, size: 50, color: Colors.red),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No lessons available yet!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: () => _viewModel.fetchLessons(widget.subjectName),
                    icon: const Icon(Icons.refresh),
                    label: const Text("Refresh"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: subjectColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final lesson = lessons[index];
              final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _listAnimationController,
                  curve: Interval(
                    (index / lessons.length) * 0.5,
                    ((index + 1) / lessons.length) * 0.5 + 0.5,
                    curve: Curves.easeOut,
                  ),
                ),
              );

              return AnimatedBuilder(
                animation: animation,
                builder: (context, child) => Transform.translate(
                  offset: Offset((1 - animation.value) * 100, 0),
                  child: Opacity(opacity: animation.value, child: child),
                ),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
                    ],
                    border: Border.all(color: Colors.grey.shade100, width: 1),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _viewModel.startActivity(context, lesson['description']),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 60,
                                  height: 60,
                                  decoration: BoxDecoration(
                                    color: subjectColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.school, color: subjectColor, size: 30),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lesson['name'],
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time, size: 14, color: Colors.grey.shade600),
                                          const SizedBox(width: 4),
                                          Text(
                                            "10-15 min",
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            width: 4,
                                            height: 4,
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade400,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          const Icon(Icons.star, size: 14, color: Colors.amber),
                                          const SizedBox(width: 4),
                                          Text(
                                            "Beginner",
                                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 15),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    icon: const Icon(Icons.play_circle_outline, size: 18),
                                    label: const Text("Start Activity"),
                                    onPressed: () => _viewModel.startActivity(context, lesson['description']),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: subjectColor,
                                      side: BorderSide(color: subjectColor),
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    icon: const Icon(Icons.lightbulb_outline, size: 18),
                                    label: const Text("Learn"),
                                    onPressed: () {
                                      _viewModel.teachLesson(lesson['name'], widget.subjectName);
                                      _explanationAnimationController.reset();
                                      _explanationAnimationController.forward();
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: subjectColor,
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
            childCount: lessons.length,
          ),
        );
      },
    );
  }

  Positioned _buildFloatingActionButton(Color subjectColor) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: FloatingActionButton(
        onPressed: () => _showQuickActions(subjectColor),
        backgroundColor: subjectColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showInfoDialog(Color subjectColor, IconData subjectIcon) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(subjectIcon, color: subjectColor),
            const SizedBox(width: 10),
            Text("About ${widget.subjectName}"),
          ],
        ),
        content: Text(
          "This section contains all the lessons for ${widget.subjectName}. "
          "Tap on 'Learn' to get an explanation or 'Start Activity' to practice what you've learned!",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Got it!"),
            style: TextButton.styleFrom(foregroundColor: subjectColor),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  void _showQuickActions(Color subjectColor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(10)),
              margin: const EdgeInsets.only(bottom: 20),
            ),
            const Text("Quick Actions", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickActionItem(
                  icon: Icons.bookmark,
                  label: "Bookmark",
                  color: Colors.blue,
                  onTap: () => _viewModel.bookmarkSubject(context),
                ),
                _buildQuickActionItem(
                  icon: Icons.share,
                  label: "Share",
                  color: Colors.green,
                  onTap: () => _viewModel.shareSubject(context),
                ),
                _buildQuickActionItem(
                  icon: Icons.help_outline,
                  label: "Help",
                  color: Colors.orange,
                  onTap: () => Navigator.pop(context), // Add help logic in ViewModel if needed
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
        ],
      ),
    );
  }

  IconData _getIconFromString(String iconName) {
    const iconMap = {
      'calculate': Icons.calculate,
      'science': Icons.science,
      'menu_book': Icons.menu_book,
      'history_edu': Icons.history_edu,
      'palette': Icons.palette,
      'music_note': Icons.music_note,
      'school': Icons.school,
    };
    return iconMap[iconName] ?? Icons.school;
  }
}