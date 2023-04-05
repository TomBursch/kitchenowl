import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/storage/temp_storage.dart';
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
    return await TempStorage.getInstance().readRecipes(household) ?? [];
  }

  @override
  Future<List<Recipe>?> runOnline() async {
    final recipes = await ApiService.getInstance().getRecipes(household);
    if (recipes != null) {
      TempStorage.getInstance().writeRecipes(household, recipes);
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
    return (await TempStorage.getInstance().readRecipes(household))
            ?.where((recipe) => recipe.tags.any((tag) => filter.contains(tag)))
            .toList() ??
        [];
  }

  @override
  Future<List<Recipe>?> runOnline() async {
    return await ApiService.getInstance().getRecipesFiltered(household, filter);
  }
}

class TransactionRecipeGetRecipe extends Transaction<Recipe> {
  final Recipe recipe;

  TransactionRecipeGetRecipe({required this.recipe, DateTime? timestamp})
      : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionRecipeGetRecipe",
        );

  @override
  Future<Recipe> runLocal() async {
    return recipe;
  }

  @override
  Future<Recipe?> runOnline() async {
    return await ApiService.getInstance().getRecipe(recipe);
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
    final recipes =
        await TempStorage.getInstance().readRecipes(household) ?? [];
    recipes
        .retainWhere((e) => e.name.toLowerCase().contains(query.toLowerCase()));

    return recipes;
  }

  @override
  Future<List<Recipe>?> runOnline() async {
    final ids = await ApiService.getInstance().searchRecipe(household, query);
    if (ids == null) return [];
    final recipes = (await TempStorage.getInstance().readRecipes(household) ??
        [])
      ..retainWhere((e) => ids.contains(e.id));

    return recipes;
  }
}
