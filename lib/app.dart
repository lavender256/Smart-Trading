import 'package:SmartTrade/screens/trading_terminal_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Crypto Order Flow Terminal',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0A0E17),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF3B82F6),
          secondary: Color(0xFF22C55E),
          surface: Color(0xFF111827),
          error: Color(0xFFEF4444),
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          bodySmall: TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
          bodyMedium: TextStyle(fontSize: 13, color: Color(0xFFE5E7EB)),
          bodyLarge: TextStyle(fontSize: 15, color: Color(0xFFE5E7EB)),
          labelSmall: TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
          labelMedium: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
          titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFFE5E7EB)),
          titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFFFFFFFF)),
        ),
      ),
      home: const ProviderScope(
        child: TradingTerminalScreen(),
      ),
    );
  }
}
