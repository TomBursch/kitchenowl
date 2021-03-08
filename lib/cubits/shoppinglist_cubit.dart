import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class ShoppinglistCubit extends Cubit<ShoppinglistCubitState> {
  ShoppinglistCubit() : super(const ShoppinglistCubitState()) {
    refresh();
  }

  Future<void> search(String query) => refresh(query ?? '');

  Future<void> add(String name) async {
    await ApiService.getInstance().addItemByName(name);
    await refresh('');
  }

  Future<void> remove(ShoppinglistItem item) async {
    await ApiService.getInstance().removeItem(item);
    await refresh();
  }

  Future<void> refresh([String query]) async {
    final state = this.state;
    if (state is SearchShoppinglistCubitState) query = query ?? state.query;
    final shoppinglist = await ApiService.getInstance().getItems();
    if (query != null && query.isNotEmpty) {
      final items = (await ApiService.getInstance().searchItem(query)) ?? [];
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
      final recent = await ApiService.getInstance().getRecentItems();
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
