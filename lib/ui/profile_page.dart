import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../widgets/bottom_nav_bar.dart';

class ProfilePage extends StatefulWidget {
          final String threadId;
  
  ProfilePage({required this.threadId});
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _firstNameController;
  late TextEditingController _lastNameController;
  late TextEditingController _emailController;
  late TextEditingController _characterController;
  late TextEditingController _dobController;
  String? _threadId; // Store threadId for the user

  @override
  void initState() {
    super.initState();
    _firstNameController = TextEditingController();
    _lastNameController = TextEditingController();
    _emailController = TextEditingController();
    _characterController = TextEditingController();
    _dobController = TextEditingController();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _threadId = prefs.getString('threadId'); // Assuming threadId is stored
      _firstNameController.text = prefs.getString('nom') ?? '';
      _lastNameController.text = prefs.getString('prenom') ?? '';
      _emailController.text = prefs.getString('email') ?? '';
      _characterController.text = prefs.getString('favoriteCharacter') ?? '';
      _dobController.text = prefs.getString('dateOfBirth') ?? '';
    });
  }

  Future<void> _saveProfile() async {
    if (_formKey.currentState!.validate()) {
      try {
        // Prepare the user data to send to the backend
        final userData = {
          'threadId': _threadId, // Ensure this is set correctly
          'nom': _firstNameController.text,
          'prenom': _lastNameController.text,
          'email': _emailController.text,
          'favoriteCharacter': _characterController.text,
          'dateNaissance': _dobController.text,
          'IQCategory': '', // Add if needed, or fetch from somewhere
        };

        // Replace with your actual token retrieval logic
        final prefs = await SharedPreferences.getInstance();
        final token =
            prefs.getString('authToken') ?? ''; // Example token storage

        // Send PUT request to the backend
        final response = await http.put(
          Uri.parse(
              'https://8fd8-102-154-202-95.ngrok-free.app/users/updateProfile'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization':
                'Bearer $token', // Include if required by your backend
          },
          body: jsonEncode(userData),
        );

        if (response.statusCode == 200) {
          // Update local SharedPreferences as a fallback or for caching
          await prefs.setString('nom', _firstNameController.text);
          await prefs.setString('prenom', _lastNameController.text);
          await prefs.setString('favoriteCharacter', _characterController.text);
          await prefs.setString('dateOfBirth', _dobController.text);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Profile updated successfully!')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Failed to update profile: ${response.body}')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != DateTime.now()) {
      setState(() {
        _dobController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Profile'),
        backgroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _firstNameController,
                decoration: InputDecoration(labelText: 'First Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _lastNameController,
                decoration: InputDecoration(labelText: 'Last Name'),
                validator: (value) => value!.isEmpty ? 'Required' : null,
              ),
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(labelText: 'Email'),
                enabled: false, // Email shouldn't be changed
              ),
              TextFormField(
                controller: _characterController,
                decoration: InputDecoration(labelText: 'Favorite Character'),
              ),
              TextFormField(
                controller: _dobController,
                decoration: InputDecoration(labelText: 'Date of Birth'),
                onTap: () => _selectDate(context),
                readOnly: true,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF4CAF50),
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                ),
                child:
                    Text('Save Changes', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
            bottomNavigationBar: BottomNavBar(
        threadId: widget.threadId,
        currentIndex: 1,
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _characterController.dispose();
    _dobController.dispose();
    super.dispose();
  }
}