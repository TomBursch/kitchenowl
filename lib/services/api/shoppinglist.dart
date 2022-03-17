import 'dart:convert';

import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension ShoppinglistApi on ApiService {
  Future<ShoppinglistItem?> getShoppingListItem(Item item) async {
    final res = await get('/shoppinglist/1/item/${item.id}');
    if (res.statusCode != 200) return null;

    final body = jsonDecode(res.body);

    return ShoppinglistItem.fromJson(body);
  }

  Future<List<ShoppinglistItem>?> getItems() async {
    final res = await get('/shoppinglist/1/items');
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => ShoppinglistItem.fromJson(e)).toList();
  }

  Future<List<Item>?> getRecentItems() async {
    final res = await get('/shoppinglist/1/recent-items');
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => Item.fromJson(e)).toList();
  }

  Future<bool> addItemByName(String name, [String? description]) async {
    final data = {'name': name};
    if (description != null) data['description'] = description;
    final res =
        await post('/shoppinglist/1/add-item-by-name', jsonEncode(data));

    return res.statusCode == 200;
  }

  Future<bool> addRecipeItems(List<RecipeItem> items) async {
    final res = await post(
      '/shoppinglist/1/recipeitems',
      jsonEncode({'items': items.map((e) => e.toJsonWithId()).toList()}),
    );

    return res.statusCode == 200;
  }

  Future<bool> updateShoppingListItemDescription(
    Item item,
    String description,
  ) async {
    final data = {'description': description};
    final res = await post('/shoppinglist/1/item/${item.id}', jsonEncode(data));

    return res.statusCode == 200;
  }

  Future<bool> removeItem(ShoppinglistItem item) async {
    final res = await delete(
      '/shoppinglist/1/item',
      body: jsonEncode({'item_id': item.id}),
    );

    return res.statusCode == 200;
  }
}
