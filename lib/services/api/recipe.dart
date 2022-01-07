import 'dart:convert';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension RecipeApi on ApiService {
  Future<List<Recipe>> getRecipes() async {
    final res = await get('/recipe');
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));
    return body.map((e) => Recipe.fromJson(e)).toList();
  }

  Future<List<Recipe>> getRecipesFiltered(List<Tag> filter) async {
    final res = await post('/recipe/filter',
        jsonEncode({"filter": filter.map((e) => e.toString()).toList()}));
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));
    return body.map((e) => Recipe.fromJson(e)).toList();
  }

  Future<List<Recipe>> searchRecipe(String query) async {
    final res = await get('/recipe/search?query=$query');
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));
    return body.map((e) => Recipe.fromJson(e)).toList();
  }

  Future<Recipe> getRecipe(Recipe recipe) async {
    final res = await get('/recipe/${recipe.id}');
    if (res.statusCode != 200) return null;

    final body = jsonDecode(res.body);
    return Recipe.fromJson(body);
  }

  Future<bool> addRecipe(Recipe recipe) async {
    final res = await post('/recipe', jsonEncode(recipe.toJson()));
    return res.statusCode == 200;
  }

  Future<bool> updateRecipe(Recipe recipe) async {
    final res = await post('/recipe/${recipe.id}', jsonEncode(recipe.toJson()));
    return res.statusCode == 200;
  }

  Future<bool> deleteRecipe(Recipe recipe) async {
    final res = await delete('/recipe/${recipe.id}');
    return res.statusCode == 200;
  }
}
