import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'ui/signup_page.dart'; // Import signup page
import 'ui/login_page.dart'; // Import login page
import 'view_models/authentication_view_model.dart';
import 'view_models/chatbot_viewmodel.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthenticationViewModel()),
        ChangeNotifierProvider(create: (_) => ChatbotViewModel()),
      ],
      child: MaterialApp(
        title: 'Chatbot App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: SignupPage(), // Start with SignupPage
      ),
    );
  }
}