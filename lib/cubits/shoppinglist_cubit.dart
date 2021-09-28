import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/services/transactions/shoppinglist.dart';
import 'package:kitchenowl/services/transaction_handler.dart';

enum ShoppinglistSorting { alphabetical, algorithmic }

class ShoppinglistCubit extends Cubit<ShoppinglistCubitState> {
  String get query => (state is SearchShoppinglistCubitState)
      ? (state as SearchShoppinglistCubitState).query
      : "";

  ShoppinglistCubit() : super(const ShoppinglistCubitState()) {
    refresh();
  }

  Future<void> search(String query) => refresh(query ?? '');

  Future<void> add(String name, [String description]) async {
    await TransactionHandler.getInstance().runTransaction(
        TransactionShoppingListAddItem(name: name, description: description));
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

  void setSorting(ShoppinglistSorting sorting) {
    if (state is! SearchShoppinglistCubitState) {
      _sortShoppinglistItems(state.listItems, sorting);
    }
    emit(state.copyWith(sorting: sorting));
  }

  Future<void> refresh([String query]) async {
    // Get required information
    final state = this.state;
    if (state is SearchShoppinglistCubitState) query = query ?? state.query;
    final sorting = state.sorting;
    List<ShoppinglistItem> shoppinglist = await TransactionHandler.getInstance()
            .runTransaction(TransactionShoppingListGetItems()) ??
        const [];

    if (query != null && query.isNotEmpty) {
      // Split query into name and description
      final splitIndex = query.indexOf(',');
      String queryName = query;
      String queryDescription = '';
      if (splitIndex >= 0) {
        queryName = query.substring(0, splitIndex).trim();
        queryDescription = query.substring(splitIndex + 1).trim();
      }

      List<Item> items = (await TransactionHandler.getInstance().runTransaction(
              TransactionShoppingListSearchItem(query: queryName)))
          .map((e) => ItemWithDescription.fromItem(
              item: e, description: queryDescription))
          .toList();
      items ??= shoppinglist
          .where((e) => e.name.contains(queryName))
          .cast<Item>()
          .toList();
      _mergeShoppinglistItems(items, shoppinglist);
      if (items.isEmpty ||
          items[0].name.toLowerCase() != queryName.toLowerCase()) {
        items.add(ItemWithDescription(
            name: queryName, description: queryDescription));
      }
      emit(SearchShoppinglistCubitState(
        result: items,
        query: query,
        listItems: shoppinglist,
      ));
    } else {
      // Sort if needed
      if (sorting != ShoppinglistSorting.alphabetical) {
        _sortShoppinglistItems(shoppinglist, sorting);
      }

      final recent = await TransactionHandler.getInstance()
          .runTransaction(TransactionShoppingListGetRecentItems());
      emit(ShoppinglistCubitState(shoppinglist, recent, sorting));
    }
  }

  void _mergeShoppinglistItems(
      List<Item> items, List<ShoppinglistItem> shoppinglist) {
    if (shoppinglist == null || shoppinglist.isEmpty) return;
    for (int i = 0; i < items.length; i++) {
      final shoppinglistItem = shoppinglist
          .firstWhere((e) => e.id == items[i].id, orElse: () => null);
      if (shoppinglistItem != null) {
        items.removeAt(i);
        items.insert(i, shoppinglistItem);
      }
    }
  }

  void _sortShoppinglistItems(
      List<ShoppinglistItem> shoppinglist, ShoppinglistSorting sorting) {
    switch (sorting) {
      case ShoppinglistSorting.alphabetical:
        shoppinglist.sort((a, b) => a.name.compareTo(b.name));
        break;
      case ShoppinglistSorting.algorithmic:
        shoppinglist.sort((a, b) => a.ordering.compareTo(b.ordering));
        break;
    }
  }
}

class ShoppinglistCubitState extends Equatable {
  final List<ShoppinglistItem> listItems;
  final List<Item> recentItems;
  final ShoppinglistSorting sorting;

  const ShoppinglistCubitState([
    this.listItems = const [],
    this.recentItems = const [],
    this.sorting = ShoppinglistSorting.alphabetical,
  ]);

  ShoppinglistCubitState copyWith({
    List<ShoppinglistItem> listItems,
    List<Item> recentItems,
    ShoppinglistSorting sorting,
  }) =>
      ShoppinglistCubitState(
        listItems ?? this.listItems,
        recentItems ?? this.recentItems,
        sorting ?? this.sorting,
      );

  @override
  List<Object> get props => listItems.cast<Object>() + recentItems + [sorting];
}

class SearchShoppinglistCubitState extends ShoppinglistCubitState {
  final String query;
  final List<Item> result;

  const SearchShoppinglistCubitState({
    List<ShoppinglistItem> listItems = const [],
    List<ShoppinglistItem> recentItems = const [],
    ShoppinglistSorting sorting = ShoppinglistSorting.alphabetical,
    this.query = "",
    this.result = const [],
  }) : super(listItems, recentItems, sorting);

  @override
  ShoppinglistCubitState copyWith({
    List<ShoppinglistItem> listItems,
    List<Item> recentItems,
    ShoppinglistSorting sorting,
  }) =>
      SearchShoppinglistCubitState(
        listItems: listItems ?? this.listItems,
        recentItems: recentItems ?? this.recentItems,
        sorting: sorting ?? this.sorting,
        query: query,
        result: result,
      );

  @override
  List<Object> get props => super.props + result + <Object>[query];
}
