import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'homescreen.dart';

void main() async {
  // Warten bis Flutter bereit ist
  WidgetsFlutterBinding.ensureInitialized();

  // Datenbank starten
  await Hive.initFlutter();
  await Hive.openBox('tradingBox');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Kraken Trader',
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFF0B0E11),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0B0E11),
          elevation: 0,
          centerTitle: true,
        ),
        cardColor: const Color(0xFF1B1E22),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF5D5CFF),
          secondary: Color(0xFF5D5CFF),
        ),
      ),

      home: const HomeScreen(),
    );
  }
}