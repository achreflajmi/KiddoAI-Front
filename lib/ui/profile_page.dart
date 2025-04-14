import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottie/lottie.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../widgets/bottom_nav_bar.dart';
import '../models/avatar_settings.dart';
import 'WhiteboardScreen.dart';

class ProfilePage extends StatefulWidget {
  final String threadId;
  const ProfilePage({super.key, required this.threadId});

  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _dobController;

  late AnimationController _animationController;
  late Animation<double> _avatarScale;

  String _selectedAvatar = AvatarSettings.defaultImagePath;
  String _selectedAvatarName = AvatarSettings.defaultAvatarName;
  String _selectedVoicePath = AvatarSettings.defaultVoicePath;

  final ImagePicker _picker = ImagePicker();
  String? _recognizedText;
  bool _isProcessing = false;

  final List<Map<String, dynamic>> _avatars = [
    {
      'name': 'SpongeBob',
      'imagePath': 'assets/avatars/spongebob.png',
      'voicePath': 'assets/voices/spongebob.wav',
      'color': Color(0xFFFFEB3B),
      'gradient': [Color.fromARGB(255, 206, 190, 46), Color(0xFFFFF9C4)],
    },
    {
      'name': 'Gumball',
      'imagePath': 'assets/avatars/gumball.png',
      'voicePath': 'assets/voices/gumball.wav',
      'color': Color(0xFF2196F3),
      'gradient': [Color.fromARGB(255, 48, 131, 198), Color(0xFFE3F2FD)],
    },
    {
      'name': 'SpiderMan',
      'imagePath': 'assets/avatars/spiderman.png',
      'voicePath': 'assets/voices/spiderman.wav',
      'color': Color.fromARGB(255, 227, 11, 18),
      'gradient': [Color.fromARGB(255, 203, 21, 39), Color(0xFFFFEBEE)],
    },
    {
      'name': 'HelloKitty',
      'imagePath': 'assets/avatars/hellokitty.png',
      'voicePath': 'assets/voices/hellokitty.wav',
      'color': Color(0xFFFF80AB),
      'gradient': [Color.fromARGB(255, 255, 131, 174), Color(0xFFFCE4EC)],
    },
  ];

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _dobController = TextEditingController();
    _loadProfile();
    _loadAvatarSettings();

    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _avatarScale = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _firstNameController.text = prefs.getString('nom') ?? '';
      _lastNameController.text = prefs.getString('prenom') ?? '';
      _dobController.text = prefs.getString('dateOfBirth') ?? '';
    });
  }

  Future<void> _loadAvatarSettings() async {
    final avatar = await AvatarSettings.getCurrentAvatar();
    setState(() {
      _selectedAvatarName = avatar['name']!;
      _selectedAvatar = avatar['imagePath']!;
      _selectedVoicePath = avatar['voicePath']!;
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('nom', _firstNameController.text);
      await prefs.setString('prenom', _lastNameController.text);
      await prefs.setString('dateOfBirth', _dobController.text);
      await AvatarSettings.saveAvatar(
        _selectedAvatarName,
        _selectedAvatar,
        _selectedVoicePath,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Profile updated successfully!')),
      );
    }
  }

  Future<void> _takePicture() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100, // No compression
        preferredCameraDevice: CameraDevice.rear,
      );
      if (photo != null) {
        setState(() => _isProcessing = true);
        await _processImage(File(photo.path));
      }
    } catch (e) {
      _showError('Error taking picture: $e');
    }
  }

  Future<void> _processImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://7d70-41-226-166-49.ngrok-free.app/ocr'), // ⚠️ Update with current ngrok URL
      );
      request.files.add(await http.MultipartFile.fromPath('image', imageFile.path));
      
      final response = await request.send();
      final respStr = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(respStr);
        setState(() {
          _recognizedText = jsonResponse['recognized_text'];
          _isProcessing = false;
        });
      } else {
        throw Exception('Server error: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Error processing image: $e');
      setState(() => _isProcessing = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Color _getAvatarColor() {
    return _avatars.firstWhere(
      (avatar) => avatar['imagePath'] == _selectedAvatar,
      orElse: () => {'color': Colors.green},
    )['color'];
  }

  List<Color> _getAvatarGradient() {
    return _avatars.firstWhere(
      (avatar) => avatar['imagePath'] == _selectedAvatar,
      orElse: () => {
        'gradient': [Colors.white, Colors.white]
      },
    )['gradient'];
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _dobController.text = picked.toLocal().toString().split(' ')[0];
      });
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon, Color color) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: color),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(25),
        borderSide: BorderSide(color: color, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Color mainColor = _getAvatarColor();
    final List<Color> bgGradient = _getAvatarGradient();

    return Scaffold(
      backgroundColor: bgGradient.last,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: bgGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Comic Sans MS',
                        ),
                        children: [
                          TextSpan(
                            text: 'K',
                            style: TextStyle(
                              color: _selectedAvatarName == 'SpongeBob'
                                  ? const Color.fromARGB(255, 66, 66, 66)
                                  : Colors.yellow,
                            ),
                          ),
                          TextSpan(
                              text: 'iddo',
                              style: TextStyle(color: Colors.white)),
                          TextSpan(
                            text: 'A',
                            style: TextStyle(
                              color: _selectedAvatarName == 'SpongeBob'
                                  ? const Color.fromARGB(255, 66, 66, 66)
                                  : Colors.yellow,
                            ),
                          ),
                          TextSpan(
                              text: 'i', style: TextStyle(color: Colors.white)),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                ScaleTransition(
                  scale: _avatarScale,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: mainColor, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: mainColor.withOpacity(0.4),
                          blurRadius: 10,
                          spreadRadius: 2,
                        )
                      ],
                    ),
                    padding: EdgeInsets.all(4),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundImage: AssetImage(_selectedAvatar),
                    ),
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  _selectedAvatarName,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Lottie.asset(
                  'assets/bouncing_ball.json',
                  height: 100,
                ),
                Text('Choose your character:'),
                SizedBox(height: 10),
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _avatars.length,
                    itemBuilder: (context, index) {
                      final avatar = _avatars[index];
                      final isSelected = avatar['imagePath'] == _selectedAvatar;

                      return GestureDetector(
                        onTap: () async {
                          setState(() {
                            _selectedAvatar = avatar['imagePath'];
                            _selectedAvatarName = avatar['name'];
                            _selectedVoicePath = avatar['voicePath'];
                          });
                          await AvatarSettings.saveAvatar(
                            _selectedAvatarName,
                            _selectedAvatar,
                            _selectedVoicePath,
                          );
                        },
                        child: Container(
                          margin: EdgeInsets.symmetric(horizontal: 8),
                          padding: EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? avatar['color'] : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 40,
                            backgroundImage: AssetImage(avatar['imagePath']),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 30),
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _firstNameController,
                        decoration: _buildInputDecoration('First Name', Icons.person, mainColor),
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 15),
                      TextFormField(
                        controller: _lastNameController,
                        decoration: _buildInputDecoration('Last Name', Icons.person_outline, mainColor),
                        validator: (value) => value!.isEmpty ? 'Required' : null,
                      ),
                      SizedBox(height: 15),
                      TextFormField(
                        controller: _dobController,
                        readOnly: true,
                        onTap: _selectDate,
                        decoration: _buildInputDecoration('Date of Birth', Icons.cake, mainColor),
                      ),
                      SizedBox(height: 30),
                      ElevatedButton(
                        onPressed: _saveProfile,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: mainColor,
                          elevation: 4,
                          shadowColor: mainColor.withOpacity(0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(25),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 14.0),
                          child: Text(
                            'Save Profile',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 20),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: _isProcessing ? null : _takePicture,
                              icon: Icon(Icons.camera_alt),
                              label: Text('Camera'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: mainColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _isProcessing
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => WhiteboardScreen(
                                            onImageSaved: (imagePath) {
                                              setState(() => _isProcessing = true);
                                              _processImage(File(imagePath));
                                            },
                                            avatarImagePath: _selectedAvatar,
                                            avatarColor: mainColor,
                                            avatarGradient: bgGradient,
                                          ),
                                        ),
                                      );
                                    },
                              icon: Icon(Icons.brush),
                              label: Text('Whiteboard'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: mainColor,
                                foregroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        if (_isProcessing)
                          Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: CircularProgressIndicator(),
                          ),
                        if (_recognizedText != null && !_isProcessing)
                          Padding(
                            padding: EdgeInsets.only(top: 16),
                            child: Text(
                              'Recognized Text: $_recognizedText',
                              style: TextStyle(fontSize: 16),
                              textAlign: TextAlign.center,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        threadId: widget.threadId,
        currentIndex: 3,
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _dobController.dispose();
    _animationController.dispose();
    super.dispose();
  }
}