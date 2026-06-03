import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'models/theme.dart';
import 'services/app_state.dart';
import 'services/firebase_service.dart';
import 'screens/onboarding_screen.dart';
import 'screens/login_screen.dart';
import 'screens/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await FirebaseService.initialize();
  final prefs = await SharedPreferences.getInstance();
  final seenOnboarding = prefs.getBool('seen_onboarding') ?? false;
  runApp(CookMyFridgeApp(seenOnboarding: seenOnboarding));
}

class CookMyFridgeApp extends StatelessWidget {
  final bool seenOnboarding;
  const CookMyFridgeApp({super.key, required this.seenOnboarding});
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        title: 'CookMyFridge',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        home: seenOnboarding ? const _AuthGate() : const OnboardingScreen(),
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: kPrimary)));
        }
        return snap.hasData ? const MainShell() : const LoginScreen();
      },
    );
  }
}
