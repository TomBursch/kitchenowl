import 'dart:convert';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/models/report.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension ReportApi on ApiService {
  static const baseRoute = '/report';

  Future<bool?> addReport({
    String? description,
    Recipe? recipe,
    User? user,
  }) async {
    final res = await post(
        baseRoute,
        jsonEncode({
          if (description != null) 'description': description,
          if (recipe != null) 'recipe_id': recipe.id,
          if (user != null) 'user_id': user.id,
        }));

    return res.statusCode != 200;
  }

  Future<bool?> deleteReport(int id) async {
    final res = await delete(baseRoute + "/$id");

    return res.statusCode != 200;
  }

  Future<List<Report>?> getReports() async {
    final res = await get(baseRoute, timeout: const Duration(seconds: 15));

    if (res.statusCode != 200) return null;

    final body = jsonDecode(res.body);
    return (body as List<dynamic>).map((e) => Report.fromJson(e)).toList();
  }
}
