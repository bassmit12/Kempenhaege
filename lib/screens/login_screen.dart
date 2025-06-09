import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'calendar/schedule_home_page.dart';
import 'dart:math' as math;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  final _pinController = TextEditingController();
  String _enteredPin = '';
  String _username = '';
  List<Map<String, dynamic>> _users = [];
  int _selectedUserIndex = 0;
  bool _isLoggingIn = false;
  bool _showError = false;

  // Animation controllers
  late AnimationController _pageController;
  late AnimationController _pinEntryController;
  late AnimationController _loginController;
  late AnimationController _errorController;
  late AnimationController _switchUserController;
  late AnimationController _backgroundAnimController;

  // Animations
  late Animation<double> _logoScaleAnimation;
  late Animation<double> _logoOpacityAnimation;
  late Animation<double> _backgroundAnimation;
  late Animation<double> _pinBoxAnimation;
  late Animation<double> _keypadScaleAnimation;
  late Animation<double> _keypadOpacityAnimation;
  late Animation<double> _buttonPressAnimation;
  late Animation<Offset> _errorShakeAnimation;
  late Animation<double> _successAnimation;
  late Animation<double> _successIconAnimation;
  late Animation<Offset> _switchUserSlideAnimation;
  late Animation<double> _switchUserOpacityAnimation;

  // Individual PIN dot animations
  late List<AnimationController> _dotAnimControllers;
  late List<Animation<double>> _dotAnimations;
  late List<Animation<double>> _dotColorAnimations;

  // Wave animation
  late Animation<double> _waveAnimation;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _setupAnimations();
  }

  void _setupAnimations() {
    // Background animation with continuous subtle movement
    _backgroundAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    );

    _waveAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(_backgroundAnimController);

    _backgroundAnimController.repeat();

    // Initial page entrance animation
    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _logoScaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2),
        weight: 60,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 40,
      ),
    ]).animate(CurvedAnimation(
      parent: _pageController,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
    ));

    _logoOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    ));

    _backgroundAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));

    _pinBoxAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageController,
      curve: const Interval(0.4, 0.8, curve: Curves.easeOutBack),
    ));

    _keypadScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOutBack),
    ));

    _keypadOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pageController,
      curve: const Interval(0.6, 1.0, curve: Curves.easeOut),
    ));

    // Animation for PIN entry
    _pinEntryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _buttonPressAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _pinEntryController,
      curve: Curves.easeInOut,
    ));

    // User switching animation
    _switchUserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _switchUserSlideAnimation = Tween<Offset>(
      begin: Offset.zero,
      end: const Offset(0, -0.7),
    ).animate(CurvedAnimation(
      parent: _switchUserController,
      curve: Curves.easeInOut,
    ));

    _switchUserOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _switchUserController,
      curve: Curves.easeInOut,
    ));

    // Individual dot animations
    _dotAnimControllers = List.generate(
        4,
        (index) => AnimationController(
              vsync: this,
              duration: const Duration(milliseconds: 250),
            ));

    _dotAnimations = _dotAnimControllers.map((controller) {
      return Tween<double>(
        begin: 1.0,
        end: 1.4,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOutBack,
      ));
    }).toList();

    _dotColorAnimations = _dotAnimControllers.map((controller) {
      return Tween<double>(
        begin: 0.0,
        end: 1.0,
      ).animate(CurvedAnimation(
        parent: controller,
        curve: Curves.easeOut,
      ));
    }).toList();

    // Login animation
    _loginController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _successAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _loginController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
    ));

    _successIconAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.0, end: 1.2),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.2, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 0.0),
        weight: 20,
      ),
    ]).animate(CurvedAnimation(
      parent: _loginController,
      curve: Curves.easeInOutQuart,
    ));

    // Error animation
    _errorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _errorShakeAnimation = TweenSequence<Offset>([
      TweenSequenceItem(
        tween: Tween<Offset>(begin: Offset.zero, end: const Offset(-0.05, 0)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
            begin: const Offset(-0.05, 0), end: const Offset(0.05, 0)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
            begin: const Offset(0.05, 0), end: const Offset(-0.05, 0)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(
            begin: const Offset(-0.05, 0), end: const Offset(0.05, 0)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero),
        weight: 20,
      ),
    ]).animate(CurvedAnimation(
      parent: _errorController,
      curve: Curves.easeOut,
    ));

    // Start the initial page animation
    _pageController.forward();
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pageController.dispose();
    _pinEntryController.dispose();
    _loginController.dispose();
    _errorController.dispose();
    _switchUserController.dispose();
    _backgroundAnimController.dispose();
    for (final controller in _dotAnimControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadUsers() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    try {
      final users = await authService.getUsers();
      setState(() {
        _users = users;
        if (users.isNotEmpty) {
          _username = users[0]['name'];
        }
      });
    } catch (e) {
      debugPrint('Error loading users: $e');
    }
  }

  void _switchUser() {
    if (_users.isEmpty || _isLoggingIn) return;

    _switchUserController.forward().then((_) {
      setState(() {
        _selectedUserIndex = (_selectedUserIndex + 1) % _users.length;
        _username = _users[_selectedUserIndex]['name'];
        _enteredPin = '';
      });
      _switchUserController.reverse();
    });
  }

  void _addDigit(String digit) {
    if (_enteredPin.length < 4 && !_isLoggingIn) {
      _pinEntryController.forward().then((_) => _pinEntryController.reverse());

      setState(() {
        _enteredPin += digit;
      });

      // Animate the newly filled dot
      final dotIndex = _enteredPin.length - 1;
      _dotAnimControllers[dotIndex].forward(from: 0.0);

      // Auto-login when all 4 digits are entered
      if (_enteredPin.length == 4) {
        _login();
      }
    }
  }

  void _removeLastDigit() {
    if (_enteredPin.isNotEmpty && !_isLoggingIn) {
      _pinEntryController.forward().then((_) => _pinEntryController.reverse());
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      });
    }
  }

  Future<void> _login() async {
    if (_enteredPin.length == 4 && !_isLoggingIn) {
      setState(() {
        _isLoggingIn = true;
      });

      final authService = Provider.of<AuthService>(context, listen: false);

      if (_users.isEmpty) {
        setState(() {
          _isLoggingIn = false;
        });
        return;
      }

      final selectedUser = _users[_selectedUserIndex];
      final username = selectedUser['username'];

      final success = await authService.login(
        username,
        _enteredPin,
      );

      if (success && mounted) {
        // Play success animation and navigate
        _loginController.forward().then((_) {
          if (mounted) {
            Navigator.of(context).pushReplacement(
              PageRouteBuilder(
                pageBuilder: (context, animation, secondaryAnimation) =>
                    const ScheduleHomePage(),
                transitionsBuilder:
                    (context, animation, secondaryAnimation, child) {
                  return FadeTransition(
                    opacity: animation,
                    child: child,
                  );
                },
                transitionDuration: const Duration(milliseconds: 500),
              ),
            );
          }
        });
      } else {
        // Reset PIN and show error animation
        setState(() {
          _enteredPin = '';
          _isLoggingIn = false;
          _showError = true;
        });

        _errorController.forward().then((_) {
          _errorController.reset();

          // Hide error message after delay
          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              setState(() {
                _showError = false;
              });
            }
          });
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(authService.error ?? 'Invalid PIN'),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              margin: const EdgeInsets.all(10),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final screenSize = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _pageController,
        _pinEntryController,
        _loginController,
        _errorController,
        _switchUserController,
        _backgroundAnimController,
      ]),
      builder: (context, child) {
        return Scaffold(
          body: Stack(
            children: [
              // Animated background with subtle movement
              AnimatedBuilder(
                animation: _waveAnimation,
                builder: (context, child) {
                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment(
                            math.sin(_waveAnimation.value * 0.2) * 0.2 + 0.2,
                            math.cos(_waveAnimation.value * 0.2) * 0.2 - 0.2),
                        end: Alignment(
                            math.cos(_waveAnimation.value * 0.2) * 0.2 + 0.8,
                            math.sin(_waveAnimation.value * 0.2) * 0.2 + 1.2),
                        colors: [
                          Color.lerp(Colors.white, const Color(0xFF1E88E5),
                              _backgroundAnimation.value)!,
                          Color.lerp(Colors.white, const Color(0xFF0D47A1),
                              _backgroundAnimation.value)!,
                        ],
                        stops: const [0.3, 1.0],
                      ),
                    ),
                  );
                },
              ),

              // Success overlay animation
              if (_loginController.isAnimating)
                Positioned.fill(
                  child: Container(
                    color: Colors.blue.shade900
                        .withOpacity(_loginController.value * 0.9),
                    child: Center(
                      child: ScaleTransition(
                        scale: _successIconAnimation,
                        child: FadeTransition(
                          opacity: Tween<double>(begin: 0.0, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _loginController,
                              curve: const Interval(0.0, 0.3),
                            ),
                          ),
                          child: const Icon(
                            Icons.check_circle_outline,
                            color: Colors.white,
                            size: 90,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

              // Main content with error shake animation
              SlideTransition(
                position: _errorShakeAnimation,
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Logo section
                      Padding(
                        padding: const EdgeInsets.only(top: 60),
                        child: ScaleTransition(
                          scale: _logoScaleAnimation,
                          child: FadeTransition(
                            opacity: _logoOpacityAnimation,
                            child: Image.asset(
                              'assets/logo/Kempenhaeghe_logo.png',
                              width: 200,
                              height: 80,
                              fit: BoxFit.contain,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),

                      // Welcome text section
                      FadeTransition(
                        opacity: _backgroundAnimation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.5),
                            end: Offset.zero,
                          ).animate(CurvedAnimation(
                            parent: _pageController,
                            curve:
                                const Interval(0.3, 0.7, curve: Curves.easeOut),
                          )),
                          child: SlideTransition(
                            position: _switchUserSlideAnimation,
                            child: FadeTransition(
                              opacity: _switchUserOpacityAnimation,
                              child: Column(
                                children: [
                                  GestureDetector(
                                    onTap: _switchUser,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(30),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color:
                                                  Colors.white.withOpacity(0.2),
                                            ),
                                            child: Center(
                                              child: Text(
                                                _username.isNotEmpty
                                                    ? _username[0].toUpperCase()
                                                    : "U",
                                                style: const TextStyle(
                                                  fontSize: 20,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                'Welcome back',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.white70,
                                                ),
                                              ),
                                              Text(
                                                _username,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                  color: Colors.white,
                                                  shadows: [
                                                    Shadow(
                                                      color: Colors.black26,
                                                      offset: Offset(0, 1),
                                                      blurRadius: 2,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_drop_down,
                                            color: Colors.white70,
                                            size: 24,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Enter your PIN to continue',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),

                      // PIN section
                      ScaleTransition(
                        scale: _pinBoxAnimation,
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 50),
                          child: Column(
                            children: [
                              // PIN display boxes
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: List.generate(
                                  4,
                                  (index) => ScaleTransition(
                                    scale: index < _enteredPin.length
                                        ? _dotAnimations[index]
                                        : const AlwaysStoppedAnimation(1.0),
                                    child: AnimatedContainer(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      width: 50, // Reduced from 60
                                      height: 50, // Reduced from 60
                                      decoration: BoxDecoration(
                                        color: index < _enteredPin.length
                                            ? Color.lerp(
                                                Colors.white.withOpacity(0.2),
                                                Colors.white.withOpacity(0.5),
                                                index < _enteredPin.length
                                                    ? _dotColorAnimations[index]
                                                        .value
                                                    : 0.0,
                                              )
                                            : Colors.white.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(
                                            12), // Adjusted from 15
                                        boxShadow: index < _enteredPin.length
                                            ? [
                                                BoxShadow(
                                                  color: Colors.white
                                                      .withOpacity(0.3),
                                                  blurRadius: 8,
                                                  spreadRadius: 2,
                                                ),
                                              ]
                                            : null,
                                        border: Border.all(
                                          color: Colors.white.withOpacity(
                                              index < _enteredPin.length
                                                  ? 0.6
                                                  : 0.3),
                                          width: 1.5,
                                        ),
                                      ),
                                      child: _isLoggingIn &&
                                              index < _enteredPin.length
                                          ? Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                          Color>(Colors.white),
                                                  backgroundColor: Colors.white
                                                      .withOpacity(0.2),
                                                ),
                                              ),
                                            )
                                          : index < _enteredPin.length
                                              ? const Center(
                                                  child: Icon(
                                                    Icons.circle,
                                                    color: Colors.white,
                                                    size: 20,
                                                  ),
                                                )
                                              : null,
                                    ),
                                  ),
                                ),
                              ),

                              // Error message
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                child: _showError
                                    ? const Padding(
                                        padding: EdgeInsets.only(top: 16),
                                        child: Text(
                                          'Incorrect PIN. Please try again.',
                                          style: TextStyle(
                                            color: Colors.red,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      )
                                    : const SizedBox(height: 16),
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Keypad section
                      Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: ScaleTransition(
                          scale: _keypadScaleAnimation,
                          child: FadeTransition(
                            opacity: _keypadOpacityAnimation,
                            child: Container(
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 24),
                              padding: const EdgeInsets.symmetric(
                                  vertical: 24, horizontal: 16),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.2),
                                  width: 1.5,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Colors.white.withOpacity(0.2),
                                    Colors.white.withOpacity(0.05),
                                  ],
                                ),
                              ),
                              child: Column(
                                children: [
                                  for (int row = 0; row < 3; row++)
                                    Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 16),
                                      child: Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceEvenly,
                                        children: List.generate(
                                          3,
                                          (col) => _buildKeypadButton(
                                              '${row * 3 + col + 1}'),
                                        ),
                                      ),
                                    ),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      const SizedBox(width: 70, height: 70),
                                      _buildKeypadButton('0'),
                                      SizedBox(
                                        width: 70,
                                        height: 70,
                                        child: ScaleTransition(
                                          scale: _buttonPressAnimation,
                                          child: Material(
                                            color: Colors.transparent,
                                            child: InkWell(
                                              onTap: _isLoggingIn
                                                  ? null
                                                  : _removeLastDigit,
                                              borderRadius:
                                                  BorderRadius.circular(35),
                                              splashColor:
                                                  Colors.white.withOpacity(0.1),
                                              highlightColor:
                                                  Colors.white.withOpacity(0.1),
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Colors.white
                                                      .withOpacity(0.1),
                                                  shape: BoxShape.circle,
                                                  border: Border.all(
                                                    color: Colors.white
                                                        .withOpacity(0.3),
                                                    width: 1,
                                                  ),
                                                ),
                                                child: const Center(
                                                  child: Icon(
                                                    Icons.backspace_outlined,
                                                    color: Colors.white,
                                                    size: 24,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
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
      },
    );
  }

  Widget _buildKeypadButton(String digit) {
    return SizedBox(
      width: 70,
      height: 70,
      child: ScaleTransition(
        scale: _buttonPressAnimation,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _isLoggingIn ? null : () => _addDigit(digit),
            borderRadius: BorderRadius.circular(35),
            splashColor: Colors.white.withOpacity(0.1),
            highlightColor: Colors.white.withOpacity(0.1),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    spreadRadius: 0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  digit,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
