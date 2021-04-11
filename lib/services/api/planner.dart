import 'dart:convert';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension PlannerApi on ApiService {
  Future<List<Recipe>> getPlannedRecipes() async {
    final res = await get('/planner/recipes');
    if (res.statusCode != 200) return [];

    final body = List.from(jsonDecode(res.body));
    return body.map((e) => Recipe.fromJson(e)).toList();
  }

  Future<bool> addPlannedRecipe(Recipe recipe) async {
    final body = {"recipe_id": recipe.id};
    final res = await post('/planner/recipe', jsonEncode(body));
    return res.statusCode == 200;
  }

  Future<bool> removePlannedRecipe(Recipe recipe) async {
    final res = await delete('/planner/recipe/${recipe.id}');
    return res.statusCode == 200;
  }
}
