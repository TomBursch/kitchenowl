import 'package:kitchenowl/models/transaction.dart';
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
        if (t.timestamp.difference(now).inDays < 3) t.runOnline();
      }
      TransactionStorage.getInstance().clearTransactions();
    }
  }

  Future<void> runTransaction(Transaction t) async {
    if (ApiService.getInstance().isConnected())
      return t.runOnline();
    else {
      await TransactionStorage.getInstance().addTransaction(t);
      return t.runLocal();
    }
  }
}
