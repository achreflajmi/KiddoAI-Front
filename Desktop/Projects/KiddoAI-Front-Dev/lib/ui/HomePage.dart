import 'package:flutter/material.dart';
import 'LessonPage.dart';
import '../view_models/Lessons_ViewModel.dart';
import '../widgets/bottom_nav_bar.dart';
import '../services/SubjectService.dart';

class SubjectsPage extends StatefulWidget {
  @override
  _SubjectsPageState createState() => _SubjectsPageState();
}

class _SubjectsPageState extends State<SubjectsPage> {
  late Future<List<String>> _subjects;

  @override
  void initState() {
    super.initState();
    // Initialize the future to fetch subjects from the backend
    _subjects = SubjectService("https://8fd8-102-154-202-95.ngrok-free.app/KiddoAI").fetchSubjects(); // Use your ngrok URL or local server URL
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Subjects")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<List<String>>(
          future: _subjects,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(child: Text('No subjects available.'));
            } else {
              // subjects fetched successfully
              final subjects = snapshot.data!;

              return GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.0,
                  mainAxisSpacing: 12.0,
                  childAspectRatio: 0.85,
                ),
                itemCount: subjects.length,
                itemBuilder: (context, index) {
                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LessonsPage(subjectName: subjects[index]),
                        ),
                      );
                    },
                    child: Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      child: Center(
                        child: Text(
                          subjects[index],
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        threadId: "lol",
        currentIndex: 1, // Example: assuming SubjectsPage is at index 1
      ),
    );
  }
}
