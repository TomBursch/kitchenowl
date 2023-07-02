import 'dart:convert';

import 'package:kitchenowl/services/api/api_service.dart';

extension AnalyticsApi on ApiService {
  static const baseRoute = '/analytics';

  Future<Map<String, dynamic>?> getAnalyticsOverview() async {
    final res = await get(baseRoute);
    if (res.statusCode != 200) return null;

    return jsonDecode(res.body);
  }
}
