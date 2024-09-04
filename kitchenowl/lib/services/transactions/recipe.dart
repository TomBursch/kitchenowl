import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/storage/mem_storage.dart';
import 'package:kitchenowl/services/transaction.dart';

class TransactionRecipeGetRecipes extends Transaction<List<Recipe>> {
  final Household household;

  TransactionRecipeGetRecipes({DateTime? timestamp, required this.household})
      : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionRecipeGetRecipes",
        );

  @override
  Future<List<Recipe>> runLocal() async {
    return await MemStorage.getInstance().readRecipes(household) ?? [];
  }

  @override
  Future<List<Recipe>?> runOnline() async {
    final recipes = await ApiService.getInstance().getRecipes(household);
    if (recipes != null) {
      MemStorage.getInstance().writeRecipes(household, recipes);
    }

    return recipes;
  }
}

class TransactionRecipeGetRecipesFiltered extends Transaction<List<Recipe>> {
  final Household household;
  final Set<Tag> filter;

  TransactionRecipeGetRecipesFiltered({
    DateTime? timestamp,
    required this.household,
    required this.filter,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionRecipeGetRecipesFiltered",
        );

  @override
  Future<List<Recipe>> runLocal() async {
    return (await MemStorage.getInstance().readRecipes(household))
            ?.where((recipe) => recipe.tags.any((tag) => filter.contains(tag)))
            .toList() ??
        [];
  }

  @override
  Future<List<Recipe>?> runOnline() async {
    return await ApiService.getInstance().getRecipesFiltered(household, filter);
  }
}

class TransactionRecipeGetRecipe extends Transaction<(Recipe?, int)> {
  final Recipe recipe;

  TransactionRecipeGetRecipe({required this.recipe, DateTime? timestamp})
      : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionRecipeGetRecipe",
        );

  @override
  Future<(Recipe?, int)> runLocal() async {
    return (recipe, 0);
  }

  @override
  Future<(Recipe?, int)> runOnline() async {
    return ApiService.getInstance().getRecipe(recipe);
  }
}

class TransactionRecipeSearchRecipes extends Transaction<List<Recipe>> {
  final Household household;
  final String query;

  TransactionRecipeSearchRecipes({
    required this.household,
    required this.query,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionRecipeSearchRecipes",
        );

  @override
  Future<List<Recipe>> runLocal() async {
    final recipes = await MemStorage.getInstance().readRecipes(household) ?? [];
    recipes
        .retainWhere((e) => e.name.toLowerCase().contains(query.toLowerCase()));

    return recipes;
  }

  @override
  Future<List<Recipe>?> runOnline() async {
    final ids =
        await ApiService.getInstance().searchRecipeById(household, query);
    if (ids == null) return [];
    final recipes = (await MemStorage.getInstance().readRecipes(household) ??
        [])
      ..retainWhere((e) => ids.contains(e.id));

    return recipes;
  }
}
