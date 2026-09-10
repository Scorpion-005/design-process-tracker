import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(const DesignTrackerApp());
}

class DesignTrackerApp extends StatelessWidget {
  const DesignTrackerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Design Process Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
