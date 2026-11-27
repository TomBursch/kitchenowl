import 'package:device_info_plus/device_info_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/config.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/services/location_service.dart';
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
    final listStyle = PreferenceStorage.getInstance().readInt(key: 'listStyle');
    final recentItemsCount =
        PreferenceStorage.getInstance().readInt(key: 'recentItemsCount');
    final accentColor =
        PreferenceStorage.getInstance().readInt(key: 'accentColor');
    final shoppingListListView =
        PreferenceStorage.getInstance().readBool(key: 'shoppingListListView');
    final shoppingListTapToRemove = PreferenceStorage.getInstance()
        .readBool(key: 'shoppingListTapToRemove');
    final recentItemsCategorize =
        PreferenceStorage.getInstance().readBool(key: 'recentItemsCategorize');
    final restoreLastShoppingList = PreferenceStorage.getInstance()
        .readBool(key: 'restoreLastShoppingList');
    final shoppingListKeepAwake =
        PreferenceStorage.getInstance().readBool(key: 'shoppingListKeepAwake');
    final advancedRecipesControl =
        PreferenceStorage.getInstance().readBool(key: 'advancedRecipesControl');

    final locationSettings = LocationService.readSettings();

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
      listStyle: (await listStyle) != null
          ? ListStyle.values[(await listStyle)!]
          : ListStyle.cards,
      recentItemsCount: await recentItemsCount ?? 9,
      accentColor:
          (await accentColor) != null ? Color((await accentColor)!) : null,
      shoppingListListView: await shoppingListListView ?? false,
      shoppingListTapToRemove: await shoppingListTapToRemove ?? true,
      recentItemsCategorize: await recentItemsCategorize ?? false,
      restoreLastShoppingList: await restoreLastShoppingList ?? false,
      shoppingListKeepAwake: await shoppingListKeepAwake ?? false,
      advancedRecipesControl: await advancedRecipesControl ?? false,
      location: await locationSettings,
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

  void setListStyle(ListStyle listStyle) {
    PreferenceStorage.getInstance()
        .writeInt(key: 'listStyle', value: listStyle.index);
    emit(state.copyWith(listStyle: listStyle));
  }

  void setRecentItemsCount(int recentItemsCount) {
    if (recentItemsCount >= 0) {
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

  void setRecentItemsCategorize(bool recentItemsCategorize) {
    PreferenceStorage.getInstance().writeBool(
      key: 'recentItemsCategorize',
      value: recentItemsCategorize,
    );
    emit(state.copyWith(recentItemsCategorize: recentItemsCategorize));
  }

  void setRestoreLastShoppinglist(bool restoreLastShoppingList) {
    PreferenceStorage.getInstance().writeBool(
      key: 'restoreLastShoppingList',
      value: restoreLastShoppingList,
    );
    emit(state.copyWith(restoreLastShoppingList: restoreLastShoppingList));
  }

  void setShoppingListKeepAwake(bool shoppingListKeepAwake) {
    PreferenceStorage.getInstance().writeBool(
      key: 'shoppingListKeepAwake',
      value: shoppingListKeepAwake,
    );
    emit(state.copyWith(shoppingListKeepAwake: shoppingListKeepAwake));
  }

  /// Enables location based shopping lists. Returns false if the location
  /// permission was not granted.
  Future<bool> setLocationEnabled(bool enabled) async {
    if (enabled) {
      final granted = await LocationService.requestPermission(
        background:
            LocationService.isGeofencingSupported && state.location.notify,
      );
      if (!granted) return false;
      if (state.location.notify) {
        await LocationService.requestNotificationPermission();
      }
    }
    await PreferenceStorage.getInstance()
        .writeBool(key: LocationService.prefEnabled, value: enabled);
    emit(state.copyWith(location: state.location.copyWith(enabled: enabled)));
    await LocationService.syncGeofencesFromCache();

    return true;
  }

  Future<void> setLocationNotify(bool notify) async {
    if (notify) {
      await LocationService.requestPermission(background: true);
      await LocationService.requestNotificationPermission();
    }
    await PreferenceStorage.getInstance()
        .writeBool(key: LocationService.prefNotify, value: notify);
    emit(state.copyWith(location: state.location.copyWith(notify: notify)));
    await LocationService.syncGeofencesFromCache();
  }

  void setLocationNotifyOncePerVisit(bool value) {
    PreferenceStorage.getInstance()
        .writeBool(key: LocationService.prefNotifyOncePerVisit, value: value);
    emit(state.copyWith(
      location: state.location.copyWith(notifyOncePerVisit: value),
    ));
  }

  void setLocationIgnoreEmptyLists(bool value) {
    PreferenceStorage.getInstance()
        .writeBool(key: LocationService.prefIgnoreEmptyLists, value: value);
    emit(state.copyWith(
      location: state.location.copyWith(ignoreEmptyLists: value),
    ));
  }

  void setLocationAutoSwitch(bool value) {
    PreferenceStorage.getInstance()
        .writeBool(key: LocationService.prefAutoSwitch, value: value);
    emit(state.copyWith(location: state.location.copyWith(autoSwitch: value)));
  }

  void setLocationConfirmSwitch(bool value) {
    PreferenceStorage.getInstance()
        .writeBool(key: LocationService.prefConfirmSwitch, value: value);
    emit(state.copyWith(
      location: state.location.copyWith(confirmSwitch: value),
    ));
  }

  Future<void> setShoppingListLocationMuted(
    int shoppingListId,
    bool muted,
  ) async {
    await LocationService.setShoppingListMuted(shoppingListId, muted);
    final ids = Set.of(state.location.mutedShoppingLists);
    muted ? ids.add(shoppingListId) : ids.remove(shoppingListId);
    emit(state.copyWith(
      location: state.location.copyWith(mutedShoppingLists: ids),
    ));
    await LocationService.syncGeofencesFromCache();
  }

  void setAdvancedRecipesControl(bool advancedRecipesControl) {
    PreferenceStorage.getInstance().writeBool(
      key: 'advancedRecipesControl',
      value: advancedRecipesControl,
    );
    emit(state.copyWith(advancedRecipesControl: advancedRecipesControl));
  }
}

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final bool dynamicAccentColor;
  final int recentItemsCount;
  final GridSize gridSize;
  final ListStyle listStyle;
  final Color? accentColor;
  final bool shoppingListListView;
  final bool shoppingListTapToRemove;
  final bool recentItemsCategorize;
  final bool restoreLastShoppingList;
  final bool shoppingListKeepAwake;
  final bool advancedRecipesControl;
  final ShoppingListLocationSettings location;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.dynamicAccentColor = false,
    this.gridSize = GridSize.normal,
    this.listStyle = ListStyle.cards,
    this.recentItemsCount = 9,
    this.accentColor,
    this.shoppingListListView = false,
    this.shoppingListTapToRemove = true,
    this.recentItemsCategorize = false,
    this.restoreLastShoppingList = false,
    this.shoppingListKeepAwake = false,
    this.advancedRecipesControl = false,
    this.location = const ShoppingListLocationSettings(),
  });

  SettingsState copyWith({
    ThemeMode? themeMode,
    bool? dynamicAccentColor,
    GridSize? gridSize,
    ListStyle? listStyle,
    int? recentItemsCount,
    Nullable<Color>? accentColor,
    bool? shoppingListListView,
    bool? shoppingListTapToRemove,
    bool? recentItemsCategorize,
    bool? restoreLastShoppingList,
    bool? shoppingListKeepAwake,
    bool? advancedRecipesControl,
    ShoppingListLocationSettings? location,
  }) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        dynamicAccentColor: dynamicAccentColor ?? this.dynamicAccentColor,
        gridSize: gridSize ?? this.gridSize,
        listStyle: listStyle ?? this.listStyle,
        recentItemsCount: recentItemsCount ?? this.recentItemsCount,
        accentColor: (accentColor ?? Nullable(this.accentColor)).value,
        shoppingListListView: shoppingListListView ?? this.shoppingListListView,
        shoppingListTapToRemove:
            shoppingListTapToRemove ?? this.shoppingListTapToRemove,
        recentItemsCategorize:
            recentItemsCategorize ?? this.recentItemsCategorize,
        restoreLastShoppingList:
            restoreLastShoppingList ?? this.restoreLastShoppingList,
        shoppingListKeepAwake:
            shoppingListKeepAwake ?? this.shoppingListKeepAwake,
        advancedRecipesControl:
            advancedRecipesControl ?? this.advancedRecipesControl,
        location: location ?? this.location,
      );

  @override
  List<Object?> get props => [
        themeMode,
        dynamicAccentColor,
        gridSize,
        listStyle,
        recentItemsCount,
        accentColor,
        shoppingListListView,
        shoppingListTapToRemove,
        recentItemsCategorize,
        restoreLastShoppingList,
        shoppingListKeepAwake,
        advancedRecipesControl,
        location,
      ];
}
