import 'package:flutter/material.dart';

import '../repositories/settings_repository.dart';

class LoadThemeModeUseCase {
  final SettingsRepository _repo;
  LoadThemeModeUseCase(this._repo);

  Future<ThemeMode> call() => _repo.loadThemeMode();
}
