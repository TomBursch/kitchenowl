import 'package:flutter/foundation.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/transaction.dart';

class TransactionTagGetAll extends Transaction<List<Tag>> {
  TransactionTagGetAll({DateTime timestamp})
      : super.internal(timestamp ?? DateTime.now(), "TransactionTagGetAll");

  @override
  Future<List<Tag>> runLocal() async {
    return const [];
  }

  @override
  Future<List<Tag>> runOnline() async {
    return ApiService.getInstance().getAllTags();
  }
}
