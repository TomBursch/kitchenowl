import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/planner.dart';

class PlannerCubit extends Cubit<PlannerCubitState> {
  PlannerCubit() : super(const PlannerCubitState()) {
    refresh();
  }

  Future<void> remove(Recipe recipe) async {
    await TransactionHandler.getInstance()
        .runTransaction(TransactionPlannerRemoveRecipe(recipe: recipe));
    await refresh();
  }

  Future<void> add(Recipe recipe) async {
    await TransactionHandler.getInstance()
        .runTransaction(TransactionPlannerAddRecipe(recipe: recipe));
    await refresh();
  }

  Future<void> refresh([String query]) async {
    final planned = await TransactionHandler.getInstance()
            .runTransaction(TransactionPlannerGetPlannedRecipes()) ??
        [];
    final recent = await TransactionHandler.getInstance()
            .runTransaction(TransactionPlannerGetRecentPlannedRecipes()) ??
        [];
    final suggested = await TransactionHandler.getInstance()
            .runTransaction(TransactionPlannerGetSuggestedRecipes()) ??
        [];
    emit(PlannerCubitState(planned, recent, suggested));
  }

  Future<void> refreshSuggestions() async {
    final suggested = await TransactionHandler.getInstance()
            .runTransaction(TransactionPlannerRefreshSuggestedRecipes()) ??
        [];
    emit(state.copyWith(suggestedRecipes: suggested));
  }
}

class PlannerCubitState extends Equatable {
  final List<Recipe> plannedRecipes;
  final List<Recipe> recentRecipes;
  final List<Recipe> suggestedRecipes;

  const PlannerCubitState(
      [this.plannedRecipes = const [],
      this.recentRecipes = const [],
      this.suggestedRecipes = const []]);

  @override
  List<Object> get props =>
      plannedRecipes.cast<Object>() + recentRecipes + suggestedRecipes;

  PlannerCubitState copyWith({
    List<Recipe> plannedRecipes,
    List<Recipe> recentRecipes,
    List<Recipe> suggestedRecipes,
  }) =>
      PlannerCubitState(
        plannedRecipes ?? this.plannedRecipes,
        recentRecipes ?? this.recentRecipes,
        suggestedRecipes ?? this.suggestedRecipes,
      );
}
