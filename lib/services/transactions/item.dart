import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/storage/temp_storage.dart';
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
  Future<Item> runOnline() async {
    return await ApiService.getInstance().getItem(item) ?? item;
  }
}

class TransactionItemGetRecipes extends Transaction<List<Recipe>> {
  final Item item;

  TransactionItemGetRecipes({required this.item, DateTime? timestamp})
      : super.internal(
            timestamp ?? DateTime.now(), "TransactionItemGetRecipes");

  @override
  Future<List<Recipe>> runLocal() async {
    final recipes = (await TempStorage.getInstance().readRecipes()) ?? [];
    recipes.retainWhere((e) => e.items.map((e) => e.id).contains(item.id));
    return recipes;
  }

  @override
  Future<List<Recipe>> runOnline() async {
    return await ApiService.getInstance().getItemRecipes(item) ?? const [];
  }
}
