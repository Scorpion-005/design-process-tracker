import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'services/theme_service.dart';
import 'services/notification_service.dart';

final themeService = ThemeService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await themeService.load();
  runApp(const SkeinApp());
}

class SkeinApp extends StatelessWidget {
  const SkeinApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeService,
      builder: (context, _) {
        return MaterialApp(
          title: 'Skein',
          debugShowCheckedModeBanner: false,
          themeMode: themeService.themeMode,
          theme: ThemeData(
            colorSchemeSeed: Colors.deepPurple,
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.deepPurple,
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasData) {
          // Signed in — make sure this device is registered for push
          // notifications (fire-and-forget, don't block the UI on it).
          NotificationService.initialize();
          return const HomeScreen();
        }
        return const LoginScreen();
      },
    );
  }
}
