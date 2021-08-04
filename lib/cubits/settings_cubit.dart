import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/config.dart';
import 'package:kitchenowl/services/storage/storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(SettingsState()) {
    load();
  }

  Future<void> load() async {
    final darkmode =
        await PreferenceStorage.getInstance().readBool(key: 'darkmode');
    Config.packageInfo = await PackageInfo.fromPlatform();

    ThemeMode themeMode = ThemeMode.system;
    if (darkmode != null) {
      themeMode = darkmode ? ThemeMode.dark : ThemeMode.light;
    }

    emit(SettingsState(
      themeMode: themeMode,
    ));
  }

  void setTheme(ThemeMode themeMode) {
    PreferenceStorage.getInstance()
        .writeBool(key: 'darkmode', value: themeMode == ThemeMode.dark);
    emit(state.copyWith(themeMode: themeMode));
  }

  void setForcedOfflineMode(bool forcedOfflineMode) {
    emit(state.copyWith(forcedOfflineMode: forcedOfflineMode));
  }
}

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final bool forcedOfflineMode;

  SettingsState({
    this.themeMode = ThemeMode.system,
    this.forcedOfflineMode = false,
  });

  SettingsState copyWith({
    ThemeMode themeMode,
    bool forcedOfflineMode,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        forcedOfflineMode: forcedOfflineMode ?? this.forcedOfflineMode,
      );

  @override
  List<Object> get props => [themeMode, forcedOfflineMode];
}
