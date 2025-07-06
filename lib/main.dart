import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'config/supabase_config.dart';
import 'services/auth_service.dart';
import 'onboarding_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/phone_auth_screen.dart';
import 'screens/direct_login_screen.dart';
import 'home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Initialize Supabase
    await SupabaseConfig.initialize();
    runApp(const FootstepsApp());
  } catch (e) {
    // Handle initialization errors
    runApp(ErrorApp(error: e.toString()));
  }
}

class FootstepsApp extends StatelessWidget {
  const FootstepsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => AuthService(),
      child: MaterialApp(
        title: 'Footsteps',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          // Mobile-optimized theme
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.teal,
            brightness: Brightness.light,
          ),
          useMaterial3: true,
          // Mobile-specific app bar theme
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
          ),
          // Mobile-optimized card theme
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          // Mobile-optimized floating action button
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            elevation: 4,
            shape: CircleBorder(),
          ),
        ),
        home: const AuthWrapper(),
        routes: {
          '/onboarding': (context) => const OnboardingScreen(),
          '/direct-login': (context) => const DirectLoginScreen(),
          '/phone-auth': (context) => const PhoneAuthScreen(),
          '/landing': (context) => const LandingScreen(),
          '/home': (context) => const HomePage(),
        },
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, child) {
        // Show loading indicator while checking auth state
        if (authService.isLoading) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        // Mobile-first onboarding flow logic
        if (authService.isAuthenticated) {
          // User is logged in → go to main app
          return const LandingScreen();
        } else if (authService.hasCompletedOnboarding) {
          // User has seen onboarding before but is not logged in
          // → show clean login screen without onboarding (native mobile app pattern)
          return const DirectLoginScreen();
        } else {
          // First time user → show onboarding
          return const OnboardingScreen();
        }
      },
    );
  }
}

class ErrorApp extends StatelessWidget {
  final String error;

  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Footsteps - Error',
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Configuration Error',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  'Please check your .env file configuration:\n\n$error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Make sure you have created a .env file in the root directory with:\n\nSUPABASE_URL=your_supabase_url\nSUPABASE_ANON_KEY=your_supabase_anon_key',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
