import 'package:device_info_plus/device_info_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/config.dart';
import 'package:kitchenowl/services/storage/storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState()) {
    load();
  }

  Future<void> load() async {
    final themeModeIndex =
        PreferenceStorage.getInstance().readInt(key: 'themeMode');
    final dynamicAccentColor =
        PreferenceStorage.getInstance().readBool(key: 'dynamicAccentColor');
    Config.deviceInfo = DeviceInfoPlugin().deviceInfo;
    Config.packageInfo = PackageInfo.fromPlatform();

    ThemeMode themeMode = ThemeMode.system;
    if (await themeModeIndex != null) {
      themeMode = ThemeMode.values[(await themeModeIndex)!];
    }

    emit(SettingsState(
      themeMode: themeMode,
      dynamicAccentColor: await dynamicAccentColor ?? false,
    ));
  }

  void setTheme(ThemeMode themeMode) {
    PreferenceStorage.getInstance()
        .writeInt(key: 'themeMode', value: themeMode.index);
    emit(state.copyWith(themeMode: themeMode));
  }

  void setUseDynamicAccentColor(bool dynamicAccentColor) {
    PreferenceStorage.getInstance()
        .writeBool(key: 'dynamicAccentColor', value: dynamicAccentColor);
    emit(state.copyWith(dynamicAccentColor: dynamicAccentColor));
  }
}

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final bool dynamicAccentColor;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.dynamicAccentColor = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? forcedOfflineMode,
    bool? dynamicAccentColor,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        dynamicAccentColor: dynamicAccentColor ?? this.dynamicAccentColor,
      );

  @override
  List<Object?> get props => [themeMode, dynamicAccentColor];
}
