import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/planner.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/household.dart';
import 'package:kitchenowl/services/transactions/planner.dart';
import 'package:kitchenowl/services/transactions/recipe.dart';
import 'package:kitchenowl/services/transactions/shoppinglist.dart';

class RecipeCubit extends Cubit<RecipeState> {
  final TransactionHandler _transactionHandler;

  RecipeCubit(Household? household, Recipe recipe, int? selectedYields)
      : this.forTesting(TransactionHandler.getInstance(), household, recipe,
            selectedYields);

  RecipeCubit.forTesting(TransactionHandler transactionHandler,
      Household? household, Recipe recipe, int? selectedYields)
      : _transactionHandler = transactionHandler,
        super(RecipeState(
            recipe: recipe,
            selectedYields: selectedYields,
            household: household)) {
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
    Future<Household?>? household;
    if (state.household != null) {
      shoppingLists = _transactionHandler.runTransaction(
        TransactionShoppingListGet(household: state.household!),
        forceOffline: true,
      );
      household = _transactionHandler.runTransaction(
        TransactionHouseholdGet(household: state.household!),
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
      household: (await household) ?? state.household,
    ));
  }

  Future<void> addItemsToList([ShoppingList? shoppingList]) async {
    shoppingList ??= state.household?.defaultShoppingList;
    if (shoppingList != null) {
      await _transactionHandler
          .runTransaction(TransactionShoppingListAddRecipeItems(
        household: state.household!,
        shoppinglist: shoppingList,
        items: state.dynamicRecipe.items
            .where((item) => state.selectedItems.contains(item.name))
            .toList(),
      ));
    }
  }

  Future<void> addRecipeToPlanner({int? day, bool updateOnAdd = false}) async {
    if (state.household != null) {
      await _transactionHandler.runTransaction(TransactionPlannerAddRecipe(
        household: state.household!,
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

  Future<Recipe?> addRecipeToHousehold() async {
    if (state.household != null) {
      final res = await ApiService.getInstance().addRecipe(
        state.household!,
        state.recipe.copyWith(
          source: "kitchenowl:///recipe/${state.recipe.id}",
          public: false,
        ),
      );
      if (res != null) setUpdateState(UpdateEnum.updated);
      return res;
    }
    return null;
  }
}

final class RecipeState extends Equatable {
  final Set<String> selectedItems;
  final Recipe recipe;
  final Recipe dynamicRecipe;
  final int selectedYields;
  final UpdateEnum updateState;
  final List<ShoppingList> shoppingLists;
  final Household? household;

  RecipeState.custom({
    required this.recipe,
    required this.selectedItems,
    this.selectedYields = 0,
    this.updateState = UpdateEnum.unchanged,
    this.shoppingLists = const [],
    this.household,
  }) : dynamicRecipe = recipe.withYields(selectedYields);

  RecipeState({
    required this.recipe,
    this.updateState = UpdateEnum.unchanged,
    int? selectedYields,
    this.shoppingLists = const [],
    this.household,
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
    Household? household,
  }) =>
      RecipeState.custom(
        recipe: recipe ?? this.recipe,
        selectedItems: selectedItems ?? this.selectedItems,
        selectedYields: selectedYields ?? this.selectedYields,
        shoppingLists: shoppingLists ?? this.shoppingLists,
        updateState: updateState ?? this.updateState,
        household: household ?? this.household,
      );

  @override
  List<Object?> get props => [
        recipe,
        selectedItems,
        selectedYields,
        dynamicRecipe,
        shoppingLists,
        updateState,
        household,
      ];

  bool isOwningHousehold(RecipeState state) =>
      household != null && recipe.householdId == household!.id;
}

final class RecipeErrorState extends RecipeState {
  RecipeErrorState({required super.recipe});
}
