import 'package:flutter/material.dart';
import 'screens/home_screen.dart'; // Import halaman Home

void main() {
  runApp(const VoxModApp());
}

// ==========================================
// TEMA & KONFIGURASI UMUM
// ==========================================
class VoxModApp extends StatelessWidget {
  const VoxModApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VoxMod Studio',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0D0D15), // Dark Navy/Black
        primaryColor: const Color(0xFF00FFC2), // Neon Green
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFF00FFC2),
          secondary: Color(0xFFE91E63), // Neon Pink
          surface: Color(0xFF1E1E2C),
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
      ),
      home: const HomeScreen(),
    );
  }
}