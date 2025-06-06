import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'view_models/authentication_view_model.dart';
import 'view_models/chatbot_viewmodel.dart';
import 'services/chatbot_service.dart';
import 'ui/AuthPage.dart';
import 'ui/chat_page.dart';

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
        debugShowCheckedModeBanner: false,
        title: 'Chatbot App',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),

        // ------------- IMPORTANT: Add these for Arabic -------------
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('ar', ''), // For Arabic
          Locale('en', ''), // For English (or any others you need)
        ],
        // -----------------------------------------------------------
       home: AuthPage(),//ChatPage(threadId: "default-thread-id"),

      ),
    );
  }
}
