import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends ChangeNotifier {
  ThemeController._({required ThemeMode initialMode, this._preferences})
    : _mode = initialMode;

  static const _darkModeKey = 'spendly_dark_mode';

  final SharedPreferences? _preferences;
  ThemeMode _mode;

  ThemeMode get mode => _mode;
  bool get isDark => _mode == ThemeMode.dark;

  static Future<ThemeController> load() async {
    final preferences = await SharedPreferences.getInstance();
    final savedDarkMode = preferences.getBool(_darkModeKey);
    final platformIsDark =
        WidgetsBinding.instance.platformDispatcher.platformBrightness ==
        Brightness.dark;
    return ThemeController._(
      initialMode: (savedDarkMode ?? platformIsDark)
          ? ThemeMode.dark
          : ThemeMode.light,
      preferences: preferences,
    );
  }

  factory ThemeController.forTest({bool isDark = false}) {
    return ThemeController._(
      initialMode: isDark ? ThemeMode.dark : ThemeMode.light,
    );
  }

  void toggle() {
    _mode = isDark ? ThemeMode.light : ThemeMode.dark;
    notifyListeners();
    unawaited(_preferences?.setBool(_darkModeKey, isDark));
  }
}
