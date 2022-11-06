import 'package:kitchenowl/models/model.dart';
import 'package:kitchenowl/services/transactions/planner.dart';
import 'package:kitchenowl/services/transactions/shoppinglist.dart';

abstract class Transaction<T> extends Model {
  static final Map<String, Transaction Function(Map<String, dynamic>, DateTime)>
      _transactionTypes = {
    "TransactionShoppingListAddItem": (m, t) =>
        TransactionShoppingListAddItem.fromJson(m, t),
    "TransactionShoppingListDeleteItem": (m, t) =>
        TransactionShoppingListDeleteItem.fromJson(m, t),
    "TransactionShoppingListUpdateItem": (m, t) =>
        TransactionShoppingListUpdateItem.fromJson(m, t),
    "TransactionShoppingListAddRecipeItems": (m, t) =>
        TransactionShoppingListAddRecipeItems.fromJson(m, t),
    "TransactionPlannerAddRecipe": (m, t) =>
        TransactionPlannerAddRecipe.fromJson(m, t),
    "TransactionPlannerRemoveRecipe": (m, t) =>
        TransactionPlannerRemoveRecipe.fromJson(m, t),
  };

  bool get saveTransaction => false;

  final String className;
  final DateTime timestamp;

  Future<T> runLocal();
  Future<T?> runOnline();

  const Transaction.internal(this.timestamp, this.className);

  factory Transaction.fromJson(Map<String, dynamic> map) {
    final DateTime timestamp =
        DateTime.tryParse(map['timestamp']) ?? DateTime.now();
    if (map.containsKey('className') &&
        _transactionTypes.containsKey(map['className'])) {
      return _transactionTypes[map['className']]!(map, timestamp)
          as Transaction<T>;
    }

    return ErrorTransaction<T>(
      timestamp,
      map.containsKey('className') ? map['className'] : "ERROR",
    );
  }

  @override
  List<Object> get props => [className, timestamp];

  @override
  Map<String, dynamic> toJson() => {
        "className": className,
        "timestamp": timestamp.toIso8601String(),
      };
}

class ErrorTransaction<T> extends Transaction<T> {
  const ErrorTransaction(DateTime timestamp, String className)
      : super.internal(timestamp, className);

  @override
  Future<T> runLocal() {
    throw UnimplementedError();
  }

  @override
  Future<T> runOnline() {
    throw UnimplementedError();
  }
}
