import 'dart:convert';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/planner.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension PlannerApi on ApiService {
  static const baseRoute = '/planner';

  Future<List<RecipePlan>?> getPlanned(Household household) async {
    final res = await get('${householdPath(household)}$baseRoute');
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => RecipePlan.fromJson(e)).toList();
  }

  Future<bool> addPlannedRecipe(
    Household household,
    RecipePlan recipePlan,
  ) async {
    final res = await post(
      '${householdPath(household)}$baseRoute/recipe',
      jsonEncode(recipePlan.toJson()),
    );

    return res.statusCode == 200;
  }

  Future<bool> removePlannedRecipe(
    Household household,
    Recipe recipe,
    DateTime? cooking_date,
  ) async {
    final body = {};
    if (cooking_date != null) body['cooking_date'] = cooking_date.millisecondsSinceEpoch;
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
