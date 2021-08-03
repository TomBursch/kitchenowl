import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class ItemSearchCubit extends Cubit<ItemSearchState> {
  ItemSearchCubit(List<Item> selectedItems)
      : super(ItemSearchState(selectedItems, '', []));

  void itemSelected(int i) {
    final List<Item> selectedItems = List.from(state.selectedItems);
    final bool containsItem = state.selectedItems
        .map((e) => e.name)
        .contains(state.searchResults[i].name);
    if (containsItem) {
      selectedItems.removeWhere((e) => e.name == state.searchResults[i].name);
    } else {
      selectedItems.add(state.searchResults[i]);
    }
    emit(ItemSearchState(selectedItems, '', state.searchResults));
  }

  Future<void> search(String query) async {
    if (query.isNotEmpty) {
      final splitIndex = query.indexOf(',');
      String queryName = query;
      String queryDescription = '';
      if (splitIndex >= 0) {
        queryName = query.substring(0, splitIndex).trim();
        queryDescription = query.substring(splitIndex + 1).trim();
      }

      List<Item> items = [];
      for (Item item
          in (await ApiService.getInstance().searchItem(queryName) ?? [])) {
        String description = state.selectedItems
                .whereType<ItemWithDescription>()
                .firstWhere((e) => e.name == item.name, orElse: () => null)
                ?.description ??
            queryDescription;
        items.add(
            ItemWithDescription.fromItem(item: item, description: description));
      }
      if (items.length == 0 ||
          items[0].name.toLowerCase() != queryName.toLowerCase())
        items.add(ItemWithDescription(
            name: queryName, description: queryDescription));
      emit(ItemSearchState(state.selectedItems, query, items));
    } else {
      emit(ItemSearchState(state.selectedItems, query, state.searchResults));
    }
  }
}

class ItemSearchState extends Equatable {
  final List<Item> selectedItems;
  final String query;
  final List<Item> searchResults;

  ItemSearchState(this.selectedItems, this.query, this.searchResults);

  @override
  List<Object> get props => [selectedItems, query, searchResults];
}