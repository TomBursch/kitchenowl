import 'dart:convert';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/recipe_scrape.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension RecipeApi on ApiService {
  static const baseRoute = '/recipe';

  Future<List<Recipe>?> getRecipes(Household household) async {
    final res = await get(householdPath(household) + baseRoute);
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => Recipe.fromJson(e)).toList();
  }

  Future<List<Recipe>?> getRecipesFiltered(
    Household household,
    Set<Tag> filter,
  ) async {
    final res = await post(
      '${householdPath(household)}$baseRoute/filter',
      jsonEncode({"filter": filter.map((e) => e.toString()).toList()}),
    );
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => Recipe.fromJson(e)).toList();
  }

  Future<List<int>?> searchRecipe(Household household, String query) async {
    final res = await get(
      '${householdPath(household)}$baseRoute/search?only_ids=true&query=$query',
    );
    if (res.statusCode != 200) return null;

    return List.from(jsonDecode(res.body));
  }

  Future<Recipe?> getRecipe(Recipe recipe) async {
    final res = await get('$baseRoute/${recipe.id}');
    if (res.statusCode != 200) return null;

    final body = jsonDecode(res.body);

    return Recipe.fromJson(body);
  }

  Future<Recipe?> addRecipe(Household household, Recipe recipe) async {
    final res = await post(
      householdPath(household) + baseRoute,
      jsonEncode(recipe.toJson()),
    );
    if (res.statusCode != 200) return null;

    return Recipe.fromJson(jsonDecode(res.body));
  }

  Future<bool> updateRecipe(Recipe recipe) async {
    final res =
        await post('$baseRoute/${recipe.id}', jsonEncode(recipe.toJson()));

    return res.statusCode == 200;
  }

  Future<bool> deleteRecipe(Recipe recipe) async {
    final res = await delete('$baseRoute/${recipe.id}');

    return res.statusCode == 200;
  }

  Future<(RecipeScrape?, int)> scrapeRecipe(
      Household household, String url) async {
    final res = await post(
      '${householdPath(household)}$baseRoute/scrape',
      jsonEncode({'url': url}),
    );
    if (res.statusCode != 200) return (null, res.statusCode);

    final body = jsonDecode(res.body);

    return (RecipeScrape.fromJson(body), 200);
  }
}
