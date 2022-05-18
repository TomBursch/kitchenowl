import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/transaction.dart';

class TransactionCategoriesGet extends Transaction<List<Category>> {
  TransactionCategoriesGet({DateTime? timestamp})
      : super.internal(timestamp ?? DateTime.now(), "TransactionCategoriesGet");

  @override
  Future<List<Category>> runLocal() async {
    return [];
  }

  @override
  Future<List<Category>> runOnline() async {
    return await ApiService.getInstance().getCategories() ?? [];
  }
}
