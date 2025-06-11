import 'package:collection/collection.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/storage/mem_storage.dart';
import 'package:kitchenowl/services/transaction.dart';

class TransactionHouseholdGetAll extends Transaction<List<Household>> {
  TransactionHouseholdGetAll({DateTime? timestamp})
      : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionHouseholdGetAll",
        );

  @override
  Future<List<Household>> runLocal() async {
    return (await MemStorage.getInstance().readHouseholds()) ?? const [];
  }

  @override
  Future<List<Household>?> runOnline() async {
    final households = await ApiService.getInstance().getAllHouseholds();
    if (households != null) {
      MemStorage.getInstance().writeHouseholds(households);
    }

    return households;
  }
}

class TransactionHouseholdGet extends Transaction<Household?> {
  final Household household;

  TransactionHouseholdGet({required this.household, DateTime? timestamp})
      : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionHouseholdGet",
        );

  @override
  Future<Household?> runLocal() async {
    return (await MemStorage.getInstance().readHouseholds())
        ?.firstWhereOrNull((e) => e.id == household.id);
  }

  @override
  Future<Household?> runOnline() async {
    final res = await ApiService.getInstance().getHousehold(this.household);
    if (res.household != null) {
      final households = await MemStorage.getInstance().readHouseholds() ?? [];
      final i = households.indexWhere((e) => e.id == household.id);
      if (i >= 0) {
        households[i] = res.household!;
      } else {
        households.add(res.household!);
      }
      MemStorage.getInstance().writeHouseholds(households);
    } else if (res.statusCode == 403) {
      final households = await MemStorage.getInstance().readHouseholds() ?? [];
      final i = households.indexWhere((e) => e.id == household.id);
      if (i >= 0) {
        households.removeAt(i);
        MemStorage.getInstance().writeHouseholds(households);
      }
    }

    return res.household;
  }
}
class TransactionShoppingListReorder extends Transaction<bool> {
  final Household household;
  final List<int> orderedIds;

  TransactionShoppingListReorder({
    required this.household,
    required this.orderedIds,
  });

  @override
  Future<bool> run() async {
    return await ApiService.getInstance()
      .updateShoppingListOrder(household.id!, orderedIds);
  }
}

class TransactionShoppingListMakeStandard extends Transaction<bool> {
  final Household household;
  final ShoppingList shoppingList;

  TransactionShoppingListMakeStandard({
    required this.household,
    required this.shoppingList,
  });

  @override
  Future<bool> run() async {
    return (await ApiService.getInstance()
      .makeStandardList(shoppingList.id!)) != null;
  }
}
