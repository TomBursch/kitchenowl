import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/enums/shoppinglist_sorting.dart';
import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/services/storage/storage.dart';
import 'package:kitchenowl/services/transactions/category.dart';
import 'package:kitchenowl/services/transactions/shoppinglist.dart';
import 'package:kitchenowl/services/transaction_handler.dart';

enum ShoppinglistStyle { grid, list }

class ShoppinglistCubit extends Cubit<ShoppinglistCubitState> {
  Future<void>? _refreshThread;
  String? _refreshCurrentQuery;

  String get query => (state is SearchShoppinglistCubitState)
      ? (state as SearchShoppinglistCubitState).query
      : "";

  ShoppinglistCubit() : super(const LoadingShoppinglistCubitState()) {
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
    await TransactionHandler.getInstance()
        .runTransaction(TransactionShoppingListAddItem(
      name: name,
      description: description ?? '',
    ));
    await refresh(query: '');
  }

  Future<void> remove(ShoppinglistItem item) async {
    final _state = state;
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
        .runTransaction(TransactionShoppingListDeleteItem(item: item))) {
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
      emit(const LoadingShoppinglistCubitState());
    }

    Future<List<ShoppinglistItem>> shoppinglist =
        TransactionHandler.getInstance().runTransaction(
      TransactionShoppingListGetItems(sorting: state.sorting),
    );

    Future<List<Category>> categories = TransactionHandler.getInstance()
        .runTransaction(TransactionCategoriesGet());

    if (query != null && query.isNotEmpty) {
      // Split query into name and description
      final splitIndex = query.indexOf(',');
      String queryName = query;
      String queryDescription = '';
      if (splitIndex >= 0) {
        queryName = query.substring(0, splitIndex).trim();
        queryDescription = query.substring(splitIndex + 1).trim();
      }

      Future<List<Item>> items = TransactionHandler.getInstance()
          .runTransaction(
            TransactionShoppingListSearchItem(query: queryName),
          )
          .then((items) => items
              .map((e) => ItemWithDescription.fromItem(
                    item: e,
                    description: queryDescription,
                  ))
              .toList());

      List<Item> loadedItems = await items;
      List<ShoppinglistItem> loadedShoppinglist = await shoppinglist;

      _mergeShoppinglistItems(loadedItems, loadedShoppinglist);
      if (loadedItems.isEmpty ||
          loadedItems[0].name.toLowerCase() != queryName.toLowerCase()) {
        loadedItems.add(ItemWithDescription(
          name: queryName,
          description: queryDescription,
        ));
      }
      resState = SearchShoppinglistCubitState(
        result: loadedItems,
        query: query,
        listItems: loadedShoppinglist,
        categories: await categories,
        style: state.style,
        sorting: state.sorting,
      );
    } else {
      final recent = TransactionHandler.getInstance()
          .runTransaction(TransactionShoppingListGetRecentItems());
      resState = ShoppinglistCubitState(
        listItems: await shoppinglist,
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
  final List<ShoppinglistItem> listItems;
  final List<ItemWithDescription> recentItems;
  final List<Category> categories;
  final ShoppinglistSorting sorting;
  final ShoppinglistStyle style;

  const ShoppinglistCubitState({
    this.listItems = const [],
    this.recentItems = const [],
    this.categories = const [],
    this.sorting = ShoppinglistSorting.alphabetical,
    this.style = ShoppinglistStyle.grid,
  });

  ShoppinglistCubitState copyWith({
    List<ShoppinglistItem>? listItems,
    List<ItemWithDescription>? recentItems,
    List<Category>? categories,
    ShoppinglistSorting? sorting,
    ShoppinglistStyle? style,
  }) =>
      ShoppinglistCubitState(
        listItems: listItems ?? this.listItems,
        recentItems: recentItems ?? this.recentItems,
        categories: categories ?? this.categories,
        sorting: sorting ?? this.sorting,
        style: style ?? this.style,
      );

  @override
  List<Object?> get props =>
      [listItems, recentItems, categories, sorting, style];
}

class LoadingShoppinglistCubitState extends ShoppinglistCubitState {
  const LoadingShoppinglistCubitState({super.style, super.sorting});

  @override
  // ignore: long-parameter-list
  ShoppinglistCubitState copyWith({
    List<ShoppinglistItem>? listItems,
    List<ItemWithDescription>? recentItems,
    List<Category>? categories,
    ShoppinglistSorting? sorting,
    ShoppinglistStyle? style,
  }) =>
      LoadingShoppinglistCubitState(
        sorting: sorting ?? this.sorting,
        style: style ?? this.style,
      );
}

class SearchShoppinglistCubitState extends ShoppinglistCubitState {
  final String query;
  final List<Item> result;

  const SearchShoppinglistCubitState({
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
    List<ShoppinglistItem>? listItems,
    List<ItemWithDescription>? recentItems,
    List<Category>? categories,
    ShoppinglistSorting? sorting,
    ShoppinglistStyle? style,
    List<Item>? result,
  }) =>
      SearchShoppinglistCubitState(
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
