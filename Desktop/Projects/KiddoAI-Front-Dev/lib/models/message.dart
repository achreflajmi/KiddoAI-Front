class Message {
  final String sender;
  final String content;
  final bool showAvatar;
  final bool isAudio;
  final DateTime timestamp;

  Message({
    required this.sender,
    required this.content,
    this.showAvatar = false,
    this.isAudio = false,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'sender': sender,
      'content': content,
      'showAvatar': showAvatar,
      'isAudio': isAudio,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      sender: json['sender'],
      content: json['content'],
      showAvatar: json['showAvatar'] ?? false,
      isAudio: json['isAudio'] ?? false,
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
    );
  }
}