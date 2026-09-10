import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/theme_service.dart';

final themeService = ThemeService();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await themeService.load();
  runApp(const DesignTrackerApp());
}

class DesignTrackerApp extends StatelessWidget {
  const DesignTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeService,
      builder: (context, _) {
        return MaterialApp(
          title: 'Design Process Tracker',
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
          home: const HomeScreen(),
        );
      },
    );
  }
}
