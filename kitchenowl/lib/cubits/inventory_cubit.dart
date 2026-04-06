import 'dart:async';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/enums/inventory_sorting.dart';
import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/inventory.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/api/inventory.dart';
import 'package:kitchenowl/services/storage/storage.dart';
import 'package:kitchenowl/services/transactions/category.dart';
import 'package:kitchenowl/services/transactions/inventory.dart';
import 'package:kitchenowl/services/transaction_handler.dart';

class InventoryCubit extends Cubit<InventoryCubitState> {
  final Household household;
  Future<void>? _refreshThread;
  String? _refreshCurrentQuery;
  Timer? _periodicRefreshTimer;
  Connection? _lastConnectionState;

  String get query => (state is SearchInventoryCubitState)
      ? (state as SearchInventoryCubitState).query
      : "";

  InventoryCubit(this.household) : super(const LoadingInventoryCubitState()) {
    PreferenceStorage.getInstance().readInt(key: 'itemSorting').then((i) {
      if (i != null && state.sorting.index != i) {
        setSorting(
          InventorySorting.values[i % InventorySorting.values.length],
          false,
        );
      }
    });
    _initialLoad();
    refresh();
    ApiService.getInstance().onInventoryAdd(onInventoryAdd);
    ApiService.getInstance().onInventoryDelete(onInventoryDelete);
    ApiService.getInstance().onInventoryItemAdd(onInventoryItemAdd);
    ApiService.getInstance().onInventoryItemRemove(onInventoryItemRemove);

    // Refresh data when connection state transitions to authenticated
    _lastConnectionState = ApiService.getInstance().connectionStatus;
    ApiService.getInstance().addListener(_onConnectionChange);

    // Periodic refresh as fallback for missed WebSocket events
    _periodicRefreshTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) {
        if (ApiService.getInstance().isAuthenticated()) {
          refresh();
        }
      },
    );
  }

  void _onConnectionChange() {
    final current = ApiService.getInstance().connectionStatus;
    if (current == Connection.authenticated &&
        _lastConnectionState != Connection.authenticated) {
      refresh();
    }
    _lastConnectionState = current;
  }

  @override
  Future<void> close() async {
    _periodicRefreshTimer?.cancel();
    ApiService.getInstance().removeListener(_onConnectionChange);
    ApiService.getInstance().offInventoryAdd(onInventoryAdd);
    ApiService.getInstance().offInventoryDelete(onInventoryDelete);
    ApiService.getInstance().offInventoryItemAdd(onInventoryItemAdd);
    ApiService.getInstance().offInventoryItemRemove(onInventoryItemRemove);
    super.close();
  }

  void onInventoryAdd(dynamic data) {
    refresh();
  }

  void onInventoryDelete(dynamic data) {
    refresh();
  }

  void onInventoryItemAdd(dynamic data) {
    final item = InventoryItem.fromJson(data["item"]);
    TransactionHandler.getInstance().runTransaction(
      TransactionInventoryAddItem(
        household: household,
        inventory: Inventory.fromJson(data["inventory"]),
        item: item,
      ),
      forceOffline: true,
      saveTransaction: false,
    );
    addLocally(
      InventoryItem.fromJson(data["item"]),
      data["inventory"]["id"],
    );
  }

  void onInventoryItemRemove(dynamic data) {
    final item = InventoryItem.fromJson(data["item"]);
    TransactionHandler.getInstance().runTransaction(
      TransactionInventoryRemoveItem(
        household: household,
        inventory: Inventory.fromJson(data["inventory"]),
        item: item,
      ),
      forceOffline: true,
      saveTransaction: false,
    );
    removeLocally(item, data["inventory"]["id"]);
  }

  Future<void> search(String query) => refresh(query: query);

  Future<void> add(Item item) async {
    final _state = state;
    addLocally(InventoryItem.fromItem(item: item));
    if (_state.selectedInventory == null) return;
    await TransactionHandler.getInstance()
        .runTransaction(TransactionInventoryAddItem(
      household: household,
      inventory: _state.selectedInventory!,
      item: item,
    ));
    await refresh(query: '');
  }

  void addLocally(InventoryItem item, [int? inventoryId]) {
    final _state = state;
    inventoryId ??= _state.selectedInventory?.id;
    if (inventoryId == null) return;
    final inventory = _state.inventories[inventoryId];
    if (inventory == null) return;

    final l = List.of(inventory.items);
    l.removeWhere((e) => e.id == item.id || e.name == item.name);
    l.add(item);
    InventorySorting.sortInventoryItems(l, state.sorting);
    final recent = List.of(inventory.recentItems);
    recent.removeWhere((e) => e.name == item.name);
    if (_state is SearchInventoryCubitState) {
      final result = List.of(_state.result);
      final index = result.indexWhere((e) => e.id == item.id);
      if (index >= 0) {
        result.removeAt(index);
        result.insert(
          index,
          item,
        );
      }
      emit(_state.copyWith(
        inventories: _replaceAndUpdateInventories(_state.inventories,
            inventory.copyWith(items: l, recentItems: recent)),
        result: result,
      ));
    } else {
      emit(state.copyWith(
        inventories: _replaceAndUpdateInventories(_state.inventories,
            inventory.copyWith(items: l, recentItems: recent)),
      ));
    }
  }

  Future<void> remove(InventoryItem item) async {
    final _state = state;
    removeLocally(item);
    if (!await TransactionHandler.getInstance()
        .runTransaction(TransactionInventoryRemoveItem(
      household: household,
      inventory: _state.selectedInventory!,
      item: item,
    ))) {
      await refresh();
    }
  }

  void removeLocally(InventoryItem item, [int? inventoryId]) {
    final _state = state;
    inventoryId ??= _state.selectedInventory?.id;
    if (inventoryId == null) return;
    final inventory = _state.inventories[inventoryId];
    if (inventory == null) return;

    final l = List.of(inventory.items);
    l.removeWhere((e) => e.name == item.name);
    final recent = List.of(inventory.recentItems);
    recent.removeWhere((e) => e.name == item.name);
    recent.insert(0, ItemWithDescription.fromItem(item: item));
    if (_state is SearchInventoryCubitState) {
      final result = List.of(_state.result);
      final index = result.indexOf(item);
      if (index >= 0) {
        result.removeAt(index);
        result.insert(
          index,
          ItemWithDescription.fromItem(
            item: item,
            description: item.description,
          ),
        );
      }
      emit(_state.copyWith(
          inventories: _replaceAndUpdateInventories(_state.inventories,
              inventory.copyWith(items: l, recentItems: recent)),
          result: result));
    } else {
      emit(state.copyWith(
        inventories: _replaceAndUpdateInventories(_state.inventories,
            inventory.copyWith(items: l, recentItems: recent)),
      ));
    }
  }

  void selectItem(InventoryItem item) {
    final l = List.of(state.selectedListItems);
    if (l.contains(item)) {
      l.remove(item);
    } else {
      l.insert(0, item);
    }
    emit(state.copyWith(selectedListItems: l));
  }

  Future<void> confirmRemove() async {
    final _state = state;
    if (_state.selectedInventory == null || _state.selectedListItems.isEmpty) {
      return;
    }
    final selectedItems = _state.selectedListItems
        .sorted((a, b) => a.id?.compareTo(b.id ?? 0) ?? -1);
    final l = List.of(_state.selectedInventory!.items);
    l.removeWhere(selectedItems.contains);
    final recent = List.of(_state.selectedInventory!.recentItems);
    recent.insertAll(
      0,
      selectedItems.map((e) => ItemWithDescription.fromItem(item: e)),
    );

    if (_state is SearchInventoryCubitState) {
      final result = List.of(_state.result);
      for (final item in selectedItems) {
        final index = result.indexOf(item);
        if (index >= 0) {
          result.removeAt(index);
          result.insert(
            index,
            ItemWithDescription.fromItem(item: item),
          );
        }
      }
      emit(_state.copyWith(
        inventories: _replaceAndUpdateInventories(_state.inventories,
            _state.selectedInventory!.copyWith(items: l, recentItems: recent)),
        result: result,
        selectedListItems: [],
      ));
    } else {
      emit(_state.copyWith(
          inventories: _replaceAndUpdateInventories(
              _state.inventories,
              _state.selectedInventory!
                  .copyWith(items: l, recentItems: recent)),
          selectedListItems: []));
    }
    if (!await TransactionHandler.getInstance()
        .runTransaction(TransactionInventoryRemoveItems(
      household: household,
      inventory: _state.selectedInventory!,
      items: selectedItems,
    ))) {
      await refresh();
    }
  }

  void incrementSorting() {
    setSorting(InventorySorting
        .values[(state.sorting.index + 1) % InventorySorting.values.length]);
  }

  void setSorting(InventorySorting sorting, [bool savePreference = true]) {
    if (state is! SearchInventoryCubitState &&
        state.selectedInventory != null &&
        state.selectedInventory?.items != const []) {
      state.inventories.forEach(
          (_, l) => InventorySorting.sortInventoryItems(l.items, sorting));
    }
    if (savePreference) {
      PreferenceStorage.getInstance()
          .writeInt(key: 'itemSorting', value: sorting.index);
    }
    emit(state.copyWith(sorting: sorting));
  }

  void setInventory(Inventory inventory) {
    if (inventory.id != null) {
      PreferenceStorage.getInstance().writeInt(
        key: 'selectedInventory',
        value: inventory.id!,
      );
    }
    emit(state.copyWith(
      selectedListItems: inventory.id != state.selectedInventoryId ? [] : null,
      selectedInventoryId: inventory.id,
    ));
  }

  Future<void> refresh({String? query}) {
    final state = this.state;
    if (state is SearchInventoryCubitState) {
      query = query ?? state.query;
    }
    if (_refreshThread != null && query != _refreshCurrentQuery) {
      _refreshCurrentQuery = query;
      _refreshThread = _refresh(query);
    }
    if (_refreshThread == null) {
      _refreshCurrentQuery = query;
      _refreshThread = _refresh(query);
    }

    return _refreshThread!;
  }

  Future<Map<int, Inventory>> fetchInventories(
      [bool forceOffline = false]) async {
    final inventories = await TransactionHandler.getInstance()
        .runTransaction(
          TransactionInventoryGet(household: household),
          forceOffline: forceOffline,
        )
        .then((lists) => Map.fromEntries(lists
            .map((e) => e.id != null ? MapEntry(e.id!, e) : null)
            .nonNulls));

    inventories.forEach(
        (_, l) => InventorySorting.sortInventoryItems(l.items, state.sorting));

    return inventories;
  }

  Future<List<Category>> fetchCategories([bool forceOffline = false]) {
    return TransactionHandler.getInstance().runTransaction(
      TransactionCategoriesGet(household: household),
      forceOffline: forceOffline,
    );
  }

  Future<void> _initialLoad() async {
    final inventories = await fetchInventories(true);

    Inventory? inventory = state.selectedInventory;
    if (await PreferenceStorage.getInstance()
            .readBool(key: "restoreLastInventory") ??
        false) {
      int? id = await PreferenceStorage.getInstance()
          .readInt(key: "selectedInventory");
      if (id != null) {
        inventory ??= inventories.values.firstWhereOrNull((s) => s.id == id);
      }
    }
    inventory ??= inventories.values.firstOrNull;

    if (inventory == null) return;

    Future<List<Category>> categories = fetchCategories(true);

    final resState = LoadingInventoryCubitState(
      inventories: inventories,
      selectedInventoryId: inventory.id,
      categories: await categories,
      sorting: state.sorting,
      selectedListItems: state.selectedListItems
          .map((e) =>
              inventory!.items.firstWhereOrNull((item) => item.id == e.id))
          .nonNulls
          .toList(),
    );

    if (state is LoadingInventoryCubitState) {
      emit(resState);
    }
  }

  Future<void> _refresh([String? query]) async {
    // Get required information
    late InventoryCubitState resState;
    if (state.selectedInventoryId == null ||
        (state.selectedInventory?.items.isEmpty ?? true) &&
            (state.selectedInventory?.recentItems.isEmpty ?? true) &&
            (query == null || query.isEmpty)) {
      emit(LoadingInventoryCubitState(
        selectedInventoryId: state.selectedInventoryId,
        inventories: state.inventories,
        sorting: state.sorting,
        categories: state.categories,
        selectedListItems: state.selectedListItems,
      ));
    }

    final inventories = await fetchInventories();

    int? selectedInventoryId = state.selectedInventoryId;
    if (selectedInventoryId != null &&
        !inventories.containsKey(selectedInventoryId)) {
      selectedInventoryId = null;
    }
    selectedInventoryId ??= inventories.values.firstOrNull?.id;

    if (selectedInventoryId == null) return;

    final inventory = inventories[selectedInventoryId];

    Future<List<Category>> categories = fetchCategories();

    if (query != null && query.isNotEmpty) {
      // Split query into name and description
      final splitIndex = query.indexOf(',');
      String queryName = query.trim();
      String? queryDescription;
      if (splitIndex >= 0) {
        queryName = query.substring(0, splitIndex).trim();
        queryDescription = query.substring(splitIndex + 1).trim();
      }

      Future<List<Item>> searchItems = TransactionHandler.getInstance()
          .runTransaction(
            TransactionInventorySearchItem(
              household: household,
              query: queryName,
            ),
          )
          .then((items) => items
              .map((e) => ItemWithDescription.fromItem(
                    item: e,
                    description: queryDescription,
                  ))
              .toList());

      List<Item> loadedItems = await searchItems;

      _mergeInventoryItems(loadedItems, inventory?.items);
      if (loadedItems.isEmpty ||
          !loadedItems
              .any((e) => e.name.toLowerCase() == queryName.toLowerCase())) {
        loadedItems.add(ItemWithDescription(
          name: queryName,
          description: queryDescription ?? '',
        ));
      }
      resState = SearchInventoryCubitState(
        inventories: inventories,
        selectedInventoryId: selectedInventoryId,
        result: loadedItems,
        query: query,
        categories: await categories,
        sorting: state.sorting,
        selectedListItems: state.selectedListItems
            .map((e) =>
                inventory?.items.firstWhereOrNull((item) => item.id == e.id))
            .nonNulls
            .toList(),
      );
    } else {
      resState = InventoryCubitState(
        inventories: inventories,
        selectedInventoryId: selectedInventoryId,
        categories: await categories,
        sorting: state.sorting,
        selectedListItems: state.selectedListItems
            .map((e) =>
                inventory?.items.firstWhereOrNull((item) => item.id == e.id))
            .nonNulls
            .toList(),
      );
    }
    if (query == _refreshCurrentQuery) {
      emit(resState);
      _refreshThread = null;
    }
  }

  void _mergeInventoryItems(
    List<Item> items,
    List<InventoryItem>? inventory,
  ) {
    if (inventory == null || inventory.isEmpty) return;
    for (int i = 0; i < items.length; i++) {
      final inventoryItem =
          inventory.firstWhereOrNull((e) => e.id == items[i].id);
      if (inventoryItem != null) {
        items.removeAt(i);
        items.insert(i, inventoryItem);
      }
    }
  }

  Map<int, Inventory> _replaceAndUpdateInventories(
      Map<int, Inventory> inventories, Inventory inventory) {
    if (inventory.id == null) return inventories;

    final res = Map.of(inventories);
    res[inventory.id!] = inventory;
    return res;
  }
}

