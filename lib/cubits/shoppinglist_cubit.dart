import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/enums/shoppinglist_sorting.dart';
import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/services/storage/storage.dart';
import 'package:kitchenowl/services/transactions/category.dart';
import 'package:kitchenowl/services/transactions/shoppinglist.dart';
import 'package:kitchenowl/services/transaction_handler.dart';

enum ShoppinglistStyle { grid, list }

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
    refresh();
  }

  Future<void> search(String query) => refresh(query: query);

  Future<void> add(String name, [String? description]) async {
    if (state.selectedShoppinglist == null) return;
    await TransactionHandler.getInstance()
        .runTransaction(TransactionShoppingListAddItem(
      shoppinglist: state.selectedShoppinglist!,
      name: name,
      description: description ?? '',
    ));
    await refresh(query: '');
  }

  Future<void> remove(ShoppinglistItem item) async {
    final _state = state;
    if (_state.selectedShoppinglist == null) return;
    final l = List.of(_state.listItems);
    l.remove(item);
    final recent = List.of(_state.recentItems);
    recent.insert(0, item);
    if (recent.length > 8) {
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
    if (!await TransactionHandler.getInstance()
        .runTransaction(TransactionShoppingListDeleteItem(
      shoppinglist: _state.selectedShoppinglist!,
      item: item,
    ))) {
      await refresh();
    }
  }

  void incrementSorting() {
    setSorting(ShoppinglistSorting
        .values[(state.sorting.index + 1) % ShoppinglistSorting.values.length]);
  }

  void incrementStyle() {
    setStyle(ShoppinglistStyle
        .values[(state.style.index + 1) % ShoppinglistStyle.values.length]);
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

  void setStyle(ShoppinglistStyle style) {
    emit(state.copyWith(style: style));
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
        style: state.style,
        categories: state.categories,
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
      String queryDescription = '';
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
          description: queryDescription,
        ));
      }
      resState = SearchShoppinglistCubitState(
        shoppinglists: shoppingLists,
        selectedShoppinglist: shoppinglist,
        result: loadedItems,
        query: query,
        listItems: loadedShoppinglistItems,
        categories: await categories,
        style: state.style,
        sorting: state.sorting,
        recentItems: state.recentItems,
      );
    } else {
      final recent = TransactionHandler.getInstance()
          .runTransaction(TransactionShoppingListGetRecentItems(
        shoppinglist: shoppinglist,
      ));
      resState = ShoppinglistCubitState(
        shoppinglists: shoppingLists,
        selectedShoppinglist: shoppinglist,
        listItems: await items,
        recentItems: await recent,
        categories: await categories,
        sorting: state.sorting,
        style: state.style,
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
  final ShoppinglistStyle style;

  const ShoppinglistCubitState({
    this.shoppinglists = const [],
    required this.selectedShoppinglist,
    this.listItems = const [],
    this.recentItems = const [],
    this.categories = const [],
    this.sorting = ShoppinglistSorting.alphabetical,
    this.style = ShoppinglistStyle.grid,
  });

  ShoppinglistCubitState copyWith({
    List<ShoppingList>? shoppinglists,
    ShoppingList? selectedShoppinglist,
    List<ShoppinglistItem>? listItems,
    List<ItemWithDescription>? recentItems,
    List<Category>? categories,
    ShoppinglistSorting? sorting,
    ShoppinglistStyle? style,
  }) =>
      ShoppinglistCubitState(
        shoppinglists: shoppinglists ?? this.shoppinglists,
        selectedShoppinglist: selectedShoppinglist ?? this.selectedShoppinglist,
        listItems: listItems ?? this.listItems,
        recentItems: recentItems ?? this.recentItems,
        categories: categories ?? this.categories,
        sorting: sorting ?? this.sorting,
        style: style ?? this.style,
      );

  @override
  List<Object?> get props => [
        shoppinglists,
        selectedShoppinglist,
        listItems,
        recentItems,
        categories,
        sorting,
        style,
      ];
}

class LoadingShoppinglistCubitState extends ShoppinglistCubitState {
  const LoadingShoppinglistCubitState({
    super.style,
    super.sorting,
    super.selectedShoppinglist,
    super.shoppinglists,
    super.categories,
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
    ShoppinglistStyle? style,
  }) =>
      LoadingShoppinglistCubitState(
        sorting: sorting ?? this.sorting,
        style: style ?? this.style,
        shoppinglists: shoppinglists ?? this.shoppinglists,
        selectedShoppinglist: selectedShoppinglist ?? this.selectedShoppinglist,
        categories: categories ?? this.categories,
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
    super.style = ShoppinglistStyle.grid,
    this.query = "",
    this.result = const [],
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
    ShoppinglistStyle? style,
    List<Item>? result,
  }) =>
      SearchShoppinglistCubitState(
        shoppinglists: shoppinglists ?? this.shoppinglists,
        selectedShoppinglist: selectedShoppinglist ?? this.selectedShoppinglist,
        listItems: listItems ?? this.listItems,
        recentItems: recentItems ?? this.recentItems,
        sorting: sorting ?? this.sorting,
        categories: categories ?? this.categories,
        style: style ?? this.style,
        query: query,
        result: result ?? this.result,
      );

  @override
  List<Object?> get props => super.props + [result, query];
}
