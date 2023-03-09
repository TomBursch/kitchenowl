import 'dart:convert';

import 'package:kitchenowl/enums/shoppinglist_sorting.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension ShoppinglistApi on ApiService {
  static const baseRoute = '/shoppinglist';
  static route([ShoppingList? shoppinglist]) =>
      "$baseRoute/${shoppinglist?.id ?? 1}";

  Future<List<ShoppingList>?> getShoppingLists(Household household) async {
    final res = await get(baseRoute);
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => ShoppingList.fromJson(e)).toList();
  }

  Future<bool> addShoppingList(
    Household household,
    ShoppingList shoppingList,
  ) async {
    final res = await post(
      baseRoute,
      jsonEncode(shoppingList.toJson()),
    );

    return res.statusCode == 200;
  }

  Future<bool> updateShoppingList(ShoppingList shoppingList) async {
    final res = await post(
      '$baseRoute/${shoppingList.id}',
      jsonEncode(shoppingList.toJson()),
    );

    return res.statusCode == 200;
  }

  Future<bool> deleteShoppingList(ShoppingList shoppingList) async {
    final res = await delete('$baseRoute/${shoppingList.id}');

    return res.statusCode == 200;
  }

  Future<List<ShoppinglistItem>?> getItems(
    ShoppingList shoppinglist, [
    ShoppinglistSorting sorting = ShoppinglistSorting.alphabetical,
  ]) async {
    final res =
        await get('${route(shoppinglist)}/items?orderby=${sorting.index}');
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => ShoppinglistItem.fromJson(e)).toList();
  }

  Future<List<ItemWithDescription>?> getRecentItems(
    ShoppingList shoppinglist,
  ) async {
    final res = await get('${route(shoppinglist)}/recent-items');
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => ItemWithDescription.fromJson(e)).toList();
  }

  Future<bool> addItemByName(
    ShoppingList shoppinglist,
    String name, [
    String? description,
  ]) async {
    final data = {'name': name};
    if (description != null) data['description'] = description;
    final res =
        await post('${route(shoppinglist)}/add-item-by-name', jsonEncode(data));

    return res.statusCode == 200;
  }

  Future<bool> addRecipeItems(List<RecipeItem> items) async {
    final res = await post(
      '${route()}/recipeitems',
      jsonEncode({'items': items.map((e) => e.toJsonWithId()).toList()}),
    );

    return res.statusCode == 200;
  }

  Future<bool> updateShoppingListItemDescription(
    ShoppingList shoppinglist,
    Item item,
    String description,
  ) async {
    final data = {'description': description};
    final res =
        await post('${route(shoppinglist)}/item/${item.id}', jsonEncode(data));

    return res.statusCode == 200;
  }

  Future<bool> removeItem(
    ShoppingList shoppinglist,
    ShoppinglistItem item, [
    DateTime? time,
  ]) async {
    final res = await delete(
      '${route(shoppinglist)}/item',
      body: jsonEncode({
        'item_id': item.id,
        if (time != null) 'removed_at': time.toUtc().millisecondsSinceEpoch,
      }),
    );

    return res.statusCode == 200;
  }
}
