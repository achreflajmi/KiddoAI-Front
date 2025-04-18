import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'view_models/authentication_view_model.dart';
import 'view_models/chatbot_viewmodel.dart';
import 'services/chatbot_service.dart';
import 'ui/AuthPage.dart';
import 'ui/Iq_test_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthenticationViewModel()),
        ChangeNotifierProvider(create: (_) => ChatViewModel(ChatbotService())),
      ],
      child: MaterialApp(
        title: 'Chatbot App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home:  IQTestScreen(threadId: "thread_3eowA2qOhI50eTg4lhGcSyc7",),//AuthPage(), 
      ),
    );
  }
}
