import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/item.dart';

class ItemSelectionCubit<T extends Item> extends Cubit<ItemSelectionState<T>> {
  ItemSelectionCubit(List<T> items) : super(ItemSelectionState<T>(items));

  void toggleItem(T item) {
    final l = List<T>.from(state.selectedItems);
    if (l.contains(item)) {
      l.remove(item);
    } else {
      l.add(item);
    }
    emit(state.copyWith(selectedItems: l));
  }

  List<T> getResult() {
    return state.selectedItems;
  }
}

class ItemSelectionState<T extends Item> extends Equatable {
  final List<T> allItems;
  final List<T> selectedItems;
  final List<RecipeItem> optionalItems;
  final List<T> items;

  ItemSelectionState(List<T> allItems)
      : this.withSelection(
          allItems,
          allItems
              .where(
                (e) => !(e is RecipeItem && e.optional),
              )
              .toList(),
        );

  ItemSelectionState.withSelection(this.allItems, this.selectedItems)
      : optionalItems = allItems
            .where((e) => e is RecipeItem && e.optional)
            .cast<RecipeItem>()
            .toList(),
        items =
            allItems.where((e) => !(e is RecipeItem && e.optional)).toList();

  const ItemSelectionState._all({
    required this.allItems,
    required this.items,
    required this.selectedItems,
    required this.optionalItems,
  });

  ItemSelectionState<T> copyWith({
    List<T>? allItems,
    List<T>? selectedItems,
    List<RecipeItem>? optionalItems,
    List<T>? items,
  }) =>
      ItemSelectionState._all(
        allItems: allItems ?? this.allItems,
        items: items ?? this.items,
        selectedItems: selectedItems ?? this.selectedItems,
        optionalItems: optionalItems ?? this.optionalItems,
      );

  @override
  List<Object?> get props => [allItems, items, selectedItems, optionalItems];
}
