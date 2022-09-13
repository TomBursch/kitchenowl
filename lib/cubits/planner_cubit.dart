import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/planner.dart';
import 'package:kitchenowl/services/transactions/shoppinglist.dart';

class PlannerCubit extends Cubit<PlannerCubitState> {
  bool _refreshLock = false;

  PlannerCubit() : super(const LoadingPlannerCubitState()) {
    refresh();
  }

  Future<void> remove(Recipe recipe, [int? day]) async {
    await TransactionHandler.getInstance()
        .runTransaction(TransactionPlannerRemoveRecipe(
      recipe: recipe,
      day: day,
    ));
    await refresh();
  }

  Future<void> add(Recipe recipe, [int? day]) async {
    await TransactionHandler.getInstance()
        .runTransaction(TransactionPlannerAddRecipe(recipe: recipe, day: day));
    await refresh();
  }

  Future<void> refresh() async {
    if (_refreshLock) return;
    _refreshLock = true;
    final planned = TransactionHandler.getInstance()
        .runTransaction(TransactionPlannerGetPlannedRecipes());
    final recent = TransactionHandler.getInstance()
        .runTransaction(TransactionPlannerGetRecentPlannedRecipes());
    final suggested = TransactionHandler.getInstance()
        .runTransaction(TransactionPlannerGetSuggestedRecipes());

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
          .runTransaction(TransactionPlannerRefreshSuggestedRecipes());
      emit((state as LoadedPlannerCubitState)
          .copyWith(suggestedRecipes: suggested));
    }
  }

  Future<void> addItemsToList(List<RecipeItem> items) async {
    await TransactionHandler.getInstance()
        .runTransaction(TransactionShoppingListAddRecipeItems(
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
  final List<Recipe> plannedRecipes;
  final List<Recipe> recentRecipes;
  final List<Recipe> suggestedRecipes;

  const LoadedPlannerCubitState([
    this.plannedRecipes = const [],
    this.recentRecipes = const [],
    this.suggestedRecipes = const [],
  ]);

  @override
  List<Object?> get props =>
      plannedRecipes.cast<Object?>() + recentRecipes + suggestedRecipes;

  LoadedPlannerCubitState copyWith({
    List<Recipe>? plannedRecipes,
    Map<int, List<Recipe>>? plannedRecipeDayMap,
    List<Recipe>? recentRecipes,
    List<Recipe>? suggestedRecipes,
  }) =>
      LoadedPlannerCubitState(
        plannedRecipes ?? this.plannedRecipes,
        recentRecipes ?? this.recentRecipes,
        suggestedRecipes ?? this.suggestedRecipes,
      );

  List<Recipe> getPlannedWithoutDay() {
    return plannedRecipes
        .where((element) => element.plannedDays.isEmpty)
        .toList();
  }

  List<Recipe> getPlannedOfDay(int day) {
    return plannedRecipes
        .where((element) => element.plannedDays.contains(day))
        .toList();
  }
}
