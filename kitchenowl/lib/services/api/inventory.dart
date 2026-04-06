import 'dart:convert';

import 'package:kitchenowl/enums/inventory_sorting.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/inventory.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension InventoryApi on ApiService {
  static const baseRoute = '/inventory';
  String route({Household? household, Inventory? inventory}) =>
      "${household != null ? householdPath(household) : ""}$baseRoute${inventory?.id != null ? "/${inventory!.id}" : ""}";

  Future<List<Inventory>?> getInventories(
    Household household, {
    InventorySorting sorting = InventorySorting.alphabetical,
    int recentItemlimit = 9,
  }) async {
    recentItemlimit = recentItemlimit > 120 ? 120 : recentItemlimit;
    final res = await get(
      route(household: household),
      queryParameters: {
        'orderby': sorting.index.toString(),
        'recent_limit': recentItemlimit.toString(),
      },
    );
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => Inventory.fromJson(e)).toList();
  }

  Future<bool> addInventory(
    Household household,
    Inventory inventory,
  ) async {
    final res = await post(
      route(household: household),
      jsonEncode(inventory.toJson()),
    );

    return res.statusCode == 200;
  }

  Future<bool> updateInventory(
    Inventory inventory,
  ) async {
    final res = await post(
      route(inventory: inventory),
      jsonEncode(inventory.toJson()),
    );

    return res.statusCode == 200;
  }

  Future<bool> deleteInventory(
    Inventory inventory,
  ) async {
    final res = await delete(route(inventory: inventory));

    return res.statusCode == 200;
  }

  Future<bool> putInventoryItem(
    Inventory inventory,
    Item item,
  ) async {
    final Map<String, dynamic> data = {};
    if (item is ItemWithDescription) {
      data['description'] = item.description;
    }
    final res = await put(
      '${route(inventory: inventory)}/item/${item.id}',
      jsonEncode(data),
    );

    return res.statusCode == 200;
  }

  Future<bool> addInventoryItemByName(
    Inventory inventory,
    String name, [
    String? description,
  ]) async {
    final data = {'name': name};
    if (description != null) data['description'] = description;
    final res = await post(
      '${route(inventory: inventory)}/add-item-by-name',
      jsonEncode(data),
    );

    return res.statusCode == 200;
  }

  Future<bool> addShoppingListItems(
    Inventory inventory,
    List<ShoppinglistItem> items,
  ) async {
    final res = await post(
      '${route(inventory: inventory)}/shoppinglistitems',
      jsonEncode({'items': items.map((e) => e.toJsonWithId()).toList()}),
    );

    return res.statusCode == 200;
  }

  Future<bool> removeInventoryItem(
    Inventory inventory,
    InventoryItem item, [
    DateTime? time,
  ]) async {
    final res = await delete(
      '${route(inventory: inventory)}/item',
      body: jsonEncode({
        'item_id': item.id,
        if (time != null) 'removed_at': time.toUtc().millisecondsSinceEpoch,
      }),
    );

    return res.statusCode == 200;
  }

  Future<bool> removeInventoryItems(
    Inventory inventory,
    List<InventoryItem> items, [
    DateTime? time,
  ]) async {
    final res = await delete(
      '${route(inventory: inventory)}/items',
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

  void onInventoryAdd(dynamic Function(dynamic) handler) {
    socket.on("inventory:add", handler);
  }

  void offInventoryAdd(dynamic Function(dynamic) handler) {
    socket.off("inventory:add", handler);
  }

  void onInventoryDelete(dynamic Function(dynamic) handler) {
    socket.on("inventory:delete", handler);
  }

  void offInventoryDelete(dynamic Function(dynamic) handler) {
    socket.off("inventory:delete", handler);
  }

  void onInventoryItemAdd(dynamic Function(dynamic) handler) {
    socket.on("inventory_item:add", handler);
  }

  void offInventoryItemAdd(dynamic Function(dynamic) handler) {
    socket.off("inventory_item:add", handler);
  }

  void onInventoryItemRemove(dynamic Function(dynamic) handler) {
    socket.on("inventory_item:remove", handler);
  }

  void offInventoryItemRemove(dynamic Function(dynamic) handler) {
    socket.off("inventory_item:remove", handler);
  }
}
