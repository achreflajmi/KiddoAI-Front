import 'package:flutter/material.dart';

class MessageBubble extends StatelessWidget {
  final String sender;
  final String message;

  MessageBubble({required this.sender, required this.message});

  @override
  Widget build(BuildContext context) {
    bool isUser = sender == 'user';
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Align(
        alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
          decoration: BoxDecoration(
            color: isUser ? Colors.blue : Colors.green,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            message,
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