class InventoryCubitState extends Equatable {
  final Map<int, Inventory> inventories;
  final int? selectedInventoryId;
  final List<Category> categories;
  final InventorySorting sorting;
  final List<InventoryItem> selectedListItems;
  final Inventory? _selectedInventory;

  const InventoryCubitState._({
    this.inventories = const {},
    this.categories = const [],
    this.sorting = InventorySorting.alphabetical,
    this.selectedListItems = const [],
    this.selectedInventoryId = null,
  }) : this._selectedInventory = null;

  InventoryCubitState({
    this.inventories = const {},
    required this.selectedInventoryId,
    this.categories = const [],
    this.sorting = InventorySorting.alphabetical,
    this.selectedListItems = const [],
  }) : _selectedInventory = inventories[selectedInventoryId];

  Inventory? get selectedInventory => _selectedInventory;

  InventoryCubitState copyWith({
    Map<int, Inventory>? inventories,
    int? selectedInventoryId,
    List<Category>? categories,
    InventorySorting? sorting,
    List<InventoryItem>? selectedListItems,
  }) =>
      InventoryCubitState(
        inventories: inventories ?? this.inventories,
        selectedInventoryId: selectedInventoryId ?? this.selectedInventoryId,
        categories: categories ?? this.categories,
        sorting: sorting ?? this.sorting,
        selectedListItems: selectedListItems ?? this.selectedListItems,
      );

