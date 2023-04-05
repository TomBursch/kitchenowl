import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/planner.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/storage/temp_storage.dart';
import 'package:kitchenowl/services/transaction.dart';

class TransactionPlannerGetPlannedRecipes
    extends Transaction<List<RecipePlan>> {
  final Household household;

  TransactionPlannerGetPlannedRecipes({
    DateTime? timestamp,
    required this.household,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionPlannerGetPlannedRecipes",
        );

  @override
  Future<List<RecipePlan>> runLocal() async {
    final recipes = List<Recipe>.from(
      await TempStorage.getInstance().readRecipes(household) ?? const [],
    );
    recipes.retainWhere((e) => e.isPlanned);

    return recipes
        .expand((r) => r.plannedDays.isNotEmpty
            ? r.plannedDays.map((day) => RecipePlan(recipe: r, day: day))
            : [RecipePlan(recipe: r)])
        .toList();
  }

  @override
  Future<List<RecipePlan>?> runOnline() async {
    return await ApiService.getInstance().getPlanned(household);
  }
}

class TransactionPlannerGetRecentPlannedRecipes
    extends Transaction<List<Recipe>> {
  final Household household;

  TransactionPlannerGetRecentPlannedRecipes({
    DateTime? timestamp,
    required this.household,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionPlannerGetRecentPlannedRecipes",
        );

  @override
  Future<List<Recipe>> runLocal() async {
    return const [];
  }

  @override
  Future<List<Recipe>?> runOnline() async {
    return await ApiService.getInstance().getRecentPlannedRecipes(household);
  }
}

class TransactionPlannerGetSuggestedRecipes extends Transaction<List<Recipe>> {
  final Household household;

  TransactionPlannerGetSuggestedRecipes({
    DateTime? timestamp,
    required this.household,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionPlannerGetSuggestedRecipes",
        );

  @override
  Future<List<Recipe>> runLocal() async {
    return const [];
  }

  @override
  Future<List<Recipe>?> runOnline() async {
    return await ApiService.getInstance().getSuggestedRecipes(household);
  }
}

class TransactionPlannerAddRecipe extends Transaction<bool> {
  final Household household;
  final Recipe recipe;
  final int? day;

  TransactionPlannerAddRecipe({
    required this.household,
    required this.recipe,
    this.day,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionPlannerAddRecipe",
        );

  factory TransactionPlannerAddRecipe.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) =>
      TransactionPlannerAddRecipe(
        household: Household.fromJson(map['household']),
        recipe: Recipe.fromJson(map['recipe']),
        day: map['day'],
        timestamp: timestamp,
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "household": household.toJsonWithId(),
      "recipe": recipe.toJsonWithId(),
      "day": day,
    });

  @override
  Future<bool> runLocal() async {
    return true;
  }

  @override
  Future<bool?> runOnline() {
    return ApiService.getInstance().addPlannedRecipe(household, recipe, day);
  }
}

class TransactionPlannerRemoveRecipe extends Transaction<bool> {
  final Household household;
  final Recipe recipe;
  final int? day;

  TransactionPlannerRemoveRecipe({
    required this.household,
    required this.recipe,
    this.day,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionPlannerRemoveRecipe",
        );

  factory TransactionPlannerRemoveRecipe.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) =>
      TransactionPlannerRemoveRecipe(
        household: Household.fromJson(map['household']),
        recipe: Recipe.fromJson(map['recipe']),
        timestamp: timestamp,
        day: map['day'],
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "household": household.toJsonWithId(),
      "recipe": recipe.toJsonWithId(),
      "day": day,
    });

  @override
  Future<bool> runLocal() async {
    return true;
  }

  @override
  Future<bool?> runOnline() {
    return ApiService.getInstance().removePlannedRecipe(household, recipe, day);
  }
}

class TransactionPlannerRefreshSuggestedRecipes
    extends Transaction<List<Recipe>> {
  final Household household;

  TransactionPlannerRefreshSuggestedRecipes({
    DateTime? timestamp,
    required this.household,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionPlannerRefreshSuggestedRecipes",
        );

  @override
  Future<List<Recipe>> runLocal() async {
    return const [];
  }

  @override
  Future<List<Recipe>?> runOnline() async {
    return await ApiService.getInstance().refreshSuggestedRecipes(household);
  }
}
