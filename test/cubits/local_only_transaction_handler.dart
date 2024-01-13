import 'package:kitchenowl/services/transaction.dart';
import 'package:kitchenowl/services/transaction_handler.dart';

class LocalOnlyTransactionHandler extends TransactionHandler {
  LocalOnlyTransactionHandler() : super.internal();

  @override
  Future<T> runTransaction<T>(Transaction<T> t,
      {bool forceOffline = false, bool saveTransaction = true}) {
    return t.runLocal();
  }
}