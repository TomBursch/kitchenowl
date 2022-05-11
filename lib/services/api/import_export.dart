import 'dart:convert';

import 'package:kitchenowl/services/api/api_service.dart';

extension ImportExportApi on ApiService {
  static const baseRoute = '/import';

  Future<void> importLanguage(String code) async {
    await get('$baseRoute/$code');
  }

  Future<Map<String, String>?> getSupportedLanguages() async {
    final res = await get('$baseRoute/supported-languages');
    if (res.statusCode != 200) return null;

    return Map<String, String>.from((jsonDecode(res.body)));
  }
}
