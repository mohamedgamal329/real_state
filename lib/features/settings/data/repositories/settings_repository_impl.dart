import 'package:flutter/material.dart';

import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_data_source.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _local;

  SettingsRepositoryImpl(this._local);

  @override
  Future<ThemeMode> loadThemeMode() {
    return _local.loadThemeMode();
  }

  @override
  Future<void> saveThemeMode(ThemeMode mode) {
    return _local.saveThemeMode(mode);
  }
}
