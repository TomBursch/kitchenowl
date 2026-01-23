import 'dart:convert';

import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/loyalty_card.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension LoyaltyCardApi on ApiService {
  static const baseRoute = '/loyalty-card';

  Future<List<LoyaltyCard>?> getAllLoyaltyCards({
    required Household household,
  }) async {
    final res = await get('${householdPath(household)}$baseRoute');
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => LoyaltyCard.fromJson(e)).toList();
  }

  Future<LoyaltyCard?> getLoyaltyCard(LoyaltyCard loyaltyCard) async {
    final res = await get('$baseRoute/${loyaltyCard.id}');
    if (res.statusCode != 200) return null;

    return LoyaltyCard.fromJson(jsonDecode(res.body));
  }

  Future<LoyaltyCard?> addLoyaltyCard(
    Household household,
    LoyaltyCard loyaltyCard,
  ) async {
    final body = loyaltyCard.toJson();
    final res = await post(
      "${householdPath(household)}$baseRoute",
      jsonEncode(body),
    );

    if (res.statusCode != 200) return null;

    return LoyaltyCard.fromJson(jsonDecode(res.body));
  }

  Future<bool> deleteLoyaltyCard(LoyaltyCard loyaltyCard) async {
    final res = await delete('$baseRoute/${loyaltyCard.id}');

    return res.statusCode == 200;
  }

  Future<bool> updateLoyaltyCard(LoyaltyCard loyaltyCard) async {
    final body = loyaltyCard.toJson();
    final res = await post('$baseRoute/${loyaltyCard.id}', jsonEncode(body));

    return res.statusCode == 200;
  }
}

