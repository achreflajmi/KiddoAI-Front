import 'package:flutter/material.dart';
import 'ui/signup_page.dart'; // Import signup page
import 'ui/login_page.dart'; // Import login page

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chatbot App',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: SignupPage(), // Start with SignupPage
    );
  }
}
