import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/helpers/item_name.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:collection/collection.dart';

class ItemSearchCubit extends Cubit<ItemSearchState> {
  final Household household;

  ItemSearchCubit(this.household, List<Item> selectedItems)
      : super(ItemSearchState(selectedItems, '', const []));

  void itemSelected(Item item) {
    final List<Item> selectedItems = List.from(state.selectedItems);
    if(!selectedItems.remove(item)) {
      selectedItems.add(item);
    }
    emit(ItemSearchState(selectedItems, '', state.searchResults));
  }

  Future<void> search(String query) async {
    if (query.isNotEmpty) {
      final (queryName, queryDescription) = parseQuery(query);

      List<Item> items = [];
      for (Item item
          in (await ApiService.getInstance().searchItem(household, queryName) ??
              [])) {
        String? description = state.selectedItems
                .whereType<ItemWithDescription>()
                .firstWhereOrNull((e) => e.name == item.name)
                ?.description ??
            queryDescription;
        items.add(ItemWithDescription.fromItem(
          item: item,
          description: description,
        ));
      }
      items = withExactMatchFirst(items, queryName, queryDescription);
      emit(ItemSearchState(state.selectedItems, query, items));
    } else {
      emit(ItemSearchState(state.selectedItems, query, state.searchResults));
    }
  }

  /// Returns [items] with the item named [queryName] in the first position,
  /// so that confirming the search adds what was typed rather than a
  /// similar item. An already known item is moved to the front, otherwise
  /// a new item is created for [queryName].
  @visibleForTesting
  static List<Item> withExactMatchFirst(
    List<Item> items,
    String queryName,
    String? queryDescription,
  ) {
    final result = List<Item>.from(items);
    final exactIndex = result.indexWhere(
      (e) => normalizeItemName(e.name) == normalizeItemName(queryName),
    );
    if (exactIndex > 0) {
      result.insert(0, result.removeAt(exactIndex));
    } else if (exactIndex < 0) {
      result.insert(
        0,
        ItemWithDescription(
          name: queryName,
          description: queryDescription ?? '',
        ),
      );
    }

    return result;
  }

  /// Scans the [query] for a comma and if found,
  /// returns a tuple consisting of the part before
  /// the comma and the remaining string.
  /// Otherwise returns the [query].
  (String, String?) parseQuery(String query) {
    final splitIndex = query.indexOf(",");
    if (splitIndex >= 0) {
      return (
        query.substring(0, splitIndex).trim(),
        query.substring(splitIndex + 1).trim()
      );
    }
    return (query, null);
  }
}

class ItemSearchState extends Equatable {
  final List<Item> selectedItems;
  final String query;
  final List<Item> searchResults;

  const ItemSearchState(this.selectedItems, this.query, this.searchResults);

  @override
  List<Object?> get props => [selectedItems, query, searchResults];
}
