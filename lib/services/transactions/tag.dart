import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/tag.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/transaction.dart';

class TransactionTagGetAll extends Transaction<Set<Tag>> {
  final Household household;

  TransactionTagGetAll({DateTime? timestamp, required this.household})
      : super.internal(timestamp ?? DateTime.now(), "TransactionTagGetAll");

  @override
  Future<Set<Tag>> runLocal() async {
    return const {};
  }

  @override
  Future<Set<Tag>?> runOnline() async {
    return await ApiService.getInstance().getAllTags(household);
  }
}
