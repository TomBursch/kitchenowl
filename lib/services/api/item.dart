import 'dart:convert';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension ItemApi on ApiService {
  static const baseRoute = '/item';

  Future<Item?> getItem(Item item) async {
    final res = await get('$baseRoute/${item.id}');
    if (res.statusCode != 200) return null;

    final body = jsonDecode(res.body);

    return Item.fromJson(body);
  }

  Future<List<Recipe>?> getItemRecipes(Item item) async {
    final res = await get('$baseRoute/${item.id}/recipes');
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => Recipe.fromJson(e)).toList();
  }

  Future<List<ItemWithDescription>?> searchItem(
    Household household,
    String query,
  ) async {
    final res =
        await get('${householdPath(household)}$baseRoute/search?query=$query');
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => ItemWithDescription.fromJson(e)).toList();
  }

  Future<bool> deleteItem(Item item) async {
    final res = await delete('$baseRoute/${item.id}');

    return res.statusCode == 200;
  }

  Future<bool> updateItem(Item item) async {
    final res =
        await post('$baseRoute/${item.id}', jsonEncode(item.toJsonWithId()));

    return res.statusCode == 200;
  }
}
