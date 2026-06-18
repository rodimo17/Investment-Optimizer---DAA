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
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4A148C),
          primary: const Color(0xFF4A148C),
          secondary: const Color(0xFF7B1FA2),
        ),
        // By not setting a global fontFamily override to the custom thin font,
        // we allow the app to use the full system font family (Regular, Bold, etc.)
        // which makes it much more readable and professional.
      ),
      home: const HomePage(),
    );
  }
}
