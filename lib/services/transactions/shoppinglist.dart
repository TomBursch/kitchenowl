import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/services/transaction.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/storage/temp_storage.dart';

class TransactionShoppingListGetItems
    extends Transaction<List<ShoppinglistItem>> {
  TransactionShoppingListGetItems({DateTime? timestamp})
      : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionShoppingListGetItems",
        );

  @override
  Future<List<ShoppinglistItem>> runLocal() async {
    return await TempStorage.getInstance().readItems() ?? const [];
  }

  @override
  Future<List<ShoppinglistItem>> runOnline() async {
    final shoppinglist = await ApiService.getInstance().getItems();
    if (shoppinglist != null) {
      TempStorage.getInstance().writeItems(shoppinglist);
    }

    return shoppinglist ?? const [];
  }
}

class TransactionShoppingListSearchItem extends Transaction<List<Item>> {
  final String query;
  TransactionShoppingListSearchItem({required this.query, DateTime? timestamp})
      : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionShoppingListSearchItem",
        );

  @override
  Future<List<Item>> runLocal() async {
    final shoppinglist =
        await TempStorage.getInstance().readItems() ?? const [];
    shoppinglist
        .retainWhere((e) => e.name.toLowerCase().contains(query.toLowerCase()));

    return shoppinglist;
  }

  @override
  Future<List<Item>> runOnline() async {
    return await ApiService.getInstance().searchItem(query) ?? [];
  }
}

class TransactionShoppingListGetRecentItems extends Transaction<List<Item>> {
  TransactionShoppingListGetRecentItems({DateTime? timestamp})
      : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionShoppingListGetRecentItems",
        );

  @override
  Future<List<Item>> runLocal() async {
    return [];
  }

  @override
  Future<List<Item>> runOnline() async {
    return await ApiService.getInstance().getRecentItems() ?? const [];
  }
}

class TransactionShoppingListAddItem extends Transaction<bool> {
  final String name;
  final String description;

  TransactionShoppingListAddItem({
    required this.name,
    required this.description,
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
        name: map['name'],
        description: map['description'],
        timestamp: timestamp,
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "name": name,
      "description": description,
    });

  @override
  Future<bool> runLocal() async {
    final list = await TempStorage.getInstance().readItems() ?? [];
    list.add(ShoppinglistItem(name: name, description: description));
    TempStorage.getInstance().writeItems(list);

    return true;
  }

  @override
  Future<bool> runOnline() {
    return ApiService.getInstance().addItemByName(name, description);
  }
}

class TransactionShoppingListDeleteItem extends Transaction<bool> {
  final ShoppinglistItem item;

  TransactionShoppingListDeleteItem({DateTime? timestamp, required this.item})
      : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionShoppingListDeleteItem",
        );

  factory TransactionShoppingListDeleteItem.fromJson(
    Map<String, dynamic> map,
    DateTime timestamp,
  ) =>
      TransactionShoppingListDeleteItem(
        item: ShoppinglistItem.fromJson(map['item']),
        timestamp: timestamp,
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "item": item.toJsonWithId(),
    });

  @override
  Future<bool> runLocal() async {
    final list = await TempStorage.getInstance().readItems() ?? [];
    list.removeWhere((e) => e.name == item.name);
    TempStorage.getInstance().writeItems(list);

    return true;
  }

  @override
  Future<bool> runOnline() {
    return ApiService.getInstance().removeItem(item);
  }
}

class TransactionShoppingListUpdateItem extends Transaction<bool> {
  final Item item;
  final String description;

  TransactionShoppingListUpdateItem({
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
        item: Item.fromJson(map['item']),
        description: map['description'],
        timestamp: timestamp,
      );

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "item": item.toJsonWithId(),
      "description": description,
    });

  @override
  Future<bool> runLocal() async {
    if (item is ShoppinglistItem) {
      final list = await TempStorage.getInstance().readItems() ?? [];
      final int i = list.indexWhere((e) => e.id == item.id);
      list.removeAt(i);
      list.insert(
        i,
        (item as ShoppinglistItem).copyWith(description: description),
      );
      TempStorage.getInstance().writeItems(list);

      return true;
    }

    return false;
  }

  @override
  Future<bool> runOnline() async {
    if (item is ShoppinglistItem) {
      return ApiService.getInstance()
          .updateShoppingListItemDescription(item, description);
    }

    return false;
  }
}

class TransactionShoppingListAddRecipeItems extends Transaction<bool> {
  final List<RecipeItem> items;

  TransactionShoppingListAddRecipeItems({
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
      items: items,
      timestamp: timestamp,
    );
  }

  @override
  bool get saveTransaction => true;

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "items": items.map((e) => e.toJsonWithId()).toList(),
    });

  @override
  Future<bool> runLocal() async {
    final list = await TempStorage.getInstance().readItems() ?? [];
    for (final item in items) {
      final int i = list.indexWhere((e) => e.id == item.id);
      if (i >= 0) {
        list.removeAt(i);
        list.insert(i, item.toShoppingListItem());
      } else {
        list.add(item.toShoppingListItem());
      }
    }
    TempStorage.getInstance().writeItems(list);

    return true;
  }

  @override
  Future<bool> runOnline() {
    return ApiService.getInstance().addRecipeItems(items);
  }
}
