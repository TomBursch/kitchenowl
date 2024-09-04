import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/planner.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/planner.dart';
import 'package:kitchenowl/services/transactions/recipe.dart';
import 'package:kitchenowl/services/transactions/shoppinglist.dart';

class RecipeCubit extends Cubit<RecipeState> {
  final Household? household;
  final TransactionHandler _transactionHandler;

  RecipeCubit(Household? household, Recipe recipe, int? selectedYields)
      : this.forTesting(TransactionHandler.getInstance(), household, recipe,
            selectedYields);

  RecipeCubit.forTesting(TransactionHandler transactionHandler, this.household,
      Recipe recipe, int? selectedYields)
      : _transactionHandler = transactionHandler,
        super(RecipeState(recipe: recipe, selectedYields: selectedYields)) {
    refresh();
  }

  void itemSelected(RecipeItem item) {
    final Set<String> selectedItems = Set.from(state.selectedItems);
    if (!selectedItems.remove(item.name)) {
      selectedItems.add(item.name);
    }
    emit(state.copyWith(selectedItems: selectedItems));
  }

  void setSelectedYields(int selectedYields) {
    emit(state.copyWith(
      selectedYields: selectedYields,
    ));
  }

  void setUpdateState(UpdateEnum updateState) {
    emit(state.copyWith(updateState: updateState));
  }

  Future<void> refresh() async {
    final recipeFuture = _transactionHandler
        .runTransaction(TransactionRecipeGetRecipe(recipe: state.recipe));
    Future<List<ShoppingList>>? shoppingLists;
    if (household != null) {
      shoppingLists = _transactionHandler.runTransaction(
        TransactionShoppingListGet(household: household!),
        forceOffline: true,
      );
    }
    final (recipe, statusCode) = await recipeFuture;
    if (recipe == null) {
      emit(RecipeErrorState(recipe: state.recipe));
      return;
    }

    emit(RecipeState(
      recipe: recipe,
      updateState: state.updateState,
      selectedYields: recipe.yields,
      shoppingLists: shoppingLists != null ? await shoppingLists : const [],
    ));
  }

  Future<void> addItemsToList([ShoppingList? shoppingList]) async {
    shoppingList ??= household?.defaultShoppingList;
    if (shoppingList != null) {
      await _transactionHandler
          .runTransaction(TransactionShoppingListAddRecipeItems(
        household: household!,
        shoppinglist: shoppingList,
        items: state.dynamicRecipe.items
            .where((item) => state.selectedItems.contains(item.name))
            .toList(),
      ));
    }
  }

  Future<void> addRecipeToPlanner({int? day, bool updateOnAdd = false}) async {
    if (household != null) {
      await _transactionHandler.runTransaction(TransactionPlannerAddRecipe(
        household: household!,
        recipePlan: RecipePlan(
          recipe: state.recipe,
          day: day,
          yields: state.recipe.yields != state.selectedYields &&
                  state.selectedYields > 0
              ? state.selectedYields
              : null,
        ),
      ));
      if (updateOnAdd) setUpdateState(UpdateEnum.updated);
    }
  }
}

final class RecipeState extends Equatable {
  final Set<String> selectedItems;
  final Recipe recipe;
  final Recipe dynamicRecipe;
  final int selectedYields;
  final UpdateEnum updateState;
  final List<ShoppingList> shoppingLists;

  RecipeState.custom({
    required this.recipe,
    required this.selectedItems,
    this.selectedYields = 0,
    this.updateState = UpdateEnum.unchanged,
    this.shoppingLists = const [],
  }) : dynamicRecipe = recipe.withYields(selectedYields);

  RecipeState({
    required this.recipe,
    this.updateState = UpdateEnum.unchanged,
    int? selectedYields,
    this.shoppingLists = const [],
  })  : selectedYields = selectedYields ?? recipe.yields,
        dynamicRecipe = recipe.withYields(selectedYields ?? recipe.yields),
        selectedItems =
            recipe.items.where((e) => !e.optional).map((e) => e.name).toSet();

  RecipeState copyWith({
    Recipe? recipe,
    Set<String>? selectedItems,
    int? selectedYields,
    UpdateEnum? updateState,
    List<ShoppingList>? shoppingLists,
  }) =>
      RecipeState.custom(
        recipe: recipe ?? this.recipe,
        selectedItems: selectedItems ?? this.selectedItems,
        selectedYields: selectedYields ?? this.selectedYields,
        shoppingLists: shoppingLists ?? this.shoppingLists,
        updateState: updateState ?? this.updateState,
      );

  @override
  List<Object?> get props => [
        recipe,
        selectedItems,
        selectedYields,
        dynamicRecipe,
        shoppingLists,
        updateState,
      ];
}

final class RecipeErrorState extends RecipeState {
  RecipeErrorState({required super.recipe});
}
