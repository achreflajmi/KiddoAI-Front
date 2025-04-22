import 'package:flutter/material.dart';
import 'package:signature/signature.dart';
import 'dart:ui' as ui;
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class WhiteboardScreen extends StatefulWidget {
  final Function(String imagePath) onImageSaved;
  final String avatarImagePath;
  final Color avatarColor;
  final List<Color> avatarGradient;

  const WhiteboardScreen({
    required this.onImageSaved,
    required this.avatarImagePath,
    required this.avatarColor,
    required this.avatarGradient,
  });

  @override
  _WhiteboardScreenState createState() => _WhiteboardScreenState();
}

class _WhiteboardScreenState extends State<WhiteboardScreen> with SingleTickerProviderStateMixin {
  final SignatureController _controller = SignatureController(
    penStrokeWidth: 6,
    penColor: Colors.black,
    exportBackgroundColor: Colors.white,
  );

  late AnimationController _animationController;
  late Animation<double> _buttonScale;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 800),
    )..repeat(reverse: true);

    _buttonScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

 Future<void> _saveDrawing() async {
  final image = await _controller.toImage();
  if (image == null) return;

  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  final tempDir = await getTemporaryDirectory();
  final file = File('${tempDir.path}/drawing_${DateTime.now().millisecondsSinceEpoch}.png');
  await file.writeAsBytes(bytes!.buffer.asUint8List());

  widget.onImageSaved(file.path);
  Navigator.pop(context);
}


  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl, // Added for RTL
      child: Scaffold(
        backgroundColor: widget.avatarGradient.last,
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: widget.avatarGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                // Custom App Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: AssetImage(widget.avatarImagePath),
                        backgroundColor: widget.avatarColor.withOpacity(0.2),
                      ),
                      Text(
                        '🖍️ سبورة KiddoAI', // Translated: Kiddo AI Whiteboard
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Comic Sans MS',
                        ),
                        textDirection: TextDirection.rtl,
                      ),
                    ].reversed.toList(), // Reversed for RTL
                  ),
                ),
                SizedBox(height: 10),
                // Drawing Area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: widget.avatarColor.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            final height = constraints.maxHeight;
                            return Stack(
                              children: [
                                // Signature Area
                                Signature(
                                  controller: _controller,
                                  backgroundColor: Colors.white,
                                ),
                                // Guide Lines
                                for (var i = 1; i < 4; i++)
                                  Positioned(
                                    top: height * (i / 4),
                                    left: 0,
                                    right: 0,
                                    child: Divider(
                                      color: widget.avatarColor.withOpacity(0.3),
                                      thickness: 1.5,
                                      indent: 16,
                                      endIndent: 16,
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      ScaleTransition(
                        scale: _buttonScale,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: widget.avatarColor,
                            side: BorderSide(color: widget.avatarColor, width: 2),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            backgroundColor: Colors.white.withOpacity(0.1),
                          ),
                          onPressed: () => _controller.clear(),
                          icon: Icon(Icons.refresh),
                          label: Text(
                            "امسح", // Translated: Clear
                            style: TextStyle(fontSize: 16),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ),
                      ScaleTransition(
                        scale: _buttonScale,
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: widget.avatarColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shadowColor: widget.avatarColor.withOpacity(0.5),
                            elevation: 4,
                          ),
                          onPressed: _saveDrawing,
                          icon: Icon(Icons.send),
                          label: Text(
                            "إرسال", // Translated: Send
                            style: TextStyle(fontSize: 16, color: Colors.white),
                            textDirection: TextDirection.rtl,
                          ),
                        ),
                      ),
                    ].reversed.toList(), // Reversed for RTL
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}