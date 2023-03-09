import 'dart:convert';

import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension ImportExportApi on ApiService {
  static const baseRoute = '/import';

  Future<void> importLanguage(Household household, String code) async {
    await get('${householdPath(household)}$baseRoute/$code');
  }

  Future<Map<String, String>?> getSupportedLanguages() async {
    final res = await get('$baseRoute/supported-languages');
    if (res.statusCode != 200) return null;

    return Map<String, String>.from((jsonDecode(res.body)));
  }
}
