import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/services/transactions/category.dart';
import 'package:kitchenowl/services/transactions/shoppinglist.dart';
import 'package:kitchenowl/services/transaction_handler.dart';

enum ShoppinglistSorting { alphabetical, algorithmic, category }

enum ShoppinglistStyle { grid, list }

class ShoppinglistCubit extends Cubit<ShoppinglistCubitState> {
  bool _refreshLock = false;

  String get query => (state is SearchShoppinglistCubitState)
      ? (state as SearchShoppinglistCubitState).query
      : "";

  ShoppinglistCubit() : super(const LoadingShoppinglistCubitState()) {
    refresh();
  }

  Future<void> search(String query) => refresh(query);

  Future<void> add(String name, [String? description]) async {
    await TransactionHandler.getInstance()
        .runTransaction(TransactionShoppingListAddItem(
      name: name,
      description: description ?? '',
    ));
    await refresh('');
  }

  Future<void> remove(ShoppinglistItem item) async {
    await TransactionHandler.getInstance()
        .runTransaction(TransactionShoppingListDeleteItem(item: item));
    await refresh();
  }

  void incrementSorting() {
    setSorting(ShoppinglistSorting
        .values[(state.sorting.index + 1) % ShoppinglistSorting.values.length]);
  }

  void incrementStyle() {
    setStyle(ShoppinglistStyle
        .values[(state.style.index + 1) % ShoppinglistStyle.values.length]);
  }

  void setSorting(ShoppinglistSorting sorting) {
    if (state is! SearchShoppinglistCubitState) {
      _sortShoppinglistItems(state.listItems, sorting);
    }
    emit(state.copyWith(sorting: sorting));
  }

  void setStyle(ShoppinglistStyle style) {
    emit(state.copyWith(style: style));
  }

  // ignore: long-method
  Future<void> refresh([String? query]) async {
    if (_refreshLock) return;
    _refreshLock = true;
    // Get required information
    final state = this.state;
    if (state.recentItems.isEmpty && state.listItems.isEmpty) {
      emit(const LoadingShoppinglistCubitState());
    }

    if (state is SearchShoppinglistCubitState) query = query ?? state.query;
    final sorting = state.sorting;
    Future<List<ShoppinglistItem>> shoppinglist =
        TransactionHandler.getInstance()
            .runTransaction(TransactionShoppingListGetItems());

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
      emit(SearchShoppinglistCubitState(
        result: loadedItems,
        query: query,
        listItems: loadedShoppinglist,
        categories: await categories,
        style: state.style,
        sorting: state.sorting,
      ));
    } else {
      // Sort if needed
      if (sorting != ShoppinglistSorting.alphabetical) {
        shoppinglist = shoppinglist.then((shoppinglist) {
          _sortShoppinglistItems(shoppinglist, sorting);

          return shoppinglist;
        });
      }

      final recent = TransactionHandler.getInstance()
          .runTransaction(TransactionShoppingListGetRecentItems());
      emit(ShoppinglistCubitState(
        listItems: await shoppinglist,
        recentItems: await recent,
        categories: await categories,
        sorting: sorting,
        style: state.style,
      ));
    }
    _refreshLock = false;
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

  void _sortShoppinglistItems(
    List<ShoppinglistItem> shoppinglist,
    ShoppinglistSorting sorting,
  ) {
    switch (sorting) {
      case ShoppinglistSorting.alphabetical:
        shoppinglist.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ShoppinglistSorting.algorithmic:
        shoppinglist.sort((a, b) {
          final int ordering = a.ordering.compareTo(b.ordering);
          // Ordering of 0 means not sortable and should be at the back
          if (ordering != 0 && a.ordering == 0) return 1;
          if (ordering != 0 && b.ordering == 0) return -1;

          return ordering;
        });
        break;
      case ShoppinglistSorting.category:
        shoppinglist.sort((a, b) {
          if (b.category == null) return a.name.compareTo(b.name);
          final int ordering =
              a.category?.name.compareTo(b.category!.name) ?? 0;
          if (ordering == 0) return a.name.compareTo(b.name);

          return ordering;
        });
        break;
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
      listItems.cast<Object>() + recentItems + categories + [sorting, style];
}

class LoadingShoppinglistCubitState extends ShoppinglistCubitState {
  const LoadingShoppinglistCubitState();
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
  }) =>
      SearchShoppinglistCubitState(
        listItems: listItems ?? this.listItems,
        recentItems: recentItems ?? this.recentItems,
        sorting: sorting ?? this.sorting,
        categories: categories ?? this.categories,
        style: style ?? this.style,
        query: query,
        result: result,
      );

  @override
  List<Object?> get props => super.props + result + <Object>[query];
}
