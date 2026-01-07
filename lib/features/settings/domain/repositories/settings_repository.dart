import 'package:flutter/material.dart';

abstract class SettingsRepository {
  Future<ThemeMode> loadThemeMode();
  Future<void> saveThemeMode(ThemeMode mode);
}
