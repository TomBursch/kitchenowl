import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/transactions/shoppinglist.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/storage/temp_storage.dart';
import 'package:kitchenowl/services/transaction_handler.dart';

class ShoppinglistCubit extends Cubit<ShoppinglistCubitState> {
  ShoppinglistCubit() : super(const ShoppinglistCubitState()) {
    refresh();
  }

  Future<void> search(String query) => refresh(query ?? '');

  Future<void> add(String name) async {
    await TransactionHandler.getInstance()
        .runTransaction(TransactionShoppingListAddItem(name: name));
    await refresh('');
  }

  Future<void> remove(ShoppinglistItem item) async {
    await TransactionHandler.getInstance()
        .runTransaction(TransactionShoppingListDeleteItem(item: item));
    await refresh();
  }

  Future<void> refresh([String query]) async {
    final state = this.state;
    if (state is SearchShoppinglistCubitState) query = query ?? state.query;
    List<ShoppinglistItem> shoppinglist =
        await ApiService.getInstance().getItems();
    if (shoppinglist == null)
      shoppinglist = await TempStorage.getInstance().readItems();
    else
      TempStorage.getInstance().writeItems(shoppinglist);
    shoppinglist = shoppinglist ?? const [];
    if (query != null && query.isNotEmpty) {
      List<Item> items = (await ApiService.getInstance().searchItem(query));
      if (items == null)
        items = shoppinglist
            .where((e) => e.name.contains(query))
            .cast<Item>()
            .toList();
      _mergeShoppinglistItems(items, shoppinglist);
      if (items.length == 0 ||
          items[0].name.toLowerCase() != query.toLowerCase())
        items.add(Item(name: query));
      emit(SearchShoppinglistCubitState(
        result: items,
        query: query,
        listItems: shoppinglist,
      ));
    } else {
      final recent = await ApiService.getInstance().getRecentItems() ?? [];
      emit(ShoppinglistCubitState(shoppinglist, recent));
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
}

class ShoppinglistCubitState extends Equatable {
  final List<ShoppinglistItem> listItems;
  final List<Item> recentItems;

  const ShoppinglistCubitState(
      [this.listItems = const [], this.recentItems = const []]);

  @override
  List<Object> get props => listItems.cast<Object>();
}

class SearchShoppinglistCubitState extends ShoppinglistCubitState {
  final String query;
  final List<Item> result;

  const SearchShoppinglistCubitState({
    List<ShoppinglistItem> listItems = const [],
    List<ShoppinglistItem> recentItems = const [],
    this.query = "",
    this.result = const [],
  }) : super(listItems, recentItems);

  @override
  List<Object> get props => super.props + result + <Object>[query];
}
