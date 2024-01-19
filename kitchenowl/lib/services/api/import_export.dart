import 'dart:convert';

import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension ImportExportApi on ApiService {
  static const baseRoute = '/import';

  Future<void> importLanguage(Household household, String code) async {
    await get('${householdPath(household)}$baseRoute/$code');
  }

  Future<void> importHousehold(
    Household household,
    Map<String, dynamic> content, [
    bool overwriteRecipes = false,
  ]) async {
    content["recipe_overwrite"] = overwriteRecipes;
    await post(
      '${householdPath(household)}$baseRoute',
      jsonEncode(content),
      timeout: const Duration(minutes: 5),
    );
  }

  Future<String?> exportHousehold(Household household) async {
    final res = await get('${householdPath(household)}/export');
    if (res.statusCode != 200) return null;

    return res.body;
  }
}
