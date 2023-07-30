import 'package:device_info_plus/device_info_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/config.dart';
import 'package:kitchenowl/kitchenowl.dart';
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
    final gridSize = PreferenceStorage.getInstance().readInt(key: 'gridSize');
    final recentItemsCount =
        PreferenceStorage.getInstance().readInt(key: 'recentItemsCount');
    final accentColor =
        PreferenceStorage.getInstance().readInt(key: 'accentColor');
    final shoppingListListView =
        PreferenceStorage.getInstance().readBool(key: 'shoppingListListView');
    final shoppingListTapToRemove = PreferenceStorage.getInstance()
        .readBool(key: 'shoppingListTapToRemove');
    Config.deviceInfo = DeviceInfoPlugin().deviceInfo;
    Config.packageInfo = PackageInfo.fromPlatform();

    ThemeMode themeMode = ThemeMode.system;
    if (await themeModeIndex != null) {
      themeMode = ThemeMode.values[(await themeModeIndex)!];
    }

    emit(SettingsState(
      themeMode: themeMode,
      dynamicAccentColor: await dynamicAccentColor ?? false,
      gridSize: (await gridSize) != null
          ? GridSize.values[(await gridSize)!]
          : GridSize.normal,
      recentItemsCount: await recentItemsCount ?? 9,
      accentColor:
          (await accentColor) != null ? Color((await accentColor)!) : null,
      shoppingListListView: await shoppingListListView ?? false,
      shoppingListTapToRemove: await shoppingListTapToRemove ?? true,
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

  void setGridSize(GridSize gridSize) {
    PreferenceStorage.getInstance()
        .writeInt(key: 'gridSize', value: gridSize.index);
    emit(state.copyWith(gridSize: gridSize));
  }

  void setRecentItemsCount(int recentItemsCount) {
    if (recentItemsCount > 0) {
      PreferenceStorage.getInstance()
          .writeInt(key: 'recentItemsCount', value: recentItemsCount);
      emit(state.copyWith(recentItemsCount: recentItemsCount));
    }
  }

  void setAccentColor(Color? accentColor) {
    accentColor = accentColor?.withAlpha(255);
    if (accentColor != null) {
      PreferenceStorage.getInstance()
          .writeInt(key: 'accentColor', value: accentColor.value);
    } else {
      PreferenceStorage.getInstance().delete(key: 'accentColor');
    }
    emit(state.copyWith(accentColor: Nullable(accentColor)));
  }

  void setShoppingListListView(bool shoppingListListView) {
    PreferenceStorage.getInstance()
        .writeBool(key: 'shoppingListListView', value: shoppingListListView);
    emit(state.copyWith(shoppingListListView: shoppingListListView));
  }

  void setShoppingListTapToRemove(bool shoppingListTapToRemove) {
    PreferenceStorage.getInstance().writeBool(
      key: 'shoppingListTapToRemove',
      value: shoppingListTapToRemove,
    );
    emit(state.copyWith(shoppingListTapToRemove: shoppingListTapToRemove));
  }
}

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final bool dynamicAccentColor;
  final int recentItemsCount;
  final GridSize gridSize;
  final Color? accentColor;
  final bool shoppingListListView;
  final bool shoppingListTapToRemove;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.dynamicAccentColor = false,
    this.gridSize = GridSize.normal,
    this.recentItemsCount = 9,
    this.accentColor,
    this.shoppingListListView = false,
    this.shoppingListTapToRemove = true,
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? dynamicAccentColor,
    GridSize? gridSize,
    int? recentItemsCount,
    Nullable<Color>? accentColor,
    bool? shoppingListListView,
    bool? shoppingListTapToRemove,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        dynamicAccentColor: dynamicAccentColor ?? this.dynamicAccentColor,
        gridSize: gridSize ?? this.gridSize,
        recentItemsCount: recentItemsCount ?? this.recentItemsCount,
        accentColor: (accentColor ?? Nullable(this.accentColor)).value,
        shoppingListListView: shoppingListListView ?? this.shoppingListListView,
        shoppingListTapToRemove:
            shoppingListTapToRemove ?? this.shoppingListTapToRemove,
      );

  @override
  List<Object?> get props => [
        themeMode,
        dynamicAccentColor,
        gridSize,
        recentItemsCount,
        accentColor,
        shoppingListListView,
        shoppingListTapToRemove,
      ];
}
