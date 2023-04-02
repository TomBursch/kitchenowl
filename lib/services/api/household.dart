import 'dart:convert';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension HouseholdApi on ApiService {
  static const baseRoute = '/household';

  Future<List<Household>?> getAllHouseholds() async {
    final res = await get(baseRoute);
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => Household.fromJson(e)).toList();
  }

  Future<Household?> getHousehold(Household household) async {
    final res = await get("$baseRoute/${household.id}");
    if (res.statusCode != 200) return null;

    return Household.fromJson(jsonDecode(res.body));
  }

  Future<bool> updateHousehold(Household household) async {
    final res = await post(
      '$baseRoute/${household.id}',
      jsonEncode(household.toJson()),
    );

    return res.statusCode == 200;
  }

  Future<bool> addHousehold(Household household) async {
    final res = await post(
      baseRoute,
      jsonEncode(household.toJson()),
    );

    return res.statusCode == 200;
  }
}
