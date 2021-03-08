import 'dart:convert';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/services/api/api_service.dart';

extension ItemApi on ApiService {
  Future<List<Item>> searchItem(String query) async {
    final res = await get('/item/search?query=$query');
    if (res.statusCode != 200) return [];

    final body = List.from(jsonDecode(res.body));
    return body.map((e) => Item.fromJson(e)).toList();
  }
}
