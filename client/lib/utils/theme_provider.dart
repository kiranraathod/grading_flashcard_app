import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.light;
  bool get isDarkMode => _themeMode == ThemeMode.dark || 
                        (_themeMode == ThemeMode.system && 
                         WidgetsBinding.instance.platformDispatcher.platformBrightness == Brightness.dark);

  // Callback for theme change events
  final List<Function(ThemeMode oldMode, ThemeMode newMode)> _themeChangeCallbacks = [];

  // Constructor loads saved theme preference
  ThemeProvider() {
    _loadThemePreference();
    
    // Listen to system theme changes
    WidgetsBinding.instance.platformDispatcher.onPlatformBrightnessChanged = () {
      if (_themeMode == ThemeMode.system) {
        notifyListeners();
      }
    };
  }

  // Add a callback for theme changes
  void addThemeChangeCallback(Function(ThemeMode oldMode, ThemeMode newMode) callback) {
    _themeChangeCallbacks.add(callback);
  }

  // Remove a callback
  void removeThemeChangeCallback(Function(ThemeMode oldMode, ThemeMode newMode) callback) {
    _themeChangeCallbacks.remove(callback);
  }

  // Load theme preference from local storage
  Future<void> _loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    final themeModeString = prefs.getString('themeMode') ?? 'light';
    
    switch (themeModeString) {
      case 'system':
        _themeMode = ThemeMode.system;
        break;
      case 'dark':
        _themeMode = ThemeMode.dark;
        break;
      default:
        _themeMode = ThemeMode.light;
    }
    
    notifyListeners();
  }

  // Save theme preference to local storage
  Future<void> _saveThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    
    String themeModeString;
    switch (_themeMode) {
      case ThemeMode.system:
        themeModeString = 'system';
        break;
      case ThemeMode.dark:
        themeModeString = 'dark';
        break;
      default:
        themeModeString = 'light';
    }
    
    await prefs.setString('themeMode', themeModeString);
  }

  // Toggle between light and dark themes with animation support
  void toggleTheme() {
    final oldMode = _themeMode;
    final newMode = isDarkMode ? ThemeMode.light : ThemeMode.dark;
    
    // Only update if actually changing
    _themeMode = newMode;
    
    // Use Future.microtask to prevent frame drops during animation
    Future.microtask(() {
      // Notify callbacks
      for (var callback in _themeChangeCallbacks) {
        callback(oldMode, _themeMode);
      }
      
      _saveThemePreference();
      notifyListeners();
    });
  }
  
  // Set specific theme mode with animation support
  void setThemeMode(ThemeMode mode) {
    final oldMode = _themeMode;
    _themeMode = mode;
    
    // Notify callbacks
    for (var callback in _themeChangeCallbacks) {
      callback(oldMode, _themeMode);
    }
    
    _saveThemePreference();
    notifyListeners();
  }

  // Get current theme mode
  ThemeMode get themeMode => _themeMode;
  
  @override
  void dispose() {
    // Clean up callbacks
    _themeChangeCallbacks.clear();
    super.dispose();
  }
}
