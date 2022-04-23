import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/planner.dart';
import 'package:kitchenowl/services/transactions/recipe.dart';
import 'package:kitchenowl/services/transactions/shoppinglist.dart';

class RecipeCubit extends Cubit<RecipeState> {
  RecipeCubit(Recipe recipe)
      : super(RecipeState(
          recipe: recipe,
          selectedItems: recipe.items.where((e) => !e.optional).toList(),
        )) {
    refresh();
  }

  void itemSelected(RecipeItem item) {
    final List<RecipeItem> selectedItems = List.from(state.selectedItems);
    if (selectedItems.contains(item)) {
      selectedItems.remove(item);
    } else {
      selectedItems.add(item);
    }
    emit(state.copyWith(selectedItems: selectedItems));
  }

  void setUpdateState(UpdateEnum updateState) {
    emit(state.copyWith(updateState: updateState));
  }

  void refresh() async {
    final recipe = await TransactionHandler.getInstance()
        .runTransaction(TransactionRecipeGetRecipe(recipe: state.recipe));
    emit(state.copyWith(
      recipe: recipe,
      selectedItems: recipe.items.where((e) => !e.optional).toList(),
    ));
  }

  Future<void> addItemsToList() async {
    await TransactionHandler.getInstance()
        .runTransaction(TransactionShoppingListAddRecipeItems(
      items: state.selectedItems,
    ));
  }

  Future<void> addRecipeToPlanner({int? day, bool updateOnAdd = false}) async {
    await TransactionHandler.getInstance()
        .runTransaction(TransactionPlannerAddRecipe(
      recipe: state.recipe,
      day: day,
    ));
    if (updateOnAdd) setUpdateState(UpdateEnum.updated);
  }
}

class RecipeState extends Equatable {
  final List<RecipeItem> selectedItems;
  final Recipe recipe;
  final UpdateEnum updateState;

  const RecipeState({
    required this.recipe,
    required this.selectedItems,
    this.updateState = UpdateEnum.unchanged,
  });

  RecipeState copyWith({
    Recipe? recipe,
    List<RecipeItem>? selectedItems,
    UpdateEnum? updateState,
  }) =>
      RecipeState(
        recipe: recipe ?? this.recipe,
        selectedItems: selectedItems ?? this.selectedItems,
        updateState: updateState ?? this.updateState,
      );

  @override
  List<Object?> get props => [recipe, selectedItems];
}
