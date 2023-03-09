import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/config.dart';
import 'package:kitchenowl/models/server_settings.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/storage/storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit() : super(const SettingsState()) {
    ApiService.getInstance().addSettingsListener(serverSettingsUpdated);
    load();
  }

  Future<void> serverSettingsUpdated() async {
    await PreferenceStorage.getInstance().write(
      key: 'serverSettings',
      value: jsonEncode(ApiService.getInstance().serverSettings.toJson()),
    );
    emit(state.copyWith(
      serverSettings: ApiService.getInstance().serverSettings,
    ));
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

    ServerSettings serverSettings = ServerSettings.fromJson(jsonDecode(
      (await PreferenceStorage.getInstance().read(key: 'serverSettings')) ??
          "{}",
    ));

    if (ApiService.getInstance().serverSettings != null) {
      serverSettings = ApiService.getInstance().serverSettings;
    }

    emit(SettingsState(
      themeMode: themeMode,
      serverSettings: serverSettings,
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
/*
  void setView(ViewsEnum view, bool value) {
    if (view == ViewsEnum.mealPlanner) {
      final settings = state.serverSettings.copyWith(featurePlanner: value);
      emit(state.copyWith(serverSettings: settings));
      PreferenceStorage.getInstance()
          .write(key: 'serverSettings', value: jsonEncode(settings.toJson()));
      ApiService.getInstance()
          .setSettings(ServerSettings(featurePlanner: value));
    }
    if (view == ViewsEnum.balances) {
      final settings = state.serverSettings.copyWith(featureExpenses: value);
      emit(state.copyWith(serverSettings: settings));
      PreferenceStorage.getInstance()
          .write(key: 'serverSettings', value: jsonEncode(settings.toJson()));
      ApiService.getInstance()
          .setSettings(ServerSettings(featureExpenses: value));
    }
  }

  void reorderView(int oldIndex, int newIndex) {
    final l = List.of(state.serverSettings.viewOrdering!);
    l.insert(newIndex, l.removeAt(oldIndex));
    final settings = state.serverSettings.copyWith(viewOrdering: l);
    emit(state.copyWith(serverSettings: settings));
    PreferenceStorage.getInstance()
        .write(key: 'serverSettings', value: jsonEncode(settings.toJson()));
    ApiService.getInstance().setSettings(ServerSettings(viewOrdering: l));
  }

  void resetViewOrder() {
    final settings =
        state.serverSettings.copyWith(viewOrdering: ViewsEnum.values);
    emit(state.copyWith(serverSettings: settings));
    PreferenceStorage.getInstance().write(
      key: 'serverSettings',
      value: jsonEncode(
        settings.copyWith(viewOrdering: const []).toJson(),
      ),
    );
    ApiService.getInstance().setSettings(const ServerSettings(
      viewOrdering: [],
    ));
  }*/
}

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final ServerSettings serverSettings;
  final bool dynamicAccentColor;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.serverSettings = const ServerSettings(),
    this.dynamicAccentColor = false,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? forcedOfflineMode,
    ServerSettings? serverSettings,
    bool? dynamicAccentColor,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        serverSettings: serverSettings ?? this.serverSettings,
        dynamicAccentColor: dynamicAccentColor ?? this.dynamicAccentColor,
      );

  @override
  List<Object?> get props => [themeMode, serverSettings, dynamicAccentColor];

  // bool isViewActive(ViewsEnum view) {
  //   if (view == ViewsEnum.mealPlanner) {
  //     return serverSettings.featurePlanner ?? true;
  //   }
  //   if (view == ViewsEnum.balances) {
  //     return serverSettings.featureExpenses ?? true;
  //   }

  //   return true;
  // }
}
