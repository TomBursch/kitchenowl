import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/planner.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/planner.dart';
import 'package:kitchenowl/services/transactions/shoppinglist.dart';

class PlannerCubit extends Cubit<PlannerCubitState> {
  final Household household;
  bool _refreshLock = false;

  PlannerCubit(this.household) : super(const LoadingPlannerCubitState()) {
    refresh();
  }

  Future<void> remove(Recipe recipe, [DateTime? cookingDate]) async {
    await TransactionHandler.getInstance()
        .runTransaction(TransactionPlannerRemoveRecipe(
      household: household,
      recipe: recipe,
      cookingDate: cookingDate,
    ));
    await refresh();
  }

  Future<void> add(Recipe recipe, [DateTime? cookingDate]) async {
    await TransactionHandler.getInstance()
        .runTransaction(TransactionPlannerAddRecipe(
      household: household,
      recipePlan: RecipePlan(recipe: recipe, cookingDate: cookingDate),
    ));
    await refresh();
  }

  Future<void> refresh() async {
    if (_refreshLock) return;
    _refreshLock = true;
    final planned = TransactionHandler.getInstance()
        .runTransaction(TransactionPlannerGetPlannedRecipes(
      household: household,
    ));
    final recent = TransactionHandler.getInstance()
        .runTransaction(TransactionPlannerGetRecentPlannedRecipes(
      household: household,
    ));
    final suggested = TransactionHandler.getInstance()
        .runTransaction(TransactionPlannerGetSuggestedRecipes(
      household: household,
    ));

    emit(LoadedPlannerCubitState(
      await planned,
      await recent,
      await suggested,
    ));
    _refreshLock = false;
  }

  Future<void> refreshSuggestions() async {
    if (state is LoadedPlannerCubitState) {
      final suggested = await TransactionHandler.getInstance()
          .runTransaction(TransactionPlannerRefreshSuggestedRecipes(
        household: household,
      ));
      emit((state as LoadedPlannerCubitState)
          .copyWith(suggestedRecipes: suggested));
    }
  }

  Future<void> addItemsToList(
    ShoppingList shoppingList,
    List<RecipeItem> items,
  ) {
    return TransactionHandler.getInstance()
        .runTransaction(TransactionShoppingListAddRecipeItems(
      household: household,
      shoppinglist: shoppingList,
      items: items,
    ));
  }
}

abstract class PlannerCubitState extends Equatable {
  const PlannerCubitState();
}

class LoadingPlannerCubitState extends PlannerCubitState {
  const LoadingPlannerCubitState();

  @override
  List<Object?> get props => [];
}

class LoadedPlannerCubitState extends PlannerCubitState {
  final List<RecipePlan> recipePlans;
  final List<Recipe> recentRecipes;
  final List<Recipe> suggestedRecipes;

  const LoadedPlannerCubitState([
    this.recipePlans = const [],
    this.recentRecipes = const [],
    this.suggestedRecipes = const [],
  ]);

  @override
  List<Object?> get props =>
      recipePlans.cast<Object?>() + recentRecipes + suggestedRecipes;

  LoadedPlannerCubitState copyWith({
    List<RecipePlan>? recipePlans,
    Map<int, List<Recipe>>? plannedRecipeDayMap,
    List<Recipe>? recentRecipes,
    List<Recipe>? suggestedRecipes,
  }) =>
      LoadedPlannerCubitState(
        recipePlans ?? this.recipePlans,
        recentRecipes ?? this.recentRecipes,
        suggestedRecipes ?? this.suggestedRecipes,
      );

  List<RecipePlan> getPlannedWithoutDay() {
    return recipePlans
        .where((element) =>
            element.cookingDate == null ||
            (element.cookingDate != null &&
                element.cookingDate!.millisecondsSinceEpoch < 0))
        .toList();
  }

  List<RecipePlan> getPlannedOfDate(DateTime cookingDate) {
    return recipePlans
        .where((element) =>
            element.cookingDate?.year == cookingDate.year &&
            element.cookingDate?.month == cookingDate.month &&
            element.cookingDate?.day == cookingDate.day)
        .toList();
  }

  List<DateTime> getUniqueCookingDays() {
    Set<DateTime> uniqueDays = {};

    for (var recipe in recipePlans) {
      if (recipe.cookingDate != null &&
          recipe.cookingDate!.millisecondsSinceEpoch > 0) {
        uniqueDays.add(recipe.cookingDate!);
      }
    }
    return uniqueDays.toList()..sort();
  }
}
