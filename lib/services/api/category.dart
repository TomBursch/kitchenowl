import 'dart:convert';

import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension CategoryApi on ApiService {
  static const baseRoute = '/category';

  Future<List<Category>?> getCategories(Household household) async {
    final res = await get(householdPath(household) + baseRoute);
    if (res.statusCode != 200) return null;

    return List<Category>.from(jsonDecode(res.body).map(
      (e) => Category.fromJson(e),
    ));
  }

  Future<bool> addCategory(Household household, Category category) async {
    final res = await post(
      householdPath(household) + baseRoute,
      jsonEncode(category.toJson()),
    );

    return res.statusCode == 200;
  }

  Future<bool> updateCategory(Category category) async {
    final res = await post(
      '$baseRoute/${category.id}',
      jsonEncode(category.toJson()),
    );

    return res.statusCode == 200;
  }

  Future<bool> mergeCategories(Category category, Category other) async {
    final res = await post(
      '$baseRoute/${category.id}',
      jsonEncode({
        "merge_category_id": other.id,
      }),
    );

    return res.statusCode == 200;
  }

  Future<bool> deleteCategory(Category category) async {
    final res = await delete(
      baseRoute,
      body: jsonEncode({'name': category.name}),
    );

    return res.statusCode == 200;
  }
}
