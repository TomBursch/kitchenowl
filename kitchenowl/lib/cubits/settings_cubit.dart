import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:equatable/equatable.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/config.dart';
import 'package:kitchenowl/kitchenowl.dart';
import 'package:kitchenowl/services/storage/storage.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// Units offered when asking for the quantity. Symbols only, so they need no
/// translation and add up on the server.
const kShoppingListUnits = [
  'kg',
  'g',
  'l',
  'dl',
  'cl',
  'ml',
  'mg',
  'oz',
  'lb',
  'fl oz',
];
const kShoppingListUnitsDefault = ['kg', 'g', 'l', 'dl', 'cl', 'ml'];

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
    final shoppingListKeepAwake = PreferenceStorage.getInstance()
        .readBool(key: 'shoppingListKeepAwake');
    final shoppingListAskQuantity = PreferenceStorage.getInstance()
        .readBool(key: 'shoppingListAskQuantity');
    final shoppingListUnits =
        PreferenceStorage.getInstance().read(key: 'shoppingListUnits');
    final shoppingListCustomUnits =
        PreferenceStorage.getInstance().read(key: 'shoppingListCustomUnits');

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
      shoppingListAskQuantity: await shoppingListAskQuantity ?? false,
      shoppingListUnits:
          _decodeList(await shoppingListUnits) ?? kShoppingListUnitsDefault,
      shoppingListCustomUnits:
          _decodeList(await shoppingListCustomUnits) ?? const <String>[],
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

  void setShoppingListAskQuantity(bool shoppingListAskQuantity) {
    PreferenceStorage.getInstance().writeBool(
      key: 'shoppingListAskQuantity',
      value: shoppingListAskQuantity,
    );
    emit(state.copyWith(shoppingListAskQuantity: shoppingListAskQuantity));
  }

  void setShoppingListUnitEnabled(String unit, bool enabled) {
    final units = state.shoppingListUnits.where((e) => e != unit).toList();
    if (enabled) units.add(unit);
    _writeUnits(units: units);
  }

  void addShoppingListCustomUnit(String unit) {
    // A comma separates entries in a description, so it can't be in a unit
    unit = unit.replaceAll(',', ' ').trim().replaceAll(RegExp(r'\s+'), ' ');
    if (unit.isEmpty) return;
    final existing = state.allShoppingListUnits
        .firstWhereOrNull((e) => e.toLowerCase() == unit.toLowerCase());
    if (existing != null) {
      setShoppingListUnitEnabled(existing, true);
      return;
    }
    _writeUnits(
      units: [...state.shoppingListUnits, unit],
      customUnits: [...state.shoppingListCustomUnits, unit],
    );
  }

  void removeShoppingListCustomUnit(String unit) {
    _writeUnits(
      units: state.shoppingListUnits.where((e) => e != unit).toList(),
      customUnits:
          state.shoppingListCustomUnits.where((e) => e != unit).toList(),
    );
  }

  void _writeUnits({List<String>? units, List<String>? customUnits}) {
    if (units != null) {
      PreferenceStorage.getInstance()
          .write(key: 'shoppingListUnits', value: jsonEncode(units));
    }
    if (customUnits != null) {
      PreferenceStorage.getInstance().write(
        key: 'shoppingListCustomUnits',
        value: jsonEncode(customUnits),
      );
    }
    emit(state.copyWith(
      shoppingListUnits: units,
      shoppingListCustomUnits: customUnits,
    ));
  }

  static List<String>? _decodeList(String? value) {
    if (value == null) return null;
    try {
      return List<String>.from(jsonDecode(value));
    } catch (_) {
      return null;
    }
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
  final bool shoppingListAskQuantity;
  final List<String> shoppingListUnits;
  final List<String> shoppingListCustomUnits;

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
    this.shoppingListAskQuantity = false,
    this.shoppingListUnits = kShoppingListUnitsDefault,
    this.shoppingListCustomUnits = const [],
  });

  List<String> get allShoppingListUnits =>
      {...kShoppingListUnits, ...shoppingListCustomUnits}.toList();

  /// Units shown when asking for the quantity, in display order.
  List<String> get visibleShoppingListUnits =>
      allShoppingListUnits.where(shoppingListUnits.contains).toList();

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
    bool? shoppingListAskQuantity,
    List<String>? shoppingListUnits,
    List<String>? shoppingListCustomUnits,
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
        shoppingListAskQuantity:
            shoppingListAskQuantity ?? this.shoppingListAskQuantity,
        shoppingListUnits: shoppingListUnits ?? this.shoppingListUnits,
        shoppingListCustomUnits:
            shoppingListCustomUnits ?? this.shoppingListCustomUnits,
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
        shoppingListAskQuantity,
        shoppingListUnits,
        shoppingListCustomUnits,
      ];
}
