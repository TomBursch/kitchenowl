import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/enums/shoppinglist_sorting.dart';
import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/storage/storage.dart';
import 'package:kitchenowl/services/transactions/category.dart';
import 'package:kitchenowl/services/transactions/shoppinglist.dart';
import 'package:kitchenowl/services/transaction_handler.dart';

class ShoppinglistCubit extends Cubit<ShoppinglistCubitState> {
  final Household household;
  Future<void>? _refreshThread;
  String? _refreshCurrentQuery;

  String get query => (state is SearchShoppinglistCubitState)
      ? (state as SearchShoppinglistCubitState).query
      : "";

  ShoppinglistCubit(this.household)
      : super(const LoadingShoppinglistCubitState()) {
    PreferenceStorage.getInstance().readInt(key: 'itemSorting').then((i) {
      if (i != null && state.sorting.index != i) {
        setSorting(
          ShoppinglistSorting.values[i % ShoppinglistSorting.values.length],
          false,
        );
      }
    });
    _initialLoad();
    refresh();
    ApiService.getInstance().onShoppinglistItemAdd(onShoppinglistItemAdd);
    ApiService.getInstance().onShoppinglistItemRemove(onShoppinglistItemRemove);
  }

  @override
  Future<void> close() async {
    ApiService.getInstance().offShoppinglistItemAdd(onShoppinglistItemAdd);
    ApiService.getInstance()
        .offShoppinglistItemRemove(onShoppinglistItemRemove);
    super.close();
  }

  void onShoppinglistItemAdd(dynamic data) {
    final item = ShoppinglistItem.fromJson(data["item"]);
    TransactionHandler.getInstance().runTransaction(
      TransactionShoppingListAddItem(
        household: household,
        shoppinglist: ShoppingList.fromJson(data["shoppinglist"]),
        item: item,
      ),
      forceOffline: true,
      saveTransaction: false,
    );
    addLocally(
      ShoppinglistItem.fromJson(data["item"]),
      data["shoppinglist"]["id"],
    );
  }

  void onShoppinglistItemRemove(dynamic data) {
    final item = ShoppinglistItem.fromJson(data["item"]);
    TransactionHandler.getInstance().runTransaction(
      TransactionShoppingListRemoveItem(
        household: household,
        shoppinglist: ShoppingList.fromJson(data["shoppinglist"]),
        item: item,
      ),
      forceOffline: true,
      saveTransaction: false,
    );
    removeLocally(item, data["shoppinglist"]["id"]);
  }

  Future<void> search(String query) => refresh(query: query);

  Future<void> add(Item item) async {
    final _state = state;
    addLocally(ShoppinglistItem.fromItem(item: item));
    if (_state.selectedShoppinglist == null) return;
    await TransactionHandler.getInstance()
        .runTransaction(TransactionShoppingListAddItem(
      household: household,
      shoppinglist: _state.selectedShoppinglist!,
      item: item,
    ));
    await refresh(query: '');
  }

