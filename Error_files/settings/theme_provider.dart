import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  bool useSystemTheme = false;
  bool isDarkMode = true;
  Color dynamicColor = Colors.deepPurple;
  bool useBottomNav = true; // true = bottom nav, false = side drawer
  bool autoColoring = true; // Auto color from artwork
  bool _isInitialized = false;

  // Auto-coloring background (COMMENTED OUT)
  // Color? _autoBackgroundColor;
  // Color get backgroundColor => _autoBackgroundColor ?? (isDarkMode ? Colors.black : Colors.white);
  Color get backgroundColor => isDarkMode ? Colors.black : Colors.white;

  // Store the original user-selected color
  Color? _originalDynamicColor;

  ThemeProvider() {
    _loadPreferences();
  }

  // Load saved preferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      useSystemTheme = prefs.getBool('useSystemTheme') ?? false;
      isDarkMode = prefs.getBool('isDarkMode') ?? true;
      useBottomNav = prefs.getBool('useBottomNav') ?? true;
      autoColoring = prefs.getBool('autoColoring') ?? true;

      // Load color as int (ARGB format)
      final colorValue = prefs.getInt('dynamicColor');
      if (colorValue != null) {
        dynamicColor = Color(colorValue);
      }

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme preferences: $e');
      // Use default values if loading fails
      _isInitialized = true;
      notifyListeners();
    }
  }

  void toggleSystemTheme(bool value) async {
    try {
      useSystemTheme = value;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('useSystemTheme', value);
    } catch (e) {
      debugPrint('Error saving system theme preference: $e');
    }
  }

  void toggleDarkMode(bool value) async {
    try {
      isDarkMode = value;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isDarkMode', value);
    } catch (e) {
      debugPrint('Error saving dark mode preference: $e');
    }
  }

  void setDynamicColor(Color color) async {
    try {
      dynamicColor = color;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      // Convert Color to ARGB int format for storage
      final argb = ((color.a * 255).round() << 24) |
                   ((color.r * 255).round() << 16) |
                   ((color.g * 255).round() << 8) |
                   ((color.b * 255).round());
      await prefs.setInt('dynamicColor', argb);
    } catch (e) {
      debugPrint('Error saving dynamic color: $e');
    }
  }

  void toggleBottomNav(bool value) async {
    try {
      useBottomNav = value;
      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('useBottomNav', value);
    } catch (e) {
      debugPrint('Error saving bottom nav preference: $e');
    }
  }

  void toggleAutoColoring(bool value) async {
    try {
      autoColoring = value;

      // COMMENTED OUT - Reset to original colors when disabling auto-coloring
      // if (!value) {
      //   _autoBackgroundColor = null;
      //   if (_originalDynamicColor != null) {
      //     dynamicColor = _originalDynamicColor!;
      //   }
      // }

      notifyListeners();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('autoColoring', value);
    } catch (e) {
      debugPrint('Error saving auto coloring preference: $e');
    }
  }

  // COMMENTED OUT - Update colors based on album artwork
  // /// Update colors based on album artwork
  // void updateAutoColors({required Color primaryColor, required Color backgroundColor}) {
  //   if (!autoColoring) return;
  //
  //   // Save original color if not already saved
  //   _originalDynamicColor ??= dynamicColor;
  //
  //   dynamicColor = primaryColor;
  //   _autoBackgroundColor = backgroundColor;
  //   notifyListeners();
  // }

  // /// Reset auto colors to default/original
  // void resetAutoColors() {
  //   if (_originalDynamicColor != null) {
  //     dynamicColor = _originalDynamicColor!;
  //   }
  //   _autoBackgroundColor = null;
  //   notifyListeners();
  // }
}
