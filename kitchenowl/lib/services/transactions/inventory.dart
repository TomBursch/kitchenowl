import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/enums/inventory_sorting.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/inventory.dart';
import 'package:kitchenowl/services/api/inventory.dart';
import 'package:kitchenowl/services/storage/mem_storage.dart';
import 'package:kitchenowl/services/transaction.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class TransactionInventoryGet extends Transaction<List<Inventory>> {
  final Household household;
  final InventorySorting sorting;

  TransactionInventoryGet({
    DateTime? timestamp,
    required this.household,
    this.sorting = InventorySorting.alphabetical,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionInventoryGet",
        );

  @override
  Future<List<Inventory>> runLocal() async {
    return await MemStorage.getInstance().readInventories(household) ?? [];
  }

  @override
  Future<List<Inventory>?> runOnline() async {
    final lists = await ApiService.getInstance().getInventories(
      household,
      sorting: sorting,
      recentItemlimit: App.settings.recentItemsCount + 3,
    );
    if (lists != null) {
      MemStorage.getInstance().writeInventories(household, lists);
    }

    return lists;
  }
}

class TransactionInventorySearchItem extends Transaction<List<Item>> {
  final Household household;
  final String query;

  TransactionInventorySearchItem({
    required this.household,
    required this.query,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionInventorySearchItem",
        );

  @override
  Future<List<Item>> runLocal() async {
    final inventories =
        await MemStorage.getInstance().readInventories(household);
    return (inventories
            ?.map((inventory) =>
                inventory.recentItems
                    .map((e) => Item.fromItem(item: e))
                    .toList() +
                inventory.items)
            .fold<List<Item>>(
          [],
          (p, e) => p + e,
        ) ??
        [])
      ..retainWhere((e) => e.name.toLowerCase().contains(query.toLowerCase()));
  }

  @override
  Future<List<Item>?> runOnline() async {
    return await ApiService.getInstance().searchItem(household, query);
  }
}

class TransactionInventoryAddItem extends Transaction<bool> {
  final Household household;
  final Inventory inventory;
  final Item item;

  TransactionInventoryAddItem({
    required this.household,
    required this.inventory,
    required this.item,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionInventoryAddItem",
        );

  factory TransactionInventoryAddItem.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) =>
      TransactionInventoryAddItem(
        household: Household.fromJson(map['household']),
        inventory: Inventory.fromJson(map['inventory']),
        item: ItemWithDescription.fromJson(map['item']),
        timestamp: timestamp,
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "household": household.toJsonWithId(),
      "inventory": inventory.toJsonWithId(),
      "item": item.toJsonWithId(),
    });

  @override
  Future<bool> runLocal() async {
    final inventories =
        await MemStorage.getInstance().readInventories(household) ?? [];
    final latestInventory =
        inventories.where((e) => e.id == inventory.id).firstOrNull;
    if (latestInventory == null) return false;
    latestInventory.items.add(InventoryItem.fromItem(item: item));
    latestInventory.recentItems
        .removeWhere((item) => item.name == this.item.name);
    MemStorage.getInstance().writeInventories(household, inventories);

    return true;
  }

  @override
  Future<bool?> runOnline() {
    if (item.id != null) {
      return ApiService.getInstance().putInventoryItem(
        inventory,
        item,
      );
    } else {
      return ApiService.getInstance().addInventoryItemByName(
        inventory,
        item.name,
        (item is ItemWithDescription
            ? (item as ItemWithDescription).description
            : ""),
      );
    }
  }
}

class TransactionInventoryRemoveItem extends Transaction<bool> {
  final Household household;
  final Inventory inventory;
  final InventoryItem item;

  TransactionInventoryRemoveItem({
    DateTime? timestamp,
    required this.household,
    required this.item,
    required this.inventory,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionInventoryDeleteItem",
        );

  factory TransactionInventoryRemoveItem.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) =>
      TransactionInventoryRemoveItem(
        household: Household.fromJson(map['household']),
        inventory: Inventory.fromJson(map['inventory']),
        item: InventoryItem.fromJson(map['item']),
        timestamp: timestamp,
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'household': household.toJsonWithId(),
      "inventory": inventory.toJsonWithId(),
      "item": item.toJsonWithId(),
    });

  @override
  Future<bool> runLocal() async {
    final inventories =
        await MemStorage.getInstance().readInventories(household) ?? [];
    final latestInventory =
        inventories.where((e) => e.id == inventory.id).firstOrNull;
    if (latestInventory == null) return false;
    latestInventory.items.removeWhere((e) => e.name == item.name);
    latestInventory.recentItems.removeWhere((e) => e.name == item.name);
    latestInventory.recentItems.insert(0, item);
    MemStorage.getInstance().writeInventories(household, inventories);

    return true;
  }

  @override
  Future<bool?> runOnline() {
    runLocal();

    return ApiService.getInstance()
        .removeInventoryItem(inventory, item, timestamp);
  }
}

class TransactionInventoryRemoveItems extends Transaction<bool> {
  final Household household;
  final Inventory inventory;
  final List<InventoryItem> items;