  void addLocally(ShoppinglistItem item, [int? shoppinglistId]) {
    final _state = state;
    shoppinglistId ??= _state.selectedShoppinglist?.id;
    if (shoppinglistId == null) return;
    final shoppinglist = _state.shoppinglists[shoppinglistId];
    if (shoppinglist == null) return;

    final l = List.of(shoppinglist.items);
    l.removeWhere((e) => e.id == item.id || e.name == item.name);
    l.add(item);
    ShoppinglistSorting.sortShoppinglistItems(l, state.sorting);
    final recent = List.of(shoppinglist.recentItems);
    recent.removeWhere((e) => e.name == item.name);
    if (_state is SearchShoppinglistCubitState) {
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
        shoppinglists: _replaceAndUpdateShoppingLists(_state.shoppinglists,
            shoppinglist.copyWith(items: l, recentItems: recent)),
        result: result,
      ));
    } else {
      emit(state.copyWith(
        shoppinglists: _replaceAndUpdateShoppingLists(_state.shoppinglists,
            shoppinglist.copyWith(items: l, recentItems: recent)),
      ));
    }
  }

  Future<void> remove(ShoppinglistItem item) async {
    final _state = state;
    removeLocally(item);
    if (!await TransactionHandler.getInstance()
        .runTransaction(TransactionShoppingListRemoveItem(
      household: household,
      shoppinglist: _state.selectedShoppinglist!,
      item: item,
    ))) {
      await refresh();
    }
  }

  void removeLocally(ShoppinglistItem item, [int? shoppinglistId]) {
    final _state = state;
    shoppinglistId ??= _state.selectedShoppinglist?.id;
    if (shoppinglistId == null) return;
    final shoppinglist = _state.shoppinglists[shoppinglistId];
    if (shoppinglist == null) return;

    final l = List.of(shoppinglist.items);
    l.removeWhere((e) => e.name == item.name);
    final recent = List.of(shoppinglist.recentItems);
    recent.removeWhere((e) => e.name == item.name);
    recent.insert(0, ItemWithDescription.fromItem(item: item));
    if (_state is SearchShoppinglistCubitState) {
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
          shoppinglists: _replaceAndUpdateShoppingLists(_state.shoppinglists,
              shoppinglist.copyWith(items: l, recentItems: recent)),
          result: result));
    } else {
      emit(state.copyWith(
        shoppinglists: _replaceAndUpdateShoppingLists(_state.shoppinglists,
            shoppinglist.copyWith(items: l, recentItems: recent)),
      ));
    }
  }

  void selectItem(ShoppinglistItem item) {
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
    if (_state.selectedShoppinglist == null ||
        _state.selectedListItems.isEmpty) {
      return;
    }
    final selectedItems = _state.selectedListItems
        .sorted((a, b) => a.id?.compareTo(b.id ?? 0) ?? -1);
    final l = List.of(_state.selectedShoppinglist!.items);
    l.removeWhere(selectedItems.contains);
    final recent = List.of(_state.selectedShoppinglist!.recentItems);
    recent.insertAll(
      0,
      selectedItems.map((e) => ItemWithDescription.fromItem(item: e)),
    );

    if (_state is SearchShoppinglistCubitState) {
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
        shoppinglists: _replaceAndUpdateShoppingLists(
            _state.shoppinglists,
            _state.selectedShoppinglist!
                .copyWith(items: l, recentItems: recent)),
        result: result,
        selectedListItems: [],
      ));
    } else {
      emit(_state.copyWith(
          shoppinglists: _replaceAndUpdateShoppingLists(
              _state.shoppinglists,
              _state.selectedShoppinglist!
                  .copyWith(items: l, recentItems: recent)),
          selectedListItems: []));
    }
    if (!await TransactionHandler.getInstance()
        .runTransaction(TransactionShoppingListRemoveItems(
      household: household,
      shoppinglist: _state.selectedShoppinglist!,
      items: selectedItems,
    ))) {
      await refresh();
    }
  }

  void incrementSorting() {
    setSorting(ShoppinglistSorting
        .values[(state.sorting.index + 1) % ShoppinglistSorting.values.length]);
  }

  void setSorting(ShoppinglistSorting sorting, [bool savePreference = true]) {
    if (state is! SearchShoppinglistCubitState &&
        state.selectedShoppinglist != null &&
        state.selectedShoppinglist?.items != const []) {
      ShoppinglistSorting.sortShoppinglistItems(
          state.selectedShoppinglist!.items, sorting);
    }
    if (savePreference) {
      PreferenceStorage.getInstance()
          .writeInt(key: 'itemSorting', value: sorting.index);
    }
    emit(state.copyWith(sorting: sorting));
  }

  void setShoppingList(
    ShoppingList shoppingList, [
    bool savePreference = false,
  ]) {
    if (savePreference) {
      PreferenceStorage.getInstance().write(
        key: 'selectedShoppinglist',
        value: jsonEncode(shoppingList.toJsonWithId()),
      );
    }
    emit(state.copyWith(
      selectedShoppinglistId: shoppingList.id,
    ));
  }

  Future<void> refresh({String? query}) {
    final state = this.state;
    if (state is SearchShoppinglistCubitState) {
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

  Future<void> _initialLoad() async {
    final shoppingLists = await TransactionHandler.getInstance()
        .runTransaction(
          TransactionShoppingListGet(household: household),
          forceOffline: true,
        )
        .then((lists) => Map.fromEntries(lists
            .map((e) => e.id != null ? MapEntry(e.id!, e) : null)
            .whereNotNull()));

    final shoppinglist =
        state.selectedShoppinglist ?? shoppingLists.values.firstOrNull;

    if (shoppinglist == null) return;

    Future<List<Category>> categories =
        TransactionHandler.getInstance().runTransaction(
      TransactionCategoriesGet(household: household),
      forceOffline: true,
    );

    final resState = LoadingShoppinglistCubitState(
      shoppinglists: shoppingLists,
      selectedShoppinglistId: shoppinglist.id,
      categories: await categories,
      sorting: state.sorting,
      selectedListItems: state.selectedListItems
          .map((e) =>
              shoppinglist.items.firstWhereOrNull((item) => item.id == e.id))
          .whereNotNull()
          .toList(),
    );

    if (state is LoadingShoppinglistCubitState) {
      emit(resState);
    }
  }

  Future<void> _refresh([String? query]) async {
    // Get required information
    late ShoppinglistCubitState resState;
    if (state.selectedShoppinglistId == null ||
        (state.selectedShoppinglist?.items.isEmpty ?? true) &&
            (state.selectedShoppinglist?.recentItems.isEmpty ?? true) &&
            (query == null || query.isEmpty)) {
      emit(LoadingShoppinglistCubitState(
        selectedShoppinglistId: state.selectedShoppinglistId,
        shoppinglists: state.shoppinglists,
        sorting: state.sorting,
        categories: state.categories,
        selectedListItems: state.selectedListItems,
      ));
    }

    final shoppingLists = await TransactionHandler.getInstance()
        .runTransaction(TransactionShoppingListGet(household: household))
        .then((lists) => Map.fromEntries(lists
            .map((e) => e.id != null ? MapEntry(e.id!, e) : null)
            .whereNotNull()));

    final selectedShoppinglistId =
        state.selectedShoppinglistId ?? shoppingLists.values.firstOrNull?.id;

    if (selectedShoppinglistId == null) return;

    final shoppinglist = shoppingLists[selectedShoppinglistId];

    Future<List<Category>> categories = TransactionHandler.getInstance()
        .runTransaction(TransactionCategoriesGet(household: household));

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
            TransactionShoppingListSearchItem(
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

      _mergeShoppinglistItems(loadedItems, shoppinglist?.items);
      if (loadedItems.isEmpty ||
          !loadedItems
              .any((e) => e.name.toLowerCase() == queryName.toLowerCase())) {
        loadedItems.add(ItemWithDescription(
          name: queryName,
          description: queryDescription ?? '',
        ));
      }
      resState = SearchShoppinglistCubitState(
        shoppinglists: shoppingLists,
        selectedShoppinglistId: selectedShoppinglistId,
        result: loadedItems,
        query: query,
        categories: await categories,
        sorting: state.sorting,
        selectedListItems: state.selectedListItems
            .map((e) =>
                shoppinglist?.items.firstWhereOrNull((item) => item.id == e.id))
            .whereNotNull()
            .toList(),
      );
    } else {
      resState = ShoppinglistCubitState(
        shoppinglists: shoppingLists,
        selectedShoppinglistId: selectedShoppinglistId,
        categories: await categories,
        sorting: state.sorting,
        selectedListItems: state.selectedListItems
            .map((e) =>
                shoppinglist?.items.firstWhereOrNull((item) => item.id == e.id))
            .whereNotNull()
            .toList(),
      );
    }
    if (query == _refreshCurrentQuery) {
      emit(resState);
      _refreshThread = null;
    }
  }

  void _mergeShoppinglistItems(
    List<Item> items,
    List<ShoppinglistItem>? shoppinglist,
  ) {
    if (shoppinglist == null || shoppinglist.isEmpty) return;
    for (int i = 0; i < items.length; i++) {
      final shoppinglistItem =
          shoppinglist.firstWhereOrNull((e) => e.id == items[i].id);
      if (shoppinglistItem != null) {
        items.removeAt(i);
        items.insert(i, shoppinglistItem);
      }
    }
  }

  Map<int, ShoppingList> _replaceAndUpdateShoppingLists(
      Map<int, ShoppingList> shoppinglists, ShoppingList shoppingList) {
    if (shoppingList.id == null) return shoppinglists;

    final res = Map.of(shoppinglists);
    res[shoppingList.id!] = shoppingList;
    return res;
  }
}

class ShoppinglistCubitState extends Equatable {
  final Map<int, ShoppingList> shoppinglists;
  final int? selectedShoppinglistId;
  final List<Category> categories;
  final ShoppinglistSorting sorting;
  final List<ShoppinglistItem> selectedListItems;
  final ShoppingList? _selectedShoppinglist;

  const ShoppinglistCubitState._({
    this.shoppinglists = const {},
    this.categories = const [],
    this.sorting = ShoppinglistSorting.alphabetical,
    this.selectedListItems = const [],
    this.selectedShoppinglistId = null,
  }) : this._selectedShoppinglist = null;

  ShoppinglistCubitState({
    this.shoppinglists = const {},
    required this.selectedShoppinglistId,
    this.categories = const [],
    this.sorting = ShoppinglistSorting.alphabetical,
    this.selectedListItems = const [],
  }) : _selectedShoppinglist = shoppinglists[selectedShoppinglistId];

  ShoppingList? get selectedShoppinglist => _selectedShoppinglist;

  ShoppinglistCubitState copyWith({
    Map<int, ShoppingList>? shoppinglists,
    int? selectedShoppinglistId,
    List<Category>? categories,
    ShoppinglistSorting? sorting,
    List<ShoppinglistItem>? selectedListItems,
  }) =>
      ShoppinglistCubitState(
        shoppinglists: shoppinglists ?? this.shoppinglists,
        selectedShoppinglistId:
            selectedShoppinglistId ?? this.selectedShoppinglistId,
        categories: categories ?? this.categories,
        sorting: sorting ?? this.sorting,
        selectedListItems: selectedListItems ?? this.selectedListItems,
      );

  @override
  List<Object?> get props => [
        shoppinglists,
        selectedShoppinglistId,
        categories,
        sorting,
        selectedListItems,
      ];
}

class LoadingShoppinglistCubitState extends ShoppinglistCubitState {
  const LoadingShoppinglistCubitState({
    super.sorting,
    super.selectedShoppinglistId,
    super.shoppinglists,
    super.categories,
    super.selectedListItems,
  }) : super._();

  @override
  ShoppinglistCubitState copyWith({
    Map<int, ShoppingList>? shoppinglists,
    int? selectedShoppinglistId,
    List<ShoppinglistItem>? listItems,
    List<ItemWithDescription>? recentItems,
    List<Category>? categories,
    ShoppinglistSorting? sorting,
    List<ShoppinglistItem>? selectedListItems,
  }) =>
      LoadingShoppinglistCubitState(
        sorting: sorting ?? this.sorting,
        shoppinglists: shoppinglists ?? this.shoppinglists,
        selectedShoppinglistId:
            selectedShoppinglistId ?? this.selectedShoppinglistId,
        categories: categories ?? this.categories,
        selectedListItems: selectedListItems ?? this.selectedListItems,
      );
}

class SearchShoppinglistCubitState extends ShoppinglistCubitState {
  final String query;
  final List<Item> result;

  SearchShoppinglistCubitState({
    super.shoppinglists = const {},
    required super.selectedShoppinglistId,
    super.categories = const [],
    super.sorting = ShoppinglistSorting.alphabetical,
    this.query = "",
    this.result = const [],
    super.selectedListItems,
  });

  @override
  ShoppinglistCubitState copyWith({
    Map<int, ShoppingList>? shoppinglists,
    int? selectedShoppinglistId,
    List<Category>? categories,
    ShoppinglistSorting? sorting,
    List<Item>? result,
    List<ShoppinglistItem>? selectedListItems,
  }) =>
      SearchShoppinglistCubitState(
        shoppinglists: shoppinglists ?? this.shoppinglists,
        selectedShoppinglistId:
            selectedShoppinglistId ?? this.selectedShoppinglistId,
        sorting: sorting ?? this.sorting,
        categories: categories ?? this.categories,
        query: query,
        result: result ?? this.result,
        selectedListItems: selectedListItems ?? this.selectedListItems,
      );

  @override
  List<Object?> get props => super.props + [result, query];
}
