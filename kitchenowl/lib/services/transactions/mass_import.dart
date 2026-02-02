import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/shoppinglist.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/storage/mem_storage.dart';
import 'package:kitchenowl/services/transaction.dart';

class TransactionShoppingListAddItems extends Transaction<bool> {
  final Household household;
  final ShoppingList shoppinglist;
  final List<ShoppinglistItem> items;

  TransactionShoppingListAddItems({
    required this.household,
    required this.shoppinglist,
    required this.items,
    DateTime? timestamp,
  }) : super.internal(
    timestamp ?? DateTime.now(),
    "TransactionShoppingListAddItems",
  );

  factory TransactionShoppingListAddItems.fromJson(
      Map<String, dynamic> map,
      DateTime timestamp,
      ) {
    final List<ShoppinglistItem> items =
    List.from(map['items'].map((e) => ShoppinglistItem.fromJson(e)));

    return TransactionShoppingListAddItems(
      household: Household.fromJson(map['household']),
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
      "household": household.toJsonWithId(),
      "shoppinglist": shoppinglist.toJsonWithId(),
      "items": items.map((e) => e.toJsonWithId()).toList(),
    });

  @override
  Future<bool> runLocal() async {
    final shoppingLists =
        await MemStorage.getInstance().readShoppingLists(household) ?? [];
    final latestShoppingList =
        shoppingLists.where((e) => e.id == shoppinglist.id).firstOrNull;
    if (latestShoppingList == null) return false;

    for (final item in items) {
      final int i =
      latestShoppingList.items.indexWhere((e) => e.name == item.name);

      if (i >= 0) {
        // If it exists, update it (e.g. append description if needed, or just keep existing)
        // For mass import, usually we just append or overwrite.
        // Here we just update the description if the new one has one.
        if (item.description.isNotEmpty) {
          latestShoppingList.items[i] = latestShoppingList.items[i].copyWith(
            description: item.description,
          );
        }
      } else {
        latestShoppingList.items.add(item);
        // Remove from recent items if it was there to avoid duplicates in suggestions
        latestShoppingList.recentItems.removeWhere((e) => e.name == item.name);
      }
    }
    MemStorage.getInstance().writeShoppingLists(household, shoppingLists);

    return true;
  }

  @override
  Future<bool?> runOnline() async {
    // We iterate because the API might not support batch adding generic items yet.
    for (final item in items) {
      await ApiService.getInstance().addItemByName(
        shoppinglist,
        item.name,
        item.description,
      );
    }
    return true;
  }
}
