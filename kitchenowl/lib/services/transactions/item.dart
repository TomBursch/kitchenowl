import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/storage/mem_storage.dart';
import 'package:kitchenowl/services/transaction.dart';

class TransactionItemGet extends Transaction<Item> {
  final Item item;

  TransactionItemGet({required this.item, DateTime? timestamp})
      : super.internal(timestamp ?? DateTime.now(), "TransactionItemGet");

  @override
  Future<Item> runLocal() async {
    return item;
  }

  @override
  Future<Item?> runOnline() async {
    return await ApiService.getInstance().getItem(item);
  }
}

class TransactionItemUpdate extends Transaction<bool> {
  final Item item;

  TransactionItemUpdate({required this.item, DateTime? timestamp})
      : super.internal(timestamp ?? DateTime.now(), "TransactionItemUpdate");

  @override
  Future<bool> runLocal() async {
    return false;
  }

  @override
  Future<bool?> runOnline() async {
    return await ApiService.getInstance().updateItem(item);
  }
}

class TransactionItemGetRecipes extends Transaction<List<Recipe>> {
  final Household? household;
  final Item item;

  TransactionItemGetRecipes({
    required this.household,
    required this.item,
    DateTime? timestamp,
  }) : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionItemGetRecipes",
        );

  @override
  Future<List<Recipe>> runLocal() async {
    if (household == null) return [];
    final recipes =
        (await MemStorage.getInstance().readRecipes(household!)) ?? [];
    recipes.retainWhere((e) {
      e.items.retainWhere((e) => e.id == item.id);

      return e.items.isNotEmpty;
    });

    return recipes;
  }

  @override
  Future<List<Recipe>?> runOnline() async {
    return await ApiService.getInstance().getItemRecipes(item);
  }
}
