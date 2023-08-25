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
  int Function() recentItemCountProvider;

  String get query => (state is SearchShoppinglistCubitState)
      ? (state as SearchShoppinglistCubitState).query
      : "";

  ShoppinglistCubit(this.household, this.recentItemCountProvider)
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
        shoppinglist: ShoppingList.fromJson(data["shoppinglist"]),
        item: item,
      ),
      forceOffline: true,
      saveTransaction: false,
    );
    if (state.selectedShoppinglist == null ||
        data["shoppinglist"]["id"] != state.selectedShoppinglist?.id) return;
    addLocally(
      ShoppinglistItem.fromJson(data["item"]),
    );
  }

  void onShoppinglistItemRemove(dynamic data) {
    final item = ShoppinglistItem.fromJson(data["item"]);
    TransactionHandler.getInstance().runTransaction(
      TransactionShoppingListDeleteItem(
        shoppinglist: ShoppingList.fromJson(data["shoppinglist"]),
        item: item,
      ),
      forceOffline: true,
      saveTransaction: false,
    );
    if (state.selectedShoppinglist == null ||
        data["shoppinglist"]["id"] != state.selectedShoppinglist?.id ||
        !state.listItems.map((e) => e.id).contains(data["item"]["id"])) return;
    removeLocally(item);
  }

  Future<void> search(String query) => refresh(query: query);

  Future<void> add(Item item) async {
    final _state = state;
    addLocally(ShoppinglistItem.fromItem(item: item));
    if (_state.selectedShoppinglist == null) return;
    await TransactionHandler.getInstance()
        .runTransaction(TransactionShoppingListAddItem(
      shoppinglist: _state.selectedShoppinglist!,
      item: item,
    ));
    await refresh(query: '');
  }

  void addLocally(ShoppinglistItem item) {
    final _state = state;
    if (_state.selectedShoppinglist == null) return;
    final l = List.of(_state.listItems);
    l.removeWhere((e) => e.id == item.id);
    l.add(item);
    ShoppinglistSorting.sortShoppinglistItems(l, state.sorting);
    final recent = List.of(_state.recentItems);
    recent.removeWhere((e) => e.id == item.id);
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
      emit(_state.copyWith(listItems: l, recentItems: recent, result: result));
    } else {
      emit(state.copyWith(listItems: l, recentItems: recent));
    }
  }

  Future<void> remove(ShoppinglistItem item) async {
    final _state = state;
    removeLocally(item);
    if (!await TransactionHandler.getInstance()
        .runTransaction(TransactionShoppingListDeleteItem(
      shoppinglist: _state.selectedShoppinglist!,
      item: item,
    ))) {
      await refresh();
    }
  }

  void removeLocally(ShoppinglistItem item) {
    final _state = state;
    if (_state.selectedShoppinglist == null) return;
    final l = List.of(_state.listItems);
    l.remove(item);
    final recent = List.of(_state.recentItems);
    recent.insert(0, item);
    if (recent.length > recentItemCountProvider()) {
      recent.removeLast();
    }
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
      emit(_state.copyWith(listItems: l, recentItems: recent, result: result));
    } else {
      emit(state.copyWith(listItems: l, recentItems: recent));
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
    final l = List.of(_state.listItems);
    l.removeWhere(_state.selectedListItems.contains);
    final recent = List.of(_state.recentItems);
    recent.insertAll(0, _state.selectedListItems);
    if (recent.length > recentItemCountProvider()) {
      recent.removeRange(recentItemCountProvider(), recent.length);
    }

    if (_state is SearchShoppinglistCubitState) {
      final result = List.of(_state.result);
      for (final item in _state.selectedListItems) {
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
      }
      emit(_state.copyWith(
        listItems: l,
        recentItems: recent,
        result: result,
        selectedListItems: [],
      ));
    } else {
      emit(state
          .copyWith(listItems: l, recentItems: recent, selectedListItems: []));
    }
    if (!await TransactionHandler.getInstance()
        .runTransaction(TransactionShoppingListDeleteItems(
      shoppinglist: _state.selectedShoppinglist!,
      items: _state.selectedListItems,
    ))) {
      await refresh();
    }
  }

  void incrementSorting() {
    setSorting(ShoppinglistSorting
        .values[(state.sorting.index + 1) % ShoppinglistSorting.values.length]);
  }

  void setSorting(ShoppinglistSorting sorting, [bool savePreference = true]) {
    if (state is! SearchShoppinglistCubitState && state.listItems != const []) {
      ShoppinglistSorting.sortShoppinglistItems(state.listItems, sorting);
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
      selectedShoppinglist: shoppingList,
      recentItems: [],
      listItems: [],
    ));
    refresh();
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
    final shoppingLists = await TransactionHandler.getInstance().runTransaction(
      TransactionShoppingListGet(household: household),
      forceOffline: true,
    );

    final shoppinglist =
        state.selectedShoppinglist ?? shoppingLists.firstOrNull;

    if (shoppinglist == null) return;

    Future<List<ShoppinglistItem>> items =
        TransactionHandler.getInstance().runTransaction(
      TransactionShoppingListGetItems(
        shoppinglist: shoppinglist,
        sorting: state.sorting,
      ),
      forceOffline: true,
    );

    Future<List<Category>> categories =
        TransactionHandler.getInstance().runTransaction(
      TransactionCategoriesGet(household: household),
      forceOffline: true,
    );

    final recent = TransactionHandler.getInstance().runTransaction(
      TransactionShoppingListGetRecentItems(
        shoppinglist: shoppinglist,
        itemsCount: recentItemCountProvider(),
      ),
      forceOffline: true,
    );
    List<ShoppinglistItem> loadedShoppinglistItems = await items;
    final resState = ShoppinglistCubitState(
      shoppinglists: shoppingLists,
      selectedShoppinglist: shoppinglist,
      listItems: loadedShoppinglistItems,
      recentItems: await recent,
      categories: await categories,
      sorting: state.sorting,
      selectedListItems: state.selectedListItems
          .map((e) => (loadedShoppinglistItems)
              .firstWhereOrNull((item) => item.id == e.id))
          .whereNotNull()
          .toList(),
    );

    if (state is LoadingShoppinglistCubitState &&
        loadedShoppinglistItems.isNotEmpty) {
      emit(resState);
    }
  }

  // ignore: long-method
  Future<void> _refresh([String? query]) async {
    // Get required information
    late ShoppinglistCubitState resState;
    if (state.recentItems.isEmpty &&
        state.listItems.isEmpty &&
        (query == null || query.isEmpty)) {
      emit(LoadingShoppinglistCubitState(
        selectedShoppinglist: state.selectedShoppinglist,
        shoppinglists: state.shoppinglists,
        sorting: state.sorting,
        categories: state.categories,
        selectedListItems: state.selectedListItems,
      ));
    }

    final shoppingLists = await TransactionHandler.getInstance()
        .runTransaction(TransactionShoppingListGet(household: household));

    final shoppinglist =
        state.selectedShoppinglist ?? shoppingLists.firstOrNull;

    if (shoppinglist == null) return;

    Future<List<ShoppinglistItem>> items =
        TransactionHandler.getInstance().runTransaction(
      TransactionShoppingListGetItems(
        shoppinglist: shoppinglist,
        sorting: state.sorting,
      ),
    );

    Future<List<Category>> categories = TransactionHandler.getInstance()
        .runTransaction(TransactionCategoriesGet(household: household));

    if (query != null && query.isNotEmpty) {
      // Split query into name and description
      final splitIndex = query.indexOf(',');
      String queryName = query;
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
      List<ShoppinglistItem> loadedShoppinglistItems = await items;

      _mergeShoppinglistItems(loadedItems, loadedShoppinglistItems);
      if (loadedItems.isEmpty ||
          loadedItems[0].name.toLowerCase() != queryName.toLowerCase()) {
        loadedItems.add(ItemWithDescription(
          name: queryName,
          description: queryDescription ?? '',
        ));
      }
      resState = SearchShoppinglistCubitState(
        shoppinglists: shoppingLists,
        selectedShoppinglist: shoppinglist,
        result: loadedItems,
        query: query,
        listItems: loadedShoppinglistItems,
        categories: await categories,
        sorting: state.sorting,
        recentItems: state.recentItems,
        selectedListItems: state.selectedListItems
            .map((e) => loadedShoppinglistItems
                .firstWhereOrNull((item) => item.id == e.id))
            .whereNotNull()
            .toList(),
      );
    } else {
      final recent = TransactionHandler.getInstance()
          .runTransaction(TransactionShoppingListGetRecentItems(
        shoppinglist: shoppinglist,
        itemsCount: recentItemCountProvider(),
      ));
      List<ShoppinglistItem> loadedShoppinglistItems = await items;
      resState = ShoppinglistCubitState(
        shoppinglists: shoppingLists,
        selectedShoppinglist: shoppinglist,
        listItems: loadedShoppinglistItems,
        recentItems: await recent,
        categories: await categories,
        sorting: state.sorting,
        selectedListItems: state.selectedListItems
            .map((e) => (loadedShoppinglistItems)
                .firstWhereOrNull((item) => item.id == e.id))
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
    List<ShoppinglistItem> shoppinglist,
  ) {
    if (shoppinglist.isEmpty) return;
    for (int i = 0; i < items.length; i++) {
      final shoppinglistItem =
          shoppinglist.firstWhereOrNull((e) => e.id == items[i].id);
      if (shoppinglistItem != null) {
        items.removeAt(i);
        items.insert(i, shoppinglistItem);
      }
    }
  }
}

class ShoppinglistCubitState extends Equatable {
  final List<ShoppingList> shoppinglists;
  final ShoppingList? selectedShoppinglist;
  final List<ShoppinglistItem> listItems;
  final List<ItemWithDescription> recentItems;
  final List<Category> categories;
  final ShoppinglistSorting sorting;
  final List<ShoppinglistItem> selectedListItems;

  const ShoppinglistCubitState({
    this.shoppinglists = const [],
    required this.selectedShoppinglist,
    this.listItems = const [],
    this.recentItems = const [],
    this.categories = const [],
    this.sorting = ShoppinglistSorting.alphabetical,
    this.selectedListItems = const [],
  });

  ShoppinglistCubitState copyWith({
    List<ShoppingList>? shoppinglists,
    ShoppingList? selectedShoppinglist,
    List<ShoppinglistItem>? listItems,
    List<ItemWithDescription>? recentItems,
    List<Category>? categories,
    ShoppinglistSorting? sorting,
    List<ShoppinglistItem>? selectedListItems,
  }) =>
      ShoppinglistCubitState(
        shoppinglists: shoppinglists ?? this.shoppinglists,
        selectedShoppinglist: selectedShoppinglist ?? this.selectedShoppinglist,
        listItems: listItems ?? this.listItems,
        recentItems: recentItems ?? this.recentItems,
        categories: categories ?? this.categories,
        sorting: sorting ?? this.sorting,
        selectedListItems: selectedListItems ?? this.selectedListItems,
      );

  @override
  List<Object?> get props => [
        shoppinglists,
        selectedShoppinglist,
        listItems,
        recentItems,
        categories,
        sorting,
        selectedListItems,
      ];
}

class LoadingShoppinglistCubitState extends ShoppinglistCubitState {
  const LoadingShoppinglistCubitState({
    super.sorting,
    super.selectedShoppinglist,
    super.shoppinglists,
    super.categories,
    super.selectedListItems,
  });

  @override
  // ignore: long-parameter-list
  ShoppinglistCubitState copyWith({
    List<ShoppingList>? shoppinglists,
    ShoppingList? selectedShoppinglist,
    List<ShoppinglistItem>? listItems,
    List<ItemWithDescription>? recentItems,
    List<Category>? categories,
    ShoppinglistSorting? sorting,
    List<ShoppinglistItem>? selectedListItems,
  }) =>
      LoadingShoppinglistCubitState(
        sorting: sorting ?? this.sorting,
        shoppinglists: shoppinglists ?? this.shoppinglists,
        selectedShoppinglist: selectedShoppinglist ?? this.selectedShoppinglist,
        categories: categories ?? this.categories,
        selectedListItems: selectedListItems ?? this.selectedListItems,
      );
}

class SearchShoppinglistCubitState extends ShoppinglistCubitState {
  final String query;
  final List<Item> result;

  const SearchShoppinglistCubitState({
    super.shoppinglists = const [],
    required super.selectedShoppinglist,
    super.listItems = const [],
    super.recentItems = const [],
    super.categories = const [],
    super.sorting = ShoppinglistSorting.alphabetical,
    this.query = "",
    this.result = const [],
    super.selectedListItems,
  });

  @override
  // ignore: long-parameter-list
  ShoppinglistCubitState copyWith({
    List<ShoppingList>? shoppinglists,
    ShoppingList? selectedShoppinglist,
    List<ShoppinglistItem>? listItems,
    List<ItemWithDescription>? recentItems,
    List<Category>? categories,
    ShoppinglistSorting? sorting,
    List<Item>? result,
    List<ShoppinglistItem>? selectedListItems,
  }) =>
      SearchShoppinglistCubitState(
        shoppinglists: shoppinglists ?? this.shoppinglists,
        selectedShoppinglist: selectedShoppinglist ?? this.selectedShoppinglist,
        listItems: listItems ?? this.listItems,
        recentItems: recentItems ?? this.recentItems,
        sorting: sorting ?? this.sorting,
        categories: categories ?? this.categories,
        query: query,
        result: result ?? this.result,
        selectedListItems: selectedListItems ?? this.selectedListItems,
      );

  @override
  List<Object?> get props => super.props + [result, query];
}
