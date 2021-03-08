import 'dart:convert';

import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension ShoppinglistApi on ApiService {
  Future<List<ShoppinglistItem>> getItems() async {
    final res = await get('/shoppinglist/1/items');
    if (res.statusCode != 200) return [];

    final body = List.from(jsonDecode(res.body));
    return body.map((e) => ShoppinglistItem.fromJson(e)).toList();
  }

  Future<List<Item>> getRecentItems() async {
    final res = await get('/shoppinglist/1/recent-items');
    if (res.statusCode != 200) return [];

    final body = List.from(jsonDecode(res.body));
    return body.map((e) => Item.fromJson(e)).toList();
  }

  Future<void> addItemByName(String name) async {
    await post('/shoppinglist/1/item', jsonEncode({'name': name}));
  }

  Future<void> addRecipeItems(List<RecipeItem> items) async {
    await post('/shoppinglist/1/recipeitems',
        jsonEncode({'items': items.map((e) => e.toJsonWithId()).toList()}));
  }

  Future<void> removeItem(ShoppinglistItem item) async {
    await delete(
      '/shoppinglist/1/item',
      body: jsonEncode({'item_id': item.id}),
    );
  }
}
