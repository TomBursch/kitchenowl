import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/services/transactions/shoppinglist.dart';
import 'package:kitchenowl/services/transaction_handler.dart';

enum ShoppinglistSorting { alphabetical, algorithmic, category }
enum ShoppinglistStyle { grid, list }

class ShoppinglistCubit extends Cubit<ShoppinglistCubitState> {
  String get query => (state is SearchShoppinglistCubitState)
      ? (state as SearchShoppinglistCubitState).query
      : "";

  ShoppinglistCubit() : super(const ShoppinglistCubitState()) {
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
    setSorting(ShoppinglistSorting.values[(state.sorting.index + 1) % 2]);
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

  Future<void> refresh([String? query]) async {
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
        TransactionShoppingListSearchItem(query: queryName),
      ))
          .map((e) => ItemWithDescription.fromItem(
                item: e,
                description: queryDescription,
              ))
          .toList();
      _mergeShoppinglistItems(items, shoppinglist);
      if (items.isEmpty ||
          items[0].name.toLowerCase() != queryName.toLowerCase()) {
        items.add(ItemWithDescription(
          name: queryName,
          description: queryDescription,
        ));
      }
      emit(SearchShoppinglistCubitState(
        result: items,
        query: query,
        listItems: shoppinglist,
        style: state.style,
        sorting: state.sorting,
      ));
    } else {
      // Sort if needed
      if (sorting != ShoppinglistSorting.alphabetical) {
        _sortShoppinglistItems(shoppinglist, sorting);
      }

      final recent = await TransactionHandler.getInstance()
          .runTransaction(TransactionShoppingListGetRecentItems());
      emit(ShoppinglistCubitState(shoppinglist, recent, sorting, state.style));
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
        // TODO: Handle this case.
        break;
    }
  }
}

class ShoppinglistCubitState extends Equatable {
  final List<ShoppinglistItem> listItems;
  final List<Item> recentItems;
  final ShoppinglistSorting sorting;
  final ShoppinglistStyle style;

  const ShoppinglistCubitState([
    this.listItems = const [],
    this.recentItems = const [],
    this.sorting = ShoppinglistSorting.alphabetical,
    this.style = ShoppinglistStyle.grid,
  ]);

  ShoppinglistCubitState copyWith({
    List<ShoppinglistItem>? listItems,
    List<Item>? recentItems,
    ShoppinglistSorting? sorting,
    ShoppinglistStyle? style,
  }) =>
      ShoppinglistCubitState(
        listItems ?? this.listItems,
        recentItems ?? this.recentItems,
        sorting ?? this.sorting,
        style ?? this.style,
      );

  @override
  List<Object?> get props =>
      listItems.cast<Object>() + recentItems + [sorting, style];
}

class SearchShoppinglistCubitState extends ShoppinglistCubitState {
  final String query;
  final List<Item> result;

  const SearchShoppinglistCubitState({
    List<ShoppinglistItem> listItems = const [],
    List<Item> recentItems = const [],
    ShoppinglistSorting sorting = ShoppinglistSorting.alphabetical,
    ShoppinglistStyle style = ShoppinglistStyle.grid,
    this.query = "",
    this.result = const [],
  }) : super(listItems, recentItems, sorting, style);

  @override
  ShoppinglistCubitState copyWith({
    List<ShoppinglistItem>? listItems,
    List<Item>? recentItems,
    ShoppinglistSorting? sorting,
    ShoppinglistStyle? style,
  }) =>
      SearchShoppinglistCubitState(
        listItems: listItems ?? this.listItems,
        recentItems: recentItems ?? this.recentItems,
        sorting: sorting ?? this.sorting,
        style: style ?? this.style,
        query: query,
        result: result,
      );

  @override
  List<Object?> get props => super.props + result + <Object>[query];
}
