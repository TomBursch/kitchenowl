import 'package:kitchenowl/models/store.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/storage/mem_storage.dart';
import 'package:kitchenowl/services/transaction.dart';

class TransactionStoresGet extends Transaction<List<Store>> {
  final Household household;

  TransactionStoresGet({required this.household, DateTime? timestamp})
      : super.internal(timestamp ?? DateTime.now(), "TransactionStoresGet");

  @override
  Future<List<Store>> runLocal() async {
    return await MemStorage.getInstance().readStores(household) ?? const [];
  }

  @override
  Future<List<Store>?> runOnline() async {
    final stores = await ApiService.getInstance().getAllStores(household);
    if (stores != null) {
      MemStorage.getInstance().writeStores(household, stores.toList());
    }

    return stores?.toList();
  }
}
