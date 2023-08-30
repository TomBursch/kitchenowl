import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/storage/temp_storage.dart';
import 'package:kitchenowl/services/transaction.dart';

class TransactionTagGetAll extends Transaction<Set<Tag>> {
  final Household household;

  TransactionTagGetAll({DateTime? timestamp, required this.household})
      : super.internal(timestamp ?? DateTime.now(), "TransactionTagGetAll");

  @override
  Future<Set<Tag>> runLocal() async {
    return await TempStorage.getInstance().readTags(household) ?? {};
  }

  @override
  Future<Set<Tag>?> runOnline() async {
    final tags = await ApiService.getInstance().getAllTags(household);
    if (tags != null) {
      TempStorage.getInstance().writeTags(household, tags);
    }

    return tags;
  }
}
