import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:lottie/lottie.dart';
import '../services/authentication_service.dart';
import 'webview_screen.dart';

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Signup Controllers
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailSignupController = TextEditingController();
  final TextEditingController _passwordSignupController = TextEditingController();
  final TextEditingController _favoriteCharacterController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();

  // Login Controllers
  final TextEditingController _emailLoginController = TextEditingController();
  final TextEditingController _passwordLoginController = TextEditingController();

  bool _isLoading = false;
  bool _passwordVisible = false;
  bool _signupPasswordVisible = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await AuthenticationService().signup(
        _nomController.text,
        _prenomController.text,
        _emailSignupController.text,
        _passwordSignupController.text,
        _favoriteCharacterController.text,
        _dateOfBirthController.text,
      );

      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('isLoggedIn', true);
      prefs.setString('threadId', response['threadId']);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => WebViewIQTestScreen(threadId: response['threadId'])),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final response = await AuthenticationService().login(
        _emailLoginController.text,
        _passwordLoginController.text,
      );

      final prefs = await SharedPreferences.getInstance();
      prefs.setBool('isLoggedIn', true);
      String? threadId = response['threadId'];
      if (threadId != null) {
        prefs.setString('threadId', threadId);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WebViewIQTestScreen(threadId: threadId)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.background,
        body: SafeArea(
          child: Row(
            mainAxisSize: MainAxisSize.max,
            children: [
              Expanded(
                flex: 8,
                child: Container(
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.background,
                  ),
                  alignment: Alignment.topCenter,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 24), // Reduced padding
                          child: Container(
                            constraints: BoxConstraints(maxWidth: 600),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                RichText(
                                  text: TextSpan(
                                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                    children: [
                                      TextSpan(
                                        text: 'K',
                                        style: TextStyle(color: Color(0xFF049a02)),
                                      ),
                                      TextSpan(text: 'iddo'),
                                      TextSpan(
                                        text: 'A',
                                        style: TextStyle(color: Color(0xFF049a02)),
                                      ),
                                      TextSpan(text: 'i'),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 20),
                                Center(
                                  child: Lottie.network(
                                    'https://assets4.lottiefiles.com/packages/lf20_u4yrau.json',
                                    height: 150,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        Container(
                          constraints: BoxConstraints(maxWidth: 600),
                          child: Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Center(
                                  child: TabBar(
                                    controller: _tabController,
                                    labelColor: Color(0xFF049a02),
                                    unselectedLabelColor: Theme.of(context).colorScheme.secondary,
                                    indicatorColor: Colors.transparent,
                                    labelStyle: TextStyle(fontSize: 20), // Increased font size
                                    tabs: [
                                      Tab(text: 'Sign In'),
                                      Tab(text: 'Sign Up'),
                                    ],
                                  ),
                                ),
                                SizedBox(height: 20),
                                Container(
                                  height: MediaQuery.of(context).size.height - 300,
                                  child: TabBarView(
                                    controller: _tabController,
                                    children: [
                                      // Login Tab
                                      _buildLoginForm(),
                                      // Signup Tab
                                      _buildSignupForm(),
                                    ],
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Let\'s get started!',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: 24),
          _buildTextField(
            controller: _emailLoginController,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _passwordLoginController,
            label: 'Password',
            obscureText: !_passwordVisible,
            suffixIcon: IconButton(
              icon: Icon(
                _passwordVisible ? Icons.visibility : Icons.visibility_off,
                color: Theme.of(context).colorScheme.secondary,
              ),
              onPressed: () => setState(() => _passwordVisible = !_passwordVisible),
            ),
          ),
          SizedBox(height: 24),
          _buildAuthButton(
            text: 'Sign In',
            onPressed: _handleLogin,
          ),
          TextButton(
            onPressed: () {},
            child: Text(
              'Forgot Password?',
              style: TextStyle(color: Color(0xFF049a02)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignupForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Create your account',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          SizedBox(height: 24),
          _buildTextField(
            controller: _nomController,
            label: 'First Name',
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _prenomController,
            label: 'Last Name',
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _emailSignupController,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _passwordSignupController,
            label: 'Password',
            obscureText: !_signupPasswordVisible,
            suffixIcon: IconButton(
              icon: Icon(
                _signupPasswordVisible ? Icons.visibility : Icons.visibility_off,
                color: Theme.of(context).colorScheme.secondary,
              ),
              onPressed: () => setState(() => _signupPasswordVisible = !_signupPasswordVisible),
            ),
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _favoriteCharacterController,
            label: 'Favorite Character',
          ),
          SizedBox(height: 16),
          _buildTextField(
            controller: _dateOfBirthController,
            label: 'Date of Birth',
            onTap: () async {
              DateTime? pickedDate = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (pickedDate != null) {
                _dateOfBirthController.text = "${pickedDate.toLocal()}".split(' ')[0];
              }
            },
          ),
          SizedBox(height: 24),
          _buildAuthButton(
            text: 'Sign Up',
            onPressed: _handleSignup,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    VoidCallback? onTap,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onTap: onTap,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        suffixIcon: suffixIcon,
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter $label';
        }
        return null;
      },
    );
  }

  Widget _buildAuthButton({
    required String text,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF049a02),
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: _isLoading
            ? CircularProgressIndicator()
            : Text(text, style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }
}