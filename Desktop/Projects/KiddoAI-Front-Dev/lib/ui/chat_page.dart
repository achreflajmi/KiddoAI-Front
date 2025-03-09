// ui/chat_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lottie/lottie.dart';
import 'dart:ui';
import '../view_models/chatbot_viewmodel.dart'; // Fixed import path
import '../services/chatbot_service.dart';
import '../widgets/bottom_nav_bar.dart';
import 'profile_page.dart';
import '../models/message.dart';

class ChatPage extends StatefulWidget {
  final String threadId;
  const ChatPage({Key? key, required this.threadId}) : super(key: key);

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> with TickerProviderStateMixin {
  late final ChatViewModel _viewModel;
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;
  late Animation<double> _microphoneScaleAnimation;

  @override
  void initState() {
    super.initState();
    _viewModel = ChatViewModel(ChatbotService());
    _viewModel.initialize();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _microphoneScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _controller.addListener(() {
      _viewModel.onTextChanged(_controller.text);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Widget _buildMessage(Message message, int index) {
    final isUser = message.sender == 'user';
    final isLastMessage = index == _viewModel.messages.length - 1;
    final showTimestamp = isLastMessage || 
        (index + 1 < _viewModel.messages.length &&
         _viewModel.messages[index + 1].sender != message.sender);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              backgroundImage: AssetImage('assets/spongebob.png'),
              radius: 16,
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFF4CAF50) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: isUser ? const Radius.circular(20) : const Radius.circular(4),
                  bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
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
                      padding: const EdgeInsets.only(top: 6),
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<ChatViewModel>(
        builder: (context, viewModel, child) {
          if (viewModel.isLoading || widget.threadId.isEmpty) {
            return Scaffold(
              body: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF4CAF50), Color(0xFF8BC34A)],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      LottieBuilder.network(
                        'https://assets9.lottiefiles.com/packages/lf20_kkhbsucc.json',
                        height: 180,
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Text(
                          "Loading your magical chat...",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4CAF50),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          return Scaffold(
            backgroundColor: const Color(0xFFF6F8FF),
            appBar: PreferredSize(
              preferredSize: const Size.fromHeight(70),
              child: AppBar(
                backgroundColor: const Color(0xFF4CAF50),
                elevation: 0,
                centerTitle: true,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(25),
                    bottomRight: Radius.circular(25),
                  ),
                ),
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/spongebob.png',
                      height: 40,
                      width: 40,
                    ),
                    const SizedBox(width: 10),
                    RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Comic Sans MS',
                        ),
                        children: [
                          TextSpan(text: 'K', style: TextStyle(color: Colors.yellow)),
                          TextSpan(text: 'iddo', style: TextStyle(color: Colors.white)),
                          TextSpan(text: 'A', style: TextStyle(color: Colors.yellow)),
                          TextSpan(text: 'i', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfilePage(threadId: viewModel.threadId),
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.yellow, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const CircleAvatar(
                          backgroundImage: AssetImage('assets/spongebob.png'),
                          radius: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            body: Stack(
              children: [
                Positioned.fill(
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/spongebob.png'),
                        fit: BoxFit.contain,
                        opacity: 0.05,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: Container(
                    margin: const EdgeInsets.only(top: 175, bottom: 85),
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(23),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.only(top: 15, bottom: 15),
                          itemCount: viewModel.messages.length,
                          itemBuilder: (context, index) {
                            WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
                            return _buildMessage(viewModel.messages[index], index);
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  top: 5,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                            border: Border.all(
                              color: viewModel.isRecording
                                  ? Colors.red
                                  : viewModel.isSending
                                      ? Colors.blue
                                      : Colors.yellow,
                              width: 3,
                            ),
                          ),
                          child: Stack(
                            children: [
                              ClipOval(
                                child: Image.asset(
                                  'assets/spongebob.png',
                                  fit: BoxFit.cover,
                                  width: 130,
                                  height: 130,
                                ),
                              ),
                              if (viewModel.isRecording || viewModel.isSending)
                                Positioned.fill(
                                  child: ClipOval(
                                    child: Lottie.network(
                                      'https://assets1.lottiefiles.com/packages/lf20_vctzcozn.json',
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          margin: const EdgeInsets.only(top: 10),
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(25),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 5,
                                offset: const Offset(0, 2),
                              ),
                            ],
                            border: Border.all(
                              color: viewModel.isRecording
                                  ? Colors.red.withOpacity(0.5)
                                  : viewModel.isSending
                                      ? Colors.blue.withOpacity(0.5)
                                      : const Color(0xFF4CAF50).withOpacity(0.5),
                              width: 2,
                            ),
                          ),
                          child: viewModel.isRecording
                              ? Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    LottieBuilder.network(
                                      'https://assets3.lottiefiles.com/packages/lf20_tzjnbj0d.json',
                                      width: 30,
                                      height: 30,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      "I'm listening... ${viewModel.recordingDuration}",
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        fontFamily: 'Comic Sans MS',
                                      ),
                                    ),
                                  ],
                                )
                              : viewModel.isSending
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        LottieBuilder.network(
                                          'https://assets9.lottiefiles.com/packages/lf20_nw19osms.json',
                                          width: 30,
                                          height: 30,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "Hmm, let me think...",
                                          style: TextStyle(
                                            color: Colors.blue,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            fontFamily: 'Comic Sans MS',
                                          ),
                                        ),
                                      ],
                                    )
                                  : Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Image.asset(
                                          'assets/spongebob.png',
                                          width: 24,
                                          height: 24,
                                        ),
                                        const SizedBox(width: 8),
                                        const Text(
                                          "Let's have fun learning!",
                                          style: TextStyle(
                                            color: Color(0xFF4CAF50),
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                            fontFamily: 'Comic Sans MS',
                                          ),
                                        ),
                                      ],
                                    ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.9),
                          Colors.white,
                        ],
                      ),
                    ),
                    child: SafeArea(
                      top: false,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        child: Material(
                          elevation: 4,
                          borderRadius: BorderRadius.circular(30),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  Colors.white,
                                  Color(0xFFE8F5E9),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(30),
                              border: Border.all(
                                color: viewModel.isRecording
                                    ? Colors.red
                                    : viewModel.isTyping
                                        ? const Color(0xFF4CAF50)
                                        : Colors.transparent,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onLongPressStart: (_) {
                                    viewModel.startRecording();
                                    _animationController.repeat(reverse: true);
                                  },
                                  onLongPressEnd: (_) {
                                    viewModel.stopRecording();
                                    _animationController.stop();
                                  },
                                  child: Container(
                                    width: 50,
                                    height: 50,
                                    margin: const EdgeInsets.only(right: 8),
                                    decoration: BoxDecoration(
                                      color: viewModel.isRecording
                                          ? Colors.red.withOpacity(0.1)
                                          : const Color(0xFF4CAF50).withOpacity(0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: AnimatedBuilder(
                                      animation: _animationController,
                                      builder: (context, child) {
                                        return Transform.scale(
                                          scale: viewModel.isRecording
                                              ? 1.0 + 0.2 * _microphoneScaleAnimation.value
                                              : 1.0,
                                          child: Icon(
                                            viewModel.isRecording ? Icons.stop : Icons.mic,
                                            color: viewModel.isRecording
                                                ? Colors.red
                                                : const Color(0xFF4CAF50),
                                            size: 28,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: TextField(
                                    controller: _controller,
                                    decoration: InputDecoration(
                                      hintText: viewModel.isRecording
                                          ? 'Listening to you...'
                                          : 'Type your message to SpongeBob...',
                                      border: InputBorder.none,
                                      hintStyle: TextStyle(
                                        color: viewModel.isRecording
                                            ? Colors.red.withOpacity(0.6)
                                            : Colors.grey[600],
                                        fontFamily: 'Comic Sans MS',
                                        fontSize: 16,
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontFamily: 'Comic Sans MS',
                                    ),
                                    maxLines: null,
                                    enabled: !viewModel.isRecording,
                                  ),
                                ),
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: _controller.text.isNotEmpty
                                        ? const Color(0xFF4CAF50)
                                        : const Color(0xFFE0E0E0),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: Icon(
                                      Icons.send_rounded,
                                      color: _controller.text.isNotEmpty
                                          ? Colors.white
                                          : Colors.grey[400],
                                    ),
                                    iconSize: 24,
                                    onPressed: () {
                                      if (_controller.text.isNotEmpty) {
                                        viewModel.sendTextMessage(_controller.text);
                                        _controller.clear();
                                      }
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            bottomNavigationBar: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(25),
                  topRight: Radius.circular(25),
                ),
                child: BottomNavBar(
                  threadId: widget.threadId,
                  currentIndex: 2,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}