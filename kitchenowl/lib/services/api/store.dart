import 'dart:convert';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/store.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension StoreApi on ApiService {
  static const baseRoute = '/store';

  Future<Set<Store>?> getAllStores(Household household) async {
    final res = await get(householdPath(household) + baseRoute);
    if (res.statusCode != 200) return null;

    final body = List.from(jsonDecode(res.body));

    return body.map((e) => Store.fromJson(e)).toSet();
  }

  Future<bool> addStore(Household household, Store store) async {
    final res = await post(
      householdPath(household) + baseRoute,
      json.encode(store.toJson()),
    );

    return res.statusCode == 200;
  }

  Future<bool> updateStore(Store store) async {
    final res =
        await post('$baseRoute/${store.id}', json.encode(store.toJson()));

    return res.statusCode == 200;
  }

  Future<bool> mergeStore(Store store, Store other) async {
    final res = await post(
      '$baseRoute/${store.id}',
      jsonEncode({
        "merge_store_id": other.id,
      }),
    );

    return res.statusCode == 200;
  }

  Future<Store?> getStore(Store store) async {
    final res = await get('$baseRoute/${store.id}');
    if (res.statusCode != 200) return null;

    final body = jsonDecode(res.body);

    return Store.fromJson(body);
  }

  Future<bool> deleteStore(Store store) async {
    final res = await delete('$baseRoute/${store.id}');

    return res.statusCode == 200;
  }
}
