import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../view_models/authentication_view_model.dart';
import 'webview_screen.dart';

class AuthPage extends StatefulWidget {
  @override
  _AuthPageState createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> with TickerProviderStateMixin {
  late TabController _tabController;
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  // Signup Controllers
  final TextEditingController _nomController = TextEditingController();
  final TextEditingController _prenomController = TextEditingController();
  final TextEditingController _emailSignupController = TextEditingController();
  final TextEditingController _passwordSignupController = TextEditingController();
  final TextEditingController _favoriteCharacterController = TextEditingController();
  final TextEditingController _dateOfBirthController = TextEditingController();
  final TextEditingController _parentPhoneController = TextEditingController();

  // Login Controllers
  final TextEditingController _emailLoginController = TextEditingController();
  final TextEditingController _passwordLoginController = TextEditingController();

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
    _nomController.dispose();
    _prenomController.dispose();
    _emailSignupController.dispose();
    _passwordSignupController.dispose();
    _favoriteCharacterController.dispose();
    _dateOfBirthController.dispose();
    _emailLoginController.dispose();
    _passwordLoginController.dispose();
    _parentPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup(BuildContext context) async {
    if (!_signupFormKey.currentState!.validate()) return;

    final viewModel = Provider.of<AuthenticationViewModel>(context, listen: false);
    
    final response = await viewModel.signup(
      _nomController.text,
      _prenomController.text,
      _emailSignupController.text,
      _passwordSignupController.text,
      _favoriteCharacterController.text,
      _dateOfBirthController.text,
       _parentPhoneController.text,
    );

    if (response != null) {
      final threadId = response['threadId'];
      if (threadId != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WebViewIQTestScreen(threadId: threadId)),
        );
      }
    } else if (viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Signup failed: ${viewModel.errorMessage}')),
      );
    }
  }

  Future<void> _handleLogin(BuildContext context) async {
    if (!_loginFormKey.currentState!.validate()) return;

    final viewModel = Provider.of<AuthenticationViewModel>(context, listen: false);
    
    final response = await viewModel.login(
      _emailLoginController.text,
      _passwordLoginController.text,
    );

    if (response != null) {
      final threadId = response['threadId'];
      if (threadId != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => WebViewIQTestScreen(threadId: threadId)),
        );
      }
    } else if (viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: ${viewModel.errorMessage}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationViewModel>(
      builder: (context, viewModel, child) {
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
                            _buildHeader(context),
                            Container(
                              constraints: BoxConstraints(maxWidth: 600),
                              child: Padding(
                                padding: EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    _buildTabBar(context),
                                    SizedBox(height: 20),
                                  Container(
                                constraints: BoxConstraints(
                                  maxHeight: MediaQuery.of(context).size.height * 0.7,
                                ),
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    _buildLoginForm(context, viewModel),
                                    _buildSignupForm(context, viewModel),
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
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(top: 24),
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
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return Center(
      child: TabBar(
        controller: _tabController,
        labelColor: Color(0xFF049a02),
        unselectedLabelColor: Theme.of(context).colorScheme.secondary,
        indicatorColor: Colors.transparent,
        labelStyle: TextStyle(fontSize: 20),
        tabs: [
          Tab(text: 'Sign In'),
          Tab(text: 'Sign Up'),
        ],
      ),
    );
  }

Widget _buildLoginForm(BuildContext context, AuthenticationViewModel viewModel) {
  return SingleChildScrollView(
    child: Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Let\'s get started!', style: Theme.of(context).textTheme.bodyLarge),
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
            onPressed: () => _handleLogin(context),
            isLoading: viewModel.isLoading,
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
    ),
  );
}


Widget _buildSignupForm(BuildContext context, AuthenticationViewModel viewModel) {
  return SingleChildScrollView(
    child: Form(
      key: _signupFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Create your account', style: Theme.of(context).textTheme.bodyLarge),
          SizedBox(height: 24),
          _buildTextField(controller: _nomController, label: 'First Name'),
          SizedBox(height: 16),
          _buildTextField(controller: _prenomController, label: 'Last Name'),
          SizedBox(height: 16),
          _buildTextField(controller: _emailSignupController, label: 'Email', keyboardType: TextInputType.emailAddress),
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
          _buildTextField(controller: _favoriteCharacterController, label: 'Favorite Character'),
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
          SizedBox(height: 16),
_buildTextField(
  controller: _parentPhoneController,
  label: 'Parent Phone Number',
  keyboardType: TextInputType.phone,
),

          SizedBox(height: 24),
          _buildAuthButton(
            text: 'Sign Up',
            onPressed: () => _handleSignup(context),
            isLoading: viewModel.isLoading,
          ),
        ],
      ),
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
    required bool isLoading,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0xFF049a02),
          padding: EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isLoading
            ? CircularProgressIndicator(color: Colors.white)
            : Text(text, style: TextStyle(fontSize: 16, color: Colors.white)),
      ),
    );
  }
}