  TransactionInventoryRemoveItems({
    DateTime? timestamp,
    required this.household,
    required this.items,
    required this.inventory,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionInventoryDeleteItems",
        );

  factory TransactionInventoryRemoveItems.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) =>
      TransactionInventoryRemoveItems(
        household: Household.fromJson(map['household']),
        inventory: Inventory.fromJson(map['inventory']),
        items: List.from(map['items'])
            .map((e) => InventoryItem.fromJson(e))
            .toList(),
        timestamp: timestamp,
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'household': household.toJsonWithId(),
      "inventory": inventory.toJsonWithId(),
      "items": items.map((e) => e.toJsonWithId()).toList(),
    });

  @override
  Future<bool> runLocal() async {
    final inventories =
        await MemStorage.getInstance().readInventories(household) ?? [];
    final latestInventory =
        inventories.where((e) => e.id == inventory.id).firstOrNull;
    if (latestInventory == null) return false;
    latestInventory.items
        .removeWhere((e) => items.map((e) => e.name).contains(e.name));
    latestInventory.recentItems.insertAll(0, items);
    MemStorage.getInstance().writeInventories(household, inventories);

    return true;
  }

  @override
  Future<bool?> runOnline() {
    runLocal();

    return ApiService.getInstance()
        .removeInventoryItems(inventory, items, timestamp);
  }
}

class TransactionInventoryUpdateItem extends Transaction<bool> {
  final Household household;
  final Inventory inventory;
  final Item item;
  final String description;

  TransactionInventoryUpdateItem({
    required this.household,
    required this.inventory,
    required this.item,
    required this.description,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionInventoryUpdateItem",
        );

  factory TransactionInventoryUpdateItem.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) =>
      TransactionInventoryUpdateItem(
        household: Household.fromJson(map['household']),
        inventory: Inventory.fromJson(map['inventory']),
        item: Item.fromJson(map['item']),
        description: map['description'],
        timestamp: timestamp,
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      'household': household.toJsonWithId(),
      "inventory": inventory.toJsonWithId(),
      "item": item.toJsonWithId(),
      "description": description,
    });

  @override
  Future<bool> runLocal() async {
    final inventories =
        await MemStorage.getInstance().readInventories(household) ?? [];
    final latestInventory =
        inventories.where((e) => e.id == inventory.id).firstOrNull;
    if (latestInventory == null) return false;

    if (item is InventoryItem) {
      final int i = latestInventory.items.indexWhere((e) => e.id == item.id);
      latestInventory.items[i] =
          (item as InventoryItem).copyWith(description: description);
      MemStorage.getInstance().writeInventories(household, inventories);

      return true;
    } else if (description.isNotEmpty) {
      latestInventory.items
          .add(InventoryItem(name: item.name, description: description));
      latestInventory.recentItems
          .removeWhere((item) => item.name == this.item.name);
      MemStorage.getInstance().writeInventories(household, inventories);

      return true;
    }

    return false;
  }

  @override
  Future<bool?> runOnline() async {
    return ApiService.getInstance().putInventoryItem(
      inventory,
      ItemWithDescription.fromItem(item: item, description: description),
    );
  }
}

// class TransactionInventoryAddShoppingListItems extends Transaction<bool> {
//   final Household household;
//   final Inventory inventory;
//   final List<ShoppinglistItem> items;

//   TransactionInventoryAddShoppingListItems({
//     required this.household,
//     required this.inventory,
//     required this.items,
//     DateTime? timestamp,
//   }) : super.internal(
//           timestamp ?? DateTime.now(),
//           "TransactionInventoryAddRecipeItems",
//         );

//   factory TransactionInventoryAddShoppingListItems.fromJson(
//     Map<String, dynamic> map,
//     DateTime timestamp,
//   ) {
//     final List<ShoppinglistItem> items =
//         List.from(map['items'].map((e) => ShoppinglistItem.fromJson(e)));

//     return TransactionInventoryAddShoppingListItems(
//       household: Household.fromJson(map['household']),
//       inventory: Inventory.fromJson(map['inventory']),
//       items: items,
//       timestamp: timestamp,
//     );
//   }

//   @override
//   bool get saveTransaction => true;

//   @override
//   Map<String, dynamic> toJson() => super.toJson()
//     ..addAll({
//       "household": household.toJsonWithId(),
//       "inventory": inventory.toJsonWithId(),
//       "items": items.map((e) => e.toJsonWithId()).toList(),
//     });

//   @override
//   Future<bool> runLocal() async {
//     final inventories =
//         await MemStorage.getInstance().readInventories(household) ?? [];
//     final latestInventory =
//         inventories.where((e) => e.id == inventory.id).firstOrNull;
//     if (latestInventory == null) return false;

//     for (final item in items) {
//       final int i = latestInventory.items.indexWhere((e) => e.id == item.id);
//       if (i >= 0) {
//         latestInventory.items[i] = item.toInventoryItem();
//       } else {
//         latestInventory.items.add(item.toInventoryItem());
//         latestInventory.recentItems.removeWhere((e) => e.name == item.name);
//       }
//     }
//     MemStorage.getInstance().writeInventories(household, inventories);

//     return true;
//   }

//   @override
//   Future<bool?> runOnline() {
//     return ApiService.getInstance().addShoppingListItems(inventory, items);
//   }
// }
