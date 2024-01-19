import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/storage/mem_storage.dart';
import 'package:kitchenowl/services/transaction.dart';

class TransactionCategoriesGet extends Transaction<List<Category>> {
  final Household household;

  TransactionCategoriesGet({required this.household, DateTime? timestamp})
      : super.internal(timestamp ?? DateTime.now(), "TransactionCategoriesGet");

  @override
  Future<List<Category>> runLocal() async {
    return await MemStorage.getInstance().readCategories(household) ?? const [];
  }

  @override
  Future<List<Category>?> runOnline() async {
    final categories = await ApiService.getInstance().getCategories(household);
    if (categories != null) {
      MemStorage.getInstance().writeCategories(household, categories);
    }

    return categories;
  }
}
