import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info/package_info.dart';
import 'package:kitchenowl/config.dart';
import 'package:kitchenowl/services/storage.dart';

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
}

class SettingsState extends Equatable {
  final ThemeMode themeMode;

  SettingsState({
    this.themeMode = ThemeMode.system,
  });

  SettingsState copyWith({
    ThemeMode themeMode,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
      );

  @override
  List<Object> get props => [themeMode];
}
