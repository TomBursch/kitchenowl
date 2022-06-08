import 'dart:convert';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/config.dart';
import 'package:kitchenowl/models/server_settings.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/storage/storage.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
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

    if (ApiService.getInstance().serverSettings.featureExpenses != null ||
        ApiService.getInstance().serverSettings.featurePlanner != null) {
      serverSettings = ApiService.getInstance().serverSettings;
    }

    emit(SettingsState(
      themeMode: themeMode,
      serverSettings: serverSettings,
    ));
  }

  void setTheme(ThemeMode themeMode) {
    PreferenceStorage.getInstance()
        .writeInt(key: 'themeMode', value: themeMode.index);
    emit(state.copyWith(themeMode: themeMode));
  }

  void setForcedOfflineMode(bool forcedOfflineMode) {
    emit(state.copyWith(forcedOfflineMode: forcedOfflineMode));
    if (!forcedOfflineMode) {
      TransactionHandler.getInstance().runOpenTransactions();
    }
  }

  void setFeaturePlanner(bool featurePlanner) {
    PreferenceStorage.getInstance()
        .writeBool(key: 'featurePlanner', value: featurePlanner);
    ApiService.getInstance()
        .setSettings(ServerSettings(featurePlanner: featurePlanner));
  }

  void setFeatureExpenses(bool featureExpenses) {
    PreferenceStorage.getInstance()
        .writeBool(key: 'featureExpenses', value: featureExpenses);
    ApiService.getInstance()
        .setSettings(ServerSettings(featureExpenses: featureExpenses));
  }
}

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final bool forcedOfflineMode;
  final ServerSettings serverSettings;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.forcedOfflineMode = false,
    this.serverSettings = const ServerSettings(),
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? forcedOfflineMode,
    ServerSettings? serverSettings,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        forcedOfflineMode: forcedOfflineMode ?? this.forcedOfflineMode,
        serverSettings: serverSettings ?? this.serverSettings,
      );

  @override
  List<Object?> get props => [themeMode, forcedOfflineMode, serverSettings];
}
