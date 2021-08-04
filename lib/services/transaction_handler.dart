import 'package:kitchenowl/app.dart';
import 'package:kitchenowl/services/transaction.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/storage/transaction_storage.dart';

class TransactionHandler {
  static TransactionHandler _instance;

  TransactionHandler._internal();
  static TransactionHandler getInstance() {
    if (_instance == null) _instance = TransactionHandler._internal();
    return _instance;
  }

  Future<void> runOpenTransactions() async {
    final transactions =
        await TransactionStorage.getInstance().readTransactions();
    if (ApiService.getInstance().isConnected()) {
      final now = DateTime.now();
      for (final t in transactions) {
        if (t != null && t.timestamp.difference(now).inDays < 3) t.runOnline();
      }
      TransactionStorage.getInstance().clearTransactions();
    }
  }

  Future<T> runTransaction<T>(Transaction<T> t) async {
    if (!ApiService.getInstance().isConnected())
      ApiService.getInstance().refresh();
    if (!App.isForcedOffline && ApiService.getInstance().isConnected()) {
      Future<T> res = t.runOnline();
      if (await res != null) return res;
    }
    if (t.saveTransaction)
      await TransactionStorage.getInstance().addTransaction(t);
    return t.runLocal();
  }
}
