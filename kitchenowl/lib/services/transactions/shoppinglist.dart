import 'package:kitchenowl/enums/shoppinglist_sorting.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/services/storage/mem_storage.dart';
import 'package:kitchenowl/services/storage/transaction_storage.dart';
import 'package:kitchenowl/services/transaction.dart';
import 'package:kitchenowl/services/api/api_service.dart';

class TransactionShoppingListGet extends Transaction<List<ShoppingList>> {
  final Household household;

  TransactionShoppingListGet({DateTime? timestamp, required this.household})
      : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionShoppingListGet",
        );

  @override
  Future<List<ShoppingList>> runLocal() async {
    return await MemStorage.getInstance().readShoppingLists(household) ?? [];
  }

  @override
  Future<List<ShoppingList>?> runOnline() async {
    final lists = await ApiService.getInstance().getShoppingLists(household);
    if (lists != null) {
      MemStorage.getInstance().writeShoppingLists(household, lists);
    }

    return lists;
  }
}

class TransactionShoppingListGetItems
    extends Transaction<List<ShoppinglistItem>> {
  final ShoppingList shoppinglist;
  final ShoppinglistSorting sorting;

  TransactionShoppingListGetItems({
    DateTime? timestamp,
    required this.shoppinglist,
    required this.sorting,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionShoppingListGetItems",
        );

  @override
  Future<List<ShoppinglistItem>> runLocal() async {
    final l = await MemStorage.getInstance().readItems(shoppinglist) ?? [];
    ShoppinglistSorting.sortShoppinglistItems(l, sorting);

    return l;
  }

  @override
  Future<List<ShoppinglistItem>?> runOnline() async {
    final items =
        await ApiService.getInstance().getItems(shoppinglist, sorting);
    if (items != null) {
      MemStorage.getInstance().writeItems(shoppinglist, items);
    }

    return items;
  }
}

class TransactionShoppingListSearchItem extends Transaction<List<Item>> {
  final Household household;
  final String query;

  TransactionShoppingListSearchItem({
    required this.household,
    required this.query,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionShoppingListSearchItem",
        );

  @override
  Future<List<Item>> runLocal() async {
    final shoppinglist = await MemStorage.getInstance()
        .readShoppingLists(household)
        .then(
          (shoppingLists) => Future.wait<List<ShoppinglistItem>?>(
            shoppingLists
                    ?.map((shoppingList) =>
                        MemStorage.getInstance().readItems(shoppingList))
                    .toList() ??
                [],
          ),
        )
        .then<List<ShoppinglistItem>>((e) => e.fold<List<ShoppinglistItem>>(
              [],
              (p, e) => p + (e ?? []),
            ));
    shoppinglist
        .retainWhere((e) => e.name.toLowerCase().contains(query.toLowerCase()));

    return shoppinglist;
  }

  @override
  Future<List<Item>?> runOnline() async {
    return await ApiService.getInstance().searchItem(household, query);
  }
}

class TransactionShoppingListGetRecentItems
    extends Transaction<List<ItemWithDescription>> {
  final ShoppingList shoppinglist;
  final int itemsCount;

  TransactionShoppingListGetRecentItems({
    DateTime? timestamp,
    required this.shoppinglist,
    required this.itemsCount,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionShoppingListGetRecentItems",
        );

  @override
  Future<List<ItemWithDescription>> runLocal() async {
    if (itemsCount <= 0) return [];
    final items =
        (await MemStorage.getInstance().readItems(shoppinglist) ?? const [])
            .map((e) => e.name)
            .toSet();

    return (await TransactionStorage.getInstance().readTransactions())
        .whereType<TransactionShoppingListDeleteItem>()
        .where((e) => e.shoppinglist.id == shoppinglist.id)
        .map((e) => e.item)
        .where((e) {
      if (items.contains(e.name)) {
        return false;
      } else {
        items.add(e.name);

        return true;
      }
    }).toList();
  }

  @override
  Future<List<ItemWithDescription>?> runOnline() async {
    if (itemsCount <= 0) return [];
    return await ApiService.getInstance()
        .getRecentItems(shoppinglist, itemsCount);
  }
}

class TransactionShoppingListAddItem extends Transaction<bool> {
  final ShoppingList shoppinglist;
  final Item item;

  TransactionShoppingListAddItem({
    required this.shoppinglist,
    required this.item,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionShoppingListAddItem",
        );

  factory TransactionShoppingListAddItem.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) =>
      TransactionShoppingListAddItem(
        shoppinglist: ShoppingList.fromJson(map['shoppinglist']),
        item: ItemWithDescription.fromJson(map['item']),
        timestamp: timestamp,
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "shoppinglist": shoppinglist.toJsonWithId(),
      "item": item.toJsonWithId(),
    });

  @override
  Future<bool> runLocal() async {
    final list = await MemStorage.getInstance().readItems(shoppinglist) ?? [];
    list.add(ShoppinglistItem.fromItem(item: item));
    MemStorage.getInstance().writeItems(shoppinglist, list);

    return true;
  }

  @override
  Future<bool?> runOnline() {
    if (item.id != null) {
      return ApiService.getInstance().putItem(
        shoppinglist,
        item,
      );
    } else {
      return ApiService.getInstance().addItemByName(
        shoppinglist,
        item.name,
        (item is ItemWithDescription
            ? (item as ItemWithDescription).description
            : ""),
      );
    }
  }
}

class TransactionShoppingListDeleteItem extends Transaction<bool> {
  final ShoppingList shoppinglist;
  final ShoppinglistItem item;

  TransactionShoppingListDeleteItem({
    DateTime? timestamp,
    required this.item,
    required this.shoppinglist,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionShoppingListDeleteItem",
        );

  factory TransactionShoppingListDeleteItem.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) =>
      TransactionShoppingListDeleteItem(
        shoppinglist: ShoppingList.fromJson(map['shoppinglist']),
        item: ShoppinglistItem.fromJson(map['item']),
        timestamp: timestamp,
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "shoppinglist": shoppinglist.toJsonWithId(),
      "item": item.toJsonWithId(),
    });

  @override
  Future<bool> runLocal() async {
    final list = await MemStorage.getInstance().readItems(shoppinglist) ?? [];
    list.removeWhere((e) => e.name == item.name);
    MemStorage.getInstance().writeItems(shoppinglist, list);

    return true;
  }

  @override
  Future<bool?> runOnline() {
    runLocal();

    return ApiService.getInstance().removeItem(shoppinglist, item, timestamp);
  }
}

class TransactionShoppingListDeleteItems extends Transaction<bool> {
  final ShoppingList shoppinglist;
  final List<ShoppinglistItem> items;

  TransactionShoppingListDeleteItems({
    DateTime? timestamp,
    required this.items,
    required this.shoppinglist,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionShoppingListDeleteItems",
        );

  factory TransactionShoppingListDeleteItems.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) =>
      TransactionShoppingListDeleteItems(
        shoppinglist: ShoppingList.fromJson(map['shoppinglist']),
        items: List.from(map['items'])
            .map((e) => ShoppinglistItem.fromJson(e))
            .toList(),
        timestamp: timestamp,
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "shoppinglist": shoppinglist.toJsonWithId(),
      "items": items.map((e) => e.toJsonWithId()).toList(),
    });

  @override
  Future<bool> runLocal() async {
    final list = await MemStorage.getInstance().readItems(shoppinglist) ?? [];
    list.removeWhere((e) => items.map((e) => e.name).contains(e.name));
    MemStorage.getInstance().writeItems(shoppinglist, list);

    return true;
  }

  @override
  Future<bool?> runOnline() {
    runLocal();

    return ApiService.getInstance().removeItems(shoppinglist, items, timestamp);
  }
}

