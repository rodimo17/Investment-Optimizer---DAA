import 'package:flutter/material.dart';
import 'pages/home.dart';
import 'pages/settings.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppSettings(),
      builder: (context, _) {
        return MaterialApp(
          title: 'Investi-Aid',
          themeMode: AppSettings().darkMode
              ? ThemeMode.dark
              : ThemeMode.light,
          theme: ThemeData(
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.light,
            useMaterial3: true,
          ),
          darkTheme: ThemeData(
            colorSchemeSeed: Colors.indigo,
            brightness: Brightness.dark,
            useMaterial3: true,
          ),
          home: const HomePage(),
        );
      },
    );
  }
}

