import 'dart:convert';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension PlannerApi on ApiService {
  static const baseRoute = '/planner';

  Future<List<Recipe>?> getPlannedRecipes() async {
    final res = await get(baseRoute + '/recipes');
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => Recipe.fromJson(e)).toList();
  }

  Future<bool> addPlannedRecipe(Recipe recipe) async {
    final body = {"recipe_id": recipe.id};
    final res = await post(baseRoute + '/recipe', jsonEncode(body));

    return res.statusCode == 200;
  }

  Future<bool> removePlannedRecipe(Recipe recipe) async {
    final res = await delete(baseRoute + '/recipe/${recipe.id}');

    return res.statusCode == 200;
  }

  Future<List<Recipe>?> getRecentPlannedRecipes() async {
    final res = await get(baseRoute + '/recent-recipes');
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => Recipe.fromJson(e)).toList();
  }

  Future<List<Recipe>?> getSuggestedRecipes() async {
    final res = await get(baseRoute + '/suggested-recipes');
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => Recipe.fromJson(e)).toList();
  }

  Future<List<Recipe>?> refreshSuggestedRecipes() async {
    final res = await get(baseRoute + '/refresh-suggested-recipes');
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => Recipe.fromJson(e)).toList();
  }
}