class TransactionShoppingListUpdateItem extends Transaction<bool> {
  final ShoppingList shoppinglist;
  final Item item;
  final String description;

  TransactionShoppingListUpdateItem({
    required this.shoppinglist,
    required this.item,
    required this.description,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionShoppingListUpdateItem",
        );

  factory TransactionShoppingListUpdateItem.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) =>
      TransactionShoppingListUpdateItem(
        shoppinglist: ShoppingList.fromJson(map['shoppinglist']),
        item: Item.fromJson(map['item']),
        description: map['description'],
        timestamp: timestamp,
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "shoppinglist": shoppinglist.toJsonWithId(),
      "item": item.toJsonWithId(),
      "description": description,
    });

  @override
  Future<bool> runLocal() async {
    if (item is ShoppinglistItem) {
      final list = await MemStorage.getInstance().readItems(shoppinglist) ?? [];
      final int i = list.indexWhere((e) => e.id == item.id);
      list.removeAt(i);
      list.insert(
        i,
        (item as ShoppinglistItem).copyWith(description: description),
      );
      MemStorage.getInstance().writeItems(shoppinglist, list);

      return true;
    } else if (description.isNotEmpty) {
      final list = await MemStorage.getInstance().readItems(shoppinglist) ?? [];
      list.add(ShoppinglistItem(name: item.name, description: description));
      MemStorage.getInstance().writeItems(shoppinglist, list);

      return true;
    }

    return false;
  }

  @override
  Future<bool?> runOnline() async {
    return ApiService.getInstance().putItem(
      shoppinglist,
      ItemWithDescription.fromItem(item: item, description: description),
    );
  }
}

class TransactionShoppingListAddRecipeItems extends Transaction<bool> {
  final ShoppingList shoppinglist;
  final List<RecipeItem> items;

  TransactionShoppingListAddRecipeItems({
    required this.shoppinglist,
    required this.items,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionShoppingListAddRecipeItems",
        );

  factory TransactionShoppingListAddRecipeItems.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) {
    final List<RecipeItem> items =
        List.from(map['items'].map((e) => RecipeItem.fromJson(e)));

    return TransactionShoppingListAddRecipeItems(
      shoppinglist: ShoppingList.fromJson(map['shoppinglist']),
      items: items,
      timestamp: timestamp,
    );
  }

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "shoppinglist": shoppinglist.toJsonWithId(),
      "items": items.map((e) => e.toJsonWithId()).toList(),
    });

  @override
  Future<bool> runLocal() async {
    final list = await MemStorage.getInstance().readItems(shoppinglist) ?? [];
    for (final item in items) {
      final int i = list.indexWhere((e) => e.id == item.id);
      if (i >= 0) {
        list.removeAt(i);
        list.insert(i, item.toShoppingListItem());
      } else {
        list.add(item.toShoppingListItem());
      }
    }
    MemStorage.getInstance().writeItems(shoppinglist, list);

    return true;
  }

  @override
  Future<bool?> runOnline() {
    return ApiService.getInstance().addRecipeItems(shoppinglist, items);
  }
}
