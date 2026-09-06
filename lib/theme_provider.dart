// ================= FILE 16: theme_provider.dart =================
import 'package:flutter/material.dart';

class ThemeProvider with ChangeNotifier {
  bool _isDarkMode = true;

  bool get isDarkMode => _isDarkMode;

  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
  }

  static ThemeData get darkTheme {
    return ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF0B0F19),
      primaryColor: const Color(0xFFF59E0B),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFF59E0B),
        secondary: Color(0xFFEC4899),
        surface: Color(0xFF1E293B),
      ),
      fontFamily: 'Roboto',
    );
  }

  static ThemeData get lightTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      primaryColor: const Color(0xFFD97706),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFD97706),
        secondary: Color(0xFFDB2777),
        surface: Colors.white,
      ),
      fontFamily: 'Roboto',
    );
  }
}
