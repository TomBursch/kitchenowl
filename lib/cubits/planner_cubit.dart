import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class PlannerCubit extends Cubit<PlannerCubitState> {
  PlannerCubit() : super(const PlannerCubitState()) {
    refresh();
  }

  Future<void> remove(Recipe recipe) async {
    await ApiService.getInstance().removePlannedRecipe(recipe);
    await refresh();
  }

  Future<void> add(Recipe recipe) async {
    await ApiService.getInstance().addPlannedRecipe(recipe);
    await refresh();
  }

  Future<void> refresh([String query]) async {
    final planned = await ApiService.getInstance().getPlannedRecipes() ?? [];
    final recent =
        await ApiService.getInstance().getRecentPlannedRecipes() ?? [];
    emit(PlannerCubitState(planned, recent));
  }
}

class PlannerCubitState extends Equatable {
  final List<Recipe> plannedRecipes;
  final List<Recipe> recentRecipes;

  const PlannerCubitState(
      [this.plannedRecipes = const [], this.recentRecipes = const []]);

  @override
  List<Object> get props => plannedRecipes.cast<Object>() + recentRecipes;
}
