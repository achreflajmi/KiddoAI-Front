import 'package:flutter/material.dart';
import 'LessonPage.dart';
import '../view_models/Lessons_ViewModel.dart';
import '../widgets/bottom_nav_bar.dart';


class SubjectsPage extends StatelessWidget {
  final List<String> subjects = ["Maths", "Science", "Literature", "History"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Subjects")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
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

        ),
      ),
      bottomNavigationBar: BottomNavBar(
        threadId: "lol",
        currentIndex: 1, // Example: assuming SubjectsPage is at index 1
      ),
    );
  }
  
}
