import 'package:flutter/material.dart';
import '../models/message.dart';

class MessageBubble extends StatelessWidget {
  final Message message;
  final int index;
  final int messagesCount;
  final Function(String) onTapBotMessage;

  const MessageBubble({
    Key? key,
    required this.message,
    required this.index,
    required this.messagesCount,
    required this.onTapBotMessage,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isUser = message.sender == 'user';
    final isLastMessage = index == messagesCount - 1;
    final showTimestamp = isLastMessage || 
                          (index + 1 < messagesCount &&
                           message.sender != (isUser ? 'bot' : 'user'));

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            GestureDetector(
              onTap: () => onTapBotMessage(message.content),
              child: CircleAvatar(
                backgroundImage: AssetImage('assets/spongebob.png'),
                radius: 16,
              ),
            ),
            SizedBox(width: 8),
          ],
          Flexible(
            child: GestureDetector(
              onTap: !isUser ? () => onTapBotMessage(message.content) : null,
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isUser ? Color(0xFF4CAF50) : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: isUser ? Radius.circular(20) : Radius.circular(4),
                    bottomRight: isUser ? Radius.circular(4) : Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 5,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.content,
                      style: TextStyle(
                        color: isUser ? Colors.white : Colors.black87,
                        fontSize: 16,
                        height: 1.4,
                      ),
                    ),
                    if (showTimestamp)
                      Padding(
                        padding: EdgeInsets.only(top: 6),
                        child: Text(
                          "${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}",
                          style: TextStyle(
                            color: isUser ? Colors.white.withOpacity(0.7) : Colors.black54,
                            fontSize: 10,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}