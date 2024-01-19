import 'dart:convert';

import 'package:kitchenowl/enums/shoppinglist_sorting.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension ShoppinglistApi on ApiService {
  static const baseRoute = '/shoppinglist';
  String route({Household? household, ShoppingList? shoppinglist}) =>
      "${household != null ? householdPath(household) : ""}$baseRoute${shoppinglist?.id != null ? "/${shoppinglist!.id}" : ""}";

  Future<List<ShoppingList>?> getShoppingLists(Household household) async {
    final res = await get(route(household: household));
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => ShoppingList.fromJson(e)).toList();
  }

  Future<bool> addShoppingList(
    Household household,
    ShoppingList shoppingList,
  ) async {
    final res = await post(
      route(household: household),
      jsonEncode(shoppingList.toJson()),
    );

    return res.statusCode == 200;
  }

  Future<bool> updateShoppingList(
    ShoppingList shoppingList,
  ) async {
    final res = await post(
      route(shoppinglist: shoppingList),
      jsonEncode(shoppingList.toJson()),
    );

    return res.statusCode == 200;
  }

  Future<bool> deleteShoppingList(
    ShoppingList shoppingList,
  ) async {
    final res = await delete(route(shoppinglist: shoppingList));

    return res.statusCode == 200;
  }

  Future<List<ShoppinglistItem>?> getItems(
    ShoppingList shoppinglist, [
    ShoppinglistSorting sorting = ShoppinglistSorting.alphabetical,
  ]) async {
    final res = await get(
      '${route(shoppinglist: shoppinglist)}/items?orderby=${sorting.index}',
    );
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => ShoppinglistItem.fromJson(e)).toList();
  }

  Future<List<ItemWithDescription>?> getRecentItems(
    ShoppingList shoppinglist, [
    int limit = 9,
  ]) async {
    final res = await get(
      '${route(shoppinglist: shoppinglist)}/recent-items?limit=$limit',
    );
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => ItemWithDescription.fromJson(e)).toList();
  }

  Future<bool> putItem(
    ShoppingList shoppinglist,
    Item item,
  ) async {
    final Map<String, dynamic> data = {};
    if (item is ItemWithDescription) {
      data['description'] = item.description;
    }
    final res = await put(
      '${route(shoppinglist: shoppinglist)}/item/${item.id}',
      jsonEncode(data),
    );

    return res.statusCode == 200;
  }

  Future<bool> addItemByName(
    ShoppingList shoppinglist,
    String name, [
    String? description,
  ]) async {
    final data = {'name': name};
    if (description != null) data['description'] = description;
    final res = await post(
      '${route(shoppinglist: shoppinglist)}/add-item-by-name',
      jsonEncode(data),
    );

    return res.statusCode == 200;
  }

  Future<bool> addRecipeItems(
    ShoppingList shoppinglist,
    List<RecipeItem> items,
  ) async {
    final res = await post(
      '${route(shoppinglist: shoppinglist)}/recipeitems',
      jsonEncode({'items': items.map((e) => e.toJsonWithId()).toList()}),
    );

    return res.statusCode == 200;
  }

  Future<bool> removeItem(
    ShoppingList shoppinglist,
    ShoppinglistItem item, [
    DateTime? time,
  ]) async {
    final res = await delete(
      '${route(shoppinglist: shoppinglist)}/item',
      body: jsonEncode({
        'item_id': item.id,
        if (time != null) 'removed_at': time.toUtc().millisecondsSinceEpoch,
      }),
    );

    return res.statusCode == 200;
  }

  Future<bool> removeItems(
    ShoppingList shoppinglist,
    List<ShoppinglistItem> items, [
    DateTime? time,
  ]) async {
    final res = await delete(
      '${route(shoppinglist: shoppinglist)}/items',
      body: jsonEncode({
        "items": items
            .map(
              (item) => {
                'item_id': item.id,
                if (time != null)
                  'removed_at': time.toUtc().millisecondsSinceEpoch,
              },
            )
            .toList(),
      }),
    );

    return res.statusCode == 200;
  }

  void onShoppinglistItemAdd(dynamic Function(dynamic) handler) {
    socket.on("shoppinglist_item:add", handler);
  }

  void offShoppinglistItemAdd(dynamic Function(dynamic) handler) {
    socket.off("shoppinglist_item:add", handler);
  }

  void onShoppinglistItemRemove(dynamic Function(dynamic) handler) {
    socket.on("shoppinglist_item:remove", handler);
  }

  void offShoppinglistItemRemove(dynamic Function(dynamic) handler) {
    socket.off("shoppinglist_item:remove", handler);
  }
}
