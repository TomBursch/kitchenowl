import 'dart:convert';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension PlannerApi on ApiService {
  static const baseRoute = '/planner';

  Future<List<Recipe>?> getPlannedRecipes(Household household) async {
    final res = await get('${householdPath(household)}$baseRoute/recipes');
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => Recipe.fromJson(e)).toList();
  }

  Future<bool> addPlannedRecipe(
    Household household,
    Recipe recipe,
    int? day,
  ) async {
    final body = {"recipe_id": recipe.id};
    if (day != null) body['day'] = day;
    final res = await post(
      '${householdPath(household)}$baseRoute/recipe',
      jsonEncode(body),
    );

    return res.statusCode == 200;
  }

  Future<bool> removePlannedRecipe(
    Household household,
    Recipe recipe,
    int? day,
  ) async {
    final body = {};
    if (day != null) body['day'] = day;
    final res = await delete(
      '${householdPath(household)}$baseRoute/recipe/${recipe.id}',
      body: jsonEncode(body),
    );

    return res.statusCode == 200;
  }

  Future<List<Recipe>?> getRecentPlannedRecipes(Household household) async {
    final res =
        await get('${householdPath(household)}$baseRoute/recent-recipes');
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => Recipe.fromJson(e)).toList();
  }

  Future<List<Recipe>?> getSuggestedRecipes(Household household) async {
    final res =
        await get('${householdPath(household)}$baseRoute/suggested-recipes');
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => Recipe.fromJson(e)).toList();
  }

  Future<List<Recipe>?> refreshSuggestedRecipes(Household household) async {
    final res = await get(
      '${householdPath(household)}$baseRoute/refresh-suggested-recipes',
    );
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => Recipe.fromJson(e)).toList();
  }
}
