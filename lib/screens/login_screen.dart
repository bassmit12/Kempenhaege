import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../theme/theme_provider.dart';
import 'calendar/schedule_home_page.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _pincodeController = TextEditingController();
  bool _obscurePincode = true;

  @override
  void initState() {
    super.initState();
    // For debugging purposes, pre-fill with test credentials
    _usernameController.text = 'johndoe';
    _pincodeController.text = '1234';
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  void _togglePincodeVisibility() {
    setState(() {
      _obscurePincode = !_obscurePincode;
    });
  }

  Future<void> _login() async {
    if (_formKey.currentState!.validate()) {
      final authService = Provider.of<AuthService>(context, listen: false);

      debugPrint('Login button pressed');
      debugPrint('Username: ${_usernameController.text}');
      debugPrint('Pincode: ${_pincodeController.text}');

      final success = await authService.login(
        _usernameController.text.trim(),
        _pincodeController.text.trim(),
      );

      if (success && mounted) {
        debugPrint('Login successful, navigating to home screen');
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const ScheduleHomePage()),
        );
      } else {
        debugPrint('Login failed: ${authService.error}');
        // Error is displayed through the auth service's error state
      }
    }
  }

  Widget _buildNotionTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDarkMode ? ThemeProvider.notionGray : Colors.grey[700],
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          validator: validator,
          keyboardType: keyboardType,
          style: TextStyle(
            fontSize: 15,
            color: isDarkMode ? Colors.white : ThemeProvider.notionBlack,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: isDarkMode ? Colors.grey[600] : Colors.grey[400],
            ),
            filled: true,
            fillColor:
                isDarkMode ? ThemeProvider.notionDarkGray : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 14,
            ),
            suffixIcon: suffixIcon,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Logo and Title
                    Column(
                      children: [
                        // Kempenhaege Logo
                        Image.asset(
                          'assets/logo/Kempenhaeghe_logo.png',
                          width: 180,
                          height: 80,
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'AI Scheduling App',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: isDarkMode
                                ? Colors.white
                                : ThemeProvider.notionBlack,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Sign in to your account',
                          style: TextStyle(
                            fontSize: 16,
                            color: isDarkMode
                                ? ThemeProvider.notionGray
                                : Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 36),
                      ],
                    ),

                    // Error message if there is one
                    if (authService.error != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 24),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                          border:
                              Border.all(color: Colors.red.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline, color: Colors.red),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                authService.error!,
                                style: const TextStyle(color: Colors.red),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.red),
                              onPressed: () {
                                authService.clearError();
                              },
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),

                    // Username Field
                    _buildNotionTextField(
                      controller: _usernameController,
                      label: 'USERNAME',
                      hint: 'Enter your username',
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your username';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),

                    // Pincode Field
                    _buildNotionTextField(
                      controller: _pincodeController,
                      label: 'PINCODE',
                      hint: 'Enter your pincode',
                      obscureText: _obscurePincode,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePincode
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color:
                              isDarkMode ? Colors.grey[600] : Colors.grey[400],
                        ),
                        onPressed: _togglePincodeVisibility,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your pincode';
                        }
                        return null;
                      },
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 32),

                    // Login Button
                    ElevatedButton(
                      onPressed: authService.isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeProvider.notionBlue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                        disabledBackgroundColor:
                            ThemeProvider.notionBlue.withOpacity(0.6),
                      ),
                      child: authService.isLoading
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Sign In',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                    const SizedBox(height: 24),

                    // Sample Credentials Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? ThemeProvider.notionDarkGray
                            : Colors.grey[100],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: isDarkMode
                              ? const Color(0xFF404040)
                              : const Color(0xFFE0E0E0),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sample Credentials',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode
                                  ? Colors.white
                                  : ThemeProvider.notionBlack,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildCredentialRow(
                            'johndoe',
                            '1234',
                            'Care Coordinator',
                            isDarkMode,
                          ),
                          const Divider(height: 24),
                          _buildCredentialRow(
                            'janesmith',
                            '5678',
                            'Admin',
                            isDarkMode,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCredentialRow(
    String username,
    String pincode,
    String role,
    bool isDarkMode,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Username: $username',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode
                          ? ThemeProvider.notionGray
                          : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pincode: $pincode',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode
                          ? ThemeProvider.notionGray
                          : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Role: $role',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDarkMode
                          ? ThemeProvider.notionGray
                          : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: () {
                _usernameController.text = username;
                _pincodeController.text = pincode;
              },
              style: TextButton.styleFrom(
                foregroundColor: ThemeProvider.notionBlue,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              child: const Text('Use'),
            ),
          ],
        ),
      ],
    );
  }
}
