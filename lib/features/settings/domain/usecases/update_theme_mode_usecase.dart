import 'package:flutter/material.dart';

import '../repositories/settings_repository.dart';

class UpdateThemeModeUseCase {
  final SettingsRepository _repo;
  UpdateThemeModeUseCase(this._repo);

  Future<void> call(ThemeMode mode) => _repo.saveThemeMode(mode);
}
