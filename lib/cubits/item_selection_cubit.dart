import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/planner.dart';

class ItemSelectionCubit extends Cubit<ItemSelectionState> {
  ItemSelectionCubit(List<RecipePlan> plans)
      : super(
          ItemSelectionState(
            Map.fromEntries(plans.map((e) => MapEntry(e, e.recipe.items))),
          ),
        );

  void toggleItem(RecipePlan recipe, RecipeItem item) {
    final s = Map.of(state.selectedItems);
    if (!s.containsKey(recipe)) return;
    final l = Set.of(s[recipe]!);
    if (l.contains(item)) {
      l.remove(item);
    } else {
      l.add(item);
    }
    s[recipe] = l;
    emit(state.copyWith(selectedItems: s));
  }

  List<RecipeItem> getResult() {
    return state.getResult();
  }
}

class ItemSelectionState extends Equatable {
  final Map<RecipePlan, Set<RecipeItem>> selectedItems;

  ItemSelectionState(Map<RecipePlan, List<RecipeItem>> items)
      : this.withSelection(
          items.map((key, value) =>
              MapEntry(key, value.where((e) => !e.optional).toSet())),
        );

  const ItemSelectionState.withSelection(this.selectedItems);

  const ItemSelectionState._all({
    required this.selectedItems,
  });

  ItemSelectionState copyWith({
    Map<RecipePlan, Set<RecipeItem>>? selectedItems,
  }) =>
      ItemSelectionState._all(
        selectedItems: selectedItems ?? this.selectedItems,
      );

  @override
  List<Object?> get props => selectedItems.values.toList();

  List<RecipeItem> getResult() {
    return selectedItems.values.expand((e) => e).toList();
  }
}
