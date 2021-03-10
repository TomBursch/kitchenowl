import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class ItemSearchCubit extends Cubit<ItemSearchState> {
  ItemSearchCubit(List<Item> selectedItems)
      : super(ItemSearchState(selectedItems, '', []));

  void itemSelected(int i) {
    final List<Item> selectedItems = List.from(state.selectedItems);
    final bool addItem = state.selectedItems
        .map((e) => e.name)
        .contains(state.searchResults[i].name);
    if (addItem) {
      selectedItems.removeWhere((e) => e.name == state.searchResults[i].name);
    } else {
      selectedItems.add(state.searchResults[i]);
    }
    emit(ItemSearchState(
        selectedItems, addItem ? '' : state.query, state.searchResults));
  }

  Future<void> search(String query) async {
    if (query.isNotEmpty) {
      final items = (await ApiService.getInstance().searchItem(query)) ?? [];
      if (items.length == 0 ||
          items[0].name.toLowerCase() != query.toLowerCase())
        items.add(Item(name: query));
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
