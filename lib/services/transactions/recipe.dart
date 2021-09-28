import 'package:flutter/foundation.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/storage/temp_storage.dart';
import 'package:kitchenowl/services/transaction.dart';

class TransactionRecipeGetRecipes extends Transaction<List<Recipe>> {
  TransactionRecipeGetRecipes({DateTime timestamp})
      : super.internal(
            timestamp ?? DateTime.now(), "TransactionRecipeGetRecipes");

  @override
  Future<List<Recipe>> runLocal() async {
    return await TempStorage.getInstance().readRecipes();
  }

  @override
  Future<List<Recipe>> runOnline() async {
    final recipes = await ApiService.getInstance().getRecipes();
    if (recipes != null) TempStorage.getInstance().writeRecipes(recipes);
    return recipes;
  }
}

class TransactionRecipeGetRecipe extends Transaction<Recipe> {
  final Recipe recipe;

  TransactionRecipeGetRecipe({@required this.recipe, DateTime timestamp})
      : assert(recipe != null),
        super.internal(
            timestamp ?? DateTime.now(), "TransactionRecipeGetRecipe");

  @override
  Future<Recipe> runLocal() async {
    return recipe;
  }

  @override
  Future<Recipe> runOnline() {
    return ApiService.getInstance().getRecipe(recipe);
  }
}

class TransactionRecipeSearchRecipes extends Transaction<List<Recipe>> {
  final String query;
  TransactionRecipeSearchRecipes({this.query, DateTime timestamp})
      : super.internal(
            timestamp ?? DateTime.now(), "TransactionRecipeSearchRecipes");

  @override
  Future<List<Recipe>> runLocal() async {
    final recipes = await TempStorage.getInstance().readRecipes() ?? const [];
    recipes.retainWhere((e) => e.name.contains(query));
    return recipes;
  }

  @override
  Future<List<Recipe>> runOnline() async {
    return await ApiService.getInstance().searchRecipe(query);
  }
}
