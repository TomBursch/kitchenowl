import 'dart:convert';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/recipe_scrape.dart';
import 'package:kitchenowl/models/recipe_suggestions.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension RecipeApi on ApiService {
  static const baseRoute = '/recipe';

  // ignore: constant_identifier_names
  static const Duration _TIMEOUT_SCRAPE = Duration(minutes: 3);
  // Used by paginated and delta-sync requests that may transfer many pages.
  // ignore: constant_identifier_names
  static const Duration _TIMEOUT_GET_RECIPES_LONG = Duration(seconds: 60);

  Future<List<Recipe>?> getRecipesFiltered(
    Household household,
    Set<Tag> filter, {
    bool slim = true,
  }) async {
    final res = await post(
      '${householdPath(household)}$baseRoute/filter',
      jsonEncode({
        "filter": filter.map((e) => e.toString()).toList(),
        if (slim) "details": "slim",
      }),
    );
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => Recipe.fromJson(e)).toList();
  }

  Future<List<int>?> searchRecipeById(Household household, String query) async {
    final res = await get(
      '${householdPath(household)}$baseRoute/search',
      queryParameters: {
        'only_ids': true.toString(),
        'query': query,
      },
    );
    if (res.statusCode != 200) return null;

    return List.from(jsonDecode(res.body));
  }

  Future<List<Recipe>?> searchRecipe(
    Household household,
    String query, {
    bool slim = true,
  }) async {
    final res = await get(
      '${householdPath(household)}$baseRoute/search',
      queryParameters: {
        'query': query,
        if (slim) 'details': 'slim',
      },
    );
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => Recipe.fromJson(e)).toList();
  }

  Future<({List<Recipe> items, int total, bool hasMore})?> getRecipesPaginated(
    Household household, {
    int page = 0,
    int perPage = 50,
  }) async {
    final res = await get(
      householdPath(household) + baseRoute,
      queryParameters: {
        'details': 'slim',
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
      timeout: _TIMEOUT_GET_RECIPES_LONG,
    );
    if (res.statusCode != 200) return null;

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final items = (body['items'] as List)
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList();
    final total = body['total'] as int;
    final hasMore = (page + 1) * perPage < total;
    return (items: items, total: total, hasMore: hasMore);
  }

  Future<({List<Recipe> recipes, List<int> deletedIds, bool hasMore, int serverTime})?> getRecipesDeltaSync(
    Household household, {
    int updatedAfter = 0,
    int page = 0,
    int perPage = 50,
  }) async {
    final res = await get(
      '${householdPath(household)}$baseRoute/sync',
      queryParameters: {
        'updated_after': updatedAfter.toString(),
        'page': page.toString(),
        'per_page': perPage.toString(),
      },
      timeout: _TIMEOUT_GET_RECIPES_LONG,
    );
    if (res.statusCode != 200) return null;

    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final recipes = (body['recipes'] as List)
        .map((e) => Recipe.fromJson(e as Map<String, dynamic>))
        .toList();
    final deletedIds =
        (body['deleted_ids'] as List).map((e) => e as int).toList();
    final hasMore = body['has_more'] as bool;
    final serverTime = (body['server_time'] as num).toInt();
    return (recipes: recipes, deletedIds: deletedIds, hasMore: hasMore, serverTime: serverTime);
  }

  Future<(Recipe?, int)> getRecipe(Recipe recipe) async {
    final res = await get('$baseRoute/${recipe.id}');
    if (res.statusCode != 200) return (null, res.statusCode);

    final body = jsonDecode(res.body);

    return (Recipe.fromJson(body), 0);
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
      timeout: _TIMEOUT_SCRAPE,
    );
    if (res.statusCode != 200) return (null, res.statusCode);

    final body = jsonDecode(res.body);

    return (RecipeScrape.fromJson(body), 200);
  }

  Future<List<Recipe>?> searchAllRecipes(String query,
      [int page = 0, String? language]) async {
    final res = await get(
      '$baseRoute/search',
      queryParameters: {
        'page': page.toString(),
        'query': query,
        if (language != null) 'language': language,
      },
    );
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => Recipe.fromJson(e)).toList();
  }

  Future<List<Recipe>?> searchAllRecipesByTag(String tag,
      [int page = 0, String? language]) async {
    final res = await get(
      '$baseRoute/search-tag',
      queryParameters: {
        'page': page.toString(),
        'tag': tag,
        if (language != null) 'language': language,
      },
    );
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => Recipe.fromJson(e)).toList();
  }

  Future<List<Recipe>?> getNewestRecipesOfHousehold(
      Household household, int page) async {
    final res = await get("${householdPath(household)}$baseRoute/newest/$page");
    if (res.statusCode != 200) return null;

    final body = jsonDecode(res.body);
    return (body as List<dynamic>).map((e) => Recipe.fromJson(e)).toList();
  }

  Future<RecipeDiscover?> discoverRecipes(String? language) async {
    final res = await get(
      "$baseRoute/discover",
      queryParameters: {
        if (language != null) 'language': language,
      },
    );
    if (res.statusCode != 200) return null;

    final body = jsonDecode(res.body);
    return RecipeDiscover.fromJson(body);
  }

  Future<List<Recipe>?> discoverRecipesCurated(
      String? language, int page) async {
    final res = await get(
      "$baseRoute/discover/curated/$page",
      queryParameters: {
        if (language != null) 'language': language,
      },
    );
    if (res.statusCode != 200) return null;

    final body = jsonDecode(res.body);
    return (body as List<dynamic>).map((e) => Recipe.fromJson(e)).toList();
  }

  Future<List<Recipe>?> discoverRecipesPopular(
      String? language, int page) async {
    final res = await get(
      "$baseRoute/discover/popular/$page",
      queryParameters: {
        if (language != null) 'language': language,
      },
    );
    if (res.statusCode != 200) return null;

    final body = jsonDecode(res.body);
    return (body as List<dynamic>).map((e) => Recipe.fromJson(e)).toList();
  }

  Future<List<Recipe>?> discoverRecipesNewest(
      String? language, int page) async {
    final res = await get(
      "$baseRoute/discover/newest/$page",
      queryParameters: {
        if (language != null) 'language': language,
      },
    );
    if (res.statusCode != 200) return null;

    final body = jsonDecode(res.body);
    return (body as List<dynamic>).map((e) => Recipe.fromJson(e)).toList();
  }
}
