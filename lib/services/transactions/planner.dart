import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/storage/temp_storage.dart';
import 'package:kitchenowl/services/transaction.dart';

class TransactionPlannerGetPlannedRecipes extends Transaction<List<Recipe>> {
  TransactionPlannerGetPlannedRecipes({DateTime? timestamp})
      : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionPlannerGetPlannedRecipes",
        );

  @override
  Future<List<Recipe>> runLocal() async {
    final recipes = List<Recipe>.from(
      await TempStorage.getInstance().readRecipes() ?? const [],
    );
    recipes.retainWhere((e) => e.isPlanned);

    return recipes;
  }

  @override
  Future<List<Recipe>?> runOnline() async {
    return await ApiService.getInstance().getPlannedRecipes();
  }
}

class TransactionPlannerGetRecentPlannedRecipes
    extends Transaction<List<Recipe>> {
  TransactionPlannerGetRecentPlannedRecipes({DateTime? timestamp})
      : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionPlannerGetRecentPlannedRecipes",
        );

  @override
  Future<List<Recipe>> runLocal() async {
    return const [];
  }

  @override
  Future<List<Recipe>?> runOnline() async {
    return await ApiService.getInstance().getRecentPlannedRecipes();
  }
}

class TransactionPlannerGetSuggestedRecipes extends Transaction<List<Recipe>> {
  TransactionPlannerGetSuggestedRecipes({DateTime? timestamp})
      : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionPlannerGetSuggestedRecipes",
        );

  @override
  Future<List<Recipe>> runLocal() async {
    return const [];
  }

  @override
  Future<List<Recipe>?> runOnline() async {
    return await ApiService.getInstance().getSuggestedRecipes();
  }
}

class TransactionPlannerAddRecipe extends Transaction<bool> {
  final Recipe recipe;
  final int? day;

  TransactionPlannerAddRecipe({
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
        recipe: Recipe.fromJson(map['recipe']),
        day: map['day'],
        timestamp: timestamp,
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "recipe": recipe.toJsonWithId(),
      "day": day,
    });

  @override
  Future<bool> runLocal() async {
    return true;
  }

  @override
  Future<bool?> runOnline() {
    return ApiService.getInstance().addPlannedRecipe(recipe, day);
  }
}

class TransactionPlannerRemoveRecipe extends Transaction<bool> {
  final Recipe recipe;
  final int? day;

  TransactionPlannerRemoveRecipe({
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
        recipe: Recipe.fromJson(map['recipe']),
        timestamp: timestamp,
        day: map['day'],
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "recipe": recipe.toJsonWithId(),
      "day": day,
    });

  @override
  Future<bool> runLocal() async {
    return true;
  }

  @override
  Future<bool?> runOnline() {
    return ApiService.getInstance().removePlannedRecipe(recipe, day);
  }
}

class TransactionPlannerRefreshSuggestedRecipes
    extends Transaction<List<Recipe>> {
  TransactionPlannerRefreshSuggestedRecipes({DateTime? timestamp})
      : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionPlannerRefreshSuggestedRecipes",
        );

  @override
  Future<List<Recipe>> runLocal() async {
    return const [];
  }

  @override
  Future<List<Recipe>?> runOnline() async {
    return await ApiService.getInstance().refreshSuggestedRecipes();
  }
}
