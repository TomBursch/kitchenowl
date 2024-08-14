import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/services/transaction.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/storage/transaction_storage.dart';

class TransactionHandler {
  static TransactionHandler? _instance;

  TransactionHandler.internal();

  static TransactionHandler getInstance() {
    _instance ??= TransactionHandler.internal();

    return _instance!;
  }

  Future<void> runOpenTransactions() async {
    if (ApiService.getInstance().isConnected()) {
      List<Transaction> transactions =
          await TransactionStorage.getInstance().readTransactions();

      final now = DateTime.now();
      List<Transaction> openTransactions = [];
      for (final t in transactions) {
        if (t is! ErrorTransaction && t.timestamp.difference(now).inDays < 3) {
          dynamic res = await t.runOnline();
          if (res == null || (res is bool && !res)) {
            openTransactions.add(t);
          }
        }
      }
      TransactionStorage.getInstance().setTransaction(openTransactions);
    }
  }

  Future<T> runTransaction<T>(
    Transaction<T> t, {
    bool forceOffline = false,
    bool saveTransaction = true,
  }) async {
    forceOffline = forceOffline || App.isForcedOffline;
    if (!ApiService.getInstance().isConnected()) {
      await ApiService.getInstance().refresh();
    }
    if (!forceOffline && ApiService.getInstance().isConnected()) {
      T? res = await t.runOnline();
      if (res != null && (res is! bool || res)) return res;
    }
    if (t.saveTransaction && saveTransaction) {
      await TransactionStorage.getInstance().addTransaction(t);
    }

    return t.runLocal();
  }
}
