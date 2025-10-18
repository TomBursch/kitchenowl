import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/services/storage/storage.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/shoppinglist.dart';

class BackgroundTask {
  static Future<void> run(AuthCubit authCubit) async {
    if (authCubit.getUser() != null) {
      await Future.wait([
        TransactionHandler.getInstance().runOpenTransactions(),
        PreferenceStorage.getInstance()
            .readInt(key: 'lastHouseholdId')
            .then((id) async {
          if (id != null)
            await TransactionHandler.getInstance().runTransaction(
                TransactionShoppingListGet(household: Household(id: id)));
        }),
      ]);
    }
  }
}
