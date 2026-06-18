import 'package:flutter/material.dart';
import 'pages/home.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Investment Optimizer',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          primary: Colors.indigo[800]!,
          secondary: Colors.deepPurple[700]!,
          surface: Colors.white,
          background: const Color(0xFFF8FAFC), // Modern Slate background
        ),
        textTheme: const TextTheme(
          displayMedium: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
          titleLarge: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5),
          bodyMedium: TextStyle(color: Color(0xFF475569)),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const HomePage(),
    );
  }
}
