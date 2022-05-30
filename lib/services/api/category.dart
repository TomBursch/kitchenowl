import 'dart:convert';

import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension CategoryApi on ApiService {
  static const baseRoute = '/category';

  Future<List<Category>?> getCategories() async {
    final res = await get(baseRoute);
    if (res.statusCode != 200) return null;

    return List<Category>.from(jsonDecode(res.body).map(
      (e) => Category.fromJson(e),
    ));
  }

  Future<bool> addCategory(Category category) async {
    final res = await post(
      baseRoute,
      jsonEncode({'name': category.name}),
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