  @override
  List<Object?> get props => [
        inventories,
        selectedInventoryId,
        categories,
        sorting,
        selectedListItems,
      ];
}

class LoadingInventoryCubitState extends InventoryCubitState {
  const LoadingInventoryCubitState({
    super.sorting,
    super.selectedInventoryId,
    super.inventories,
    super.categories,
    super.selectedListItems,
  }) : super._();

  @override
  InventoryCubitState copyWith({
    Map<int, Inventory>? inventories,
    int? selectedInventoryId,
    List<InventoryItem>? listItems,
    List<ItemWithDescription>? recentItems,
    List<Category>? categories,
    InventorySorting? sorting,
    List<InventoryItem>? selectedListItems,
  }) =>
      LoadingInventoryCubitState(
        sorting: sorting ?? this.sorting,
        inventories: inventories ?? this.inventories,
        selectedInventoryId: selectedInventoryId ?? this.selectedInventoryId,
        categories: categories ?? this.categories,
        selectedListItems: selectedListItems ?? this.selectedListItems,
      );
}

class SearchInventoryCubitState extends InventoryCubitState {
  final String query;
  final List<Item> result;

  SearchInventoryCubitState({
    super.inventories = const {},
    required super.selectedInventoryId,
    super.categories = const [],
    super.sorting = InventorySorting.alphabetical,
    this.query = "",
    this.result = const [],
    super.selectedListItems,
  });

  @override
  InventoryCubitState copyWith({
    Map<int, Inventory>? inventories,
    int? selectedInventoryId,
    List<Category>? categories,
    InventorySorting? sorting,
    List<Item>? result,
    List<InventoryItem>? selectedListItems,
  }) =>
      SearchInventoryCubitState(
        inventories: inventories ?? this.inventories,
        selectedInventoryId: selectedInventoryId ?? this.selectedInventoryId,
        sorting: sorting ?? this.sorting,
        categories: categories ?? this.categories,
        query: query,
        result: result ?? this.result,
        selectedListItems: selectedListItems ?? this.selectedListItems,
      );

  @override
  List<Object?> get props => super.props + [result, query];
}
