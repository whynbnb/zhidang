import 'package:flutter/material.dart';

import 'screens/home_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ZhidangApp());
}

class ZhidangApp extends StatelessWidget {
  const ZhidangApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F766E),
      brightness: Brightness.light,
    );
    final dark = ColorScheme.fromSeed(
      seedColor: const Color(0xFF14B8A6),
      brightness: Brightness.dark,
    );

    return MaterialApp(
      title: '值当',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: base,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: false),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
        ),
        cardTheme: CardThemeData(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
        ),
      ),
      darkTheme: ThemeData(
        colorScheme: dark,
        useMaterial3: true,
        appBarTheme: const AppBarTheme(centerTitle: false),
        inputDecorationTheme: const InputDecorationTheme(
          filled: true,
        ),
        cardTheme: CardThemeData(
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero,
        ),
      ),
      home: const HomePage(),
    );
  }
}
