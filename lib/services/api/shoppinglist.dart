import 'dart:convert';

import 'package:kitchenowl/enums/shoppinglist_sorting.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension ShoppinglistApi on ApiService {
  static const baseRoute = '/shoppinglist/1';

  Future<ShoppinglistItem?> getShoppingListItem(Item item) async {
    final res = await get('$baseRoute/item/${item.id}');
    if (res.statusCode != 200) return null;

    final body = jsonDecode(res.body);

    return ShoppinglistItem.fromJson(body);
  }

  Future<List<ShoppinglistItem>?> getItems([
    ShoppinglistSorting sorting = ShoppinglistSorting.alphabetical,
  ]) async {
    final res = await get('$baseRoute/items?orderby=${sorting.index}');
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => ShoppinglistItem.fromJson(e)).toList();
  }

  Future<List<ItemWithDescription>?> getRecentItems() async {
    final res = await get('$baseRoute/recent-items');
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => ItemWithDescription.fromJson(e)).toList();
  }

  Future<bool> addItemByName(String name, [String? description]) async {
    final data = {'name': name};
    if (description != null) data['description'] = description;
    final res = await post('$baseRoute/add-item-by-name', jsonEncode(data));

    return res.statusCode == 200;
  }

  Future<bool> addRecipeItems(List<RecipeItem> items) async {
    final res = await post(
      '$baseRoute/recipeitems',
      jsonEncode({'items': items.map((e) => e.toJsonWithId()).toList()}),
    );

    return res.statusCode == 200;
  }

  Future<bool> updateShoppingListItemDescription(
    Item item,
    String description,
  ) async {
    final data = {'description': description};
    final res = await post('$baseRoute/item/${item.id}', jsonEncode(data));

    return res.statusCode == 200;
  }

  Future<bool> removeItem(ShoppinglistItem item) async {
    final res = await delete(
      '$baseRoute/item',
      body: jsonEncode({'item_id': item.id}),
    );

    return res.statusCode == 200;
  }
}
