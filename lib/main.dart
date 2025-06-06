import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'screens/calendar/schedule_home_page.dart';
import 'screens/login_screen.dart';
import 'theme/theme_provider.dart';
import 'services/event_manager.dart';
import 'services/user_preference_manager.dart';
import 'services/schedule_recommendation_service.dart';
import 'services/auth_service.dart';

void main() async {
  // Ensure Flutter is initialized before doing any async work
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the schedule recommendation service in the background
  // without blocking app startup
  final recommendationService = ScheduleRecommendationService();
  // Don't wait for it to finish - let it initialize in the background
  recommendationService.initializeNetwork().catchError((error) {
    // Log the error but don't crash the app
    print('Failed to initialize neural network: $error');
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => EventManager()),
        ChangeNotifierProvider(create: (context) => UserPreferenceManager()),
        // Add the recommendation service to the provider
        Provider.value(value: recommendationService),
        // Add the authentication service
        ChangeNotifierProvider(create: (context) => AuthService()),
      ],
      child: const KempenhaegeScheduleApp(),
    ),
  );
}

class KempenhaegeScheduleApp extends StatelessWidget {
  const KempenhaegeScheduleApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final authService = Provider.of<AuthService>(context);

    return MaterialApp(
      title: 'Kempenhaege Schedule',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      home: authService.isAuthenticated
          ? const ScheduleHomePage()
          : const LoginScreen(),
    );
  }
}
