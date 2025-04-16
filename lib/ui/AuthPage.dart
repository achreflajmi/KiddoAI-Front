import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';
import '../view_models/authentication_view_model.dart';
import 'iq_test_screen.dart';

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
          MaterialPageRoute(builder: (context) => IQTestScreen(threadId: threadId)),
        );
      }
    } else if (viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فشل إنشاء الحساب: ${viewModel.errorMessage}', // Translated: Signup failed
            textDirection: TextDirection.rtl,
          ),
        ),
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
          MaterialPageRoute(builder: (context) => IQTestScreen(threadId: threadId)),
        );
      }
    } else if (viewModel.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'فشل تسجيل الدخول: ${viewModel.errorMessage}', // Translated: Login failed
            textDirection: TextDirection.rtl,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthenticationViewModel>(
      builder: (context, viewModel, child) {
        return Directionality(
          textDirection: TextDirection.rtl, // Added for RTL
          child: GestureDetector(
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
                  ].reversed.toList(), // Reversed for RTL
                ),
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
          Tab(text: 'تسجيل الدخول'), // Translated: Sign In
          Tab(text: 'إنشاء حساب'), // Translated: Sign Up
        ].reversed.toList(), // Reversed for RTL
      ),
    );
  }

  Widget _buildLoginForm(BuildContext context, AuthenticationViewModel viewModel) {
    return SingleChildScrollView(
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end, // Changed for RTL
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'ابدأ الآن!', // Translated: Let's get started!
              style: Theme.of(context).textTheme.bodyLarge,
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 24),
            _buildTextField(
              controller: _emailLoginController,
              label: 'البريد الإلكتروني', // Translated: Email
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr, // Email typically LTR
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _passwordLoginController,
              label: 'كلمة المرور', // Translated: Password
              obscureText: !_passwordVisible,
              textDirection: TextDirection.ltr, // Password typically LTR
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
              text: 'تسجيل الدخول', // Translated: Sign In
              onPressed: () => _handleLogin(context),
              isLoading: viewModel.isLoading,
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'هل نسيت كلمة المرور؟', // Translated: Forgot Password?
                style: TextStyle(color: Color(0xFF049a02)),
                textDirection: TextDirection.rtl,
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
          crossAxisAlignment: CrossAxisAlignment.end, // Changed for RTL
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'أنشئ حسابك', // Translated: Create your account
              style: Theme.of(context).textTheme.bodyLarge,
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 24),
            _buildTextField(
              controller: _prenomController,
              label: 'الاسم الأول', // Translated: First Name
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _nomController,
              label: 'اسم العائلة', // Translated: Last Name
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _emailSignupController,
              label: 'البريد الإلكتروني', // Translated: Email
              keyboardType: TextInputType.emailAddress,
              textDirection: TextDirection.ltr, // Email typically LTR
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _passwordSignupController,
              label: 'كلمة المرور', // Translated: Password
              obscureText: !_signupPasswordVisible,
              textDirection: TextDirection.ltr, // Password typically LTR
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
              label: 'الشخصية المفضلة', // Translated: Favorite Character
              textDirection: TextDirection.rtl,
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _dateOfBirthController,
              label: 'تاريخ الميلاد', // Translated: Date of Birth
              textDirection: TextDirection.rtl,
              readOnly: true,
              onTap: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(1900),
                  lastDate: DateTime.now(),
                  locale: const Locale('ar'), // Arabic date picker
                );
                if (pickedDate != null) {
                  _dateOfBirthController.text = "${pickedDate.toLocal()}".split(' ')[0];
                }
              },
            ),
            SizedBox(height: 16),
            _buildTextField(
              controller: _parentPhoneController,
              label: 'رقم هاتف الوالدين', // Translated: Parent Phone Number
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr, // Phone typically LTR
            ),
            SizedBox(height: 24),
            _buildAuthButton(
              text: 'إنشاء حساب', // Translated: Sign Up
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
    TextDirection? textDirection, // Added for RTL control
    bool readOnly = false, // Added for date field
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      onTap: onTap,
      readOnly: readOnly,
      textDirection: textDirection,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        suffixIcon: suffixIcon,
        labelStyle: TextStyle(fontSize: 14, color: Colors.black),
 // Added for RTL
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'يرجى إدخال $label'; // Translated: Please enter [field]
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
            : Text(
                text,
                style: TextStyle(fontSize: 16, color: Colors.white),
                textDirection: TextDirection.rtl,
              ),
      ),
    );
  }
}