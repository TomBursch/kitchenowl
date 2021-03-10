import 'package:kitchenowl/enums/transaction_enum.dart';
import 'package:kitchenowl/models/model.dart';
import 'package:kitchenowl/models/transactions/shoppinglist.dart';

export 'package:kitchenowl/models/transactions/shoppinglist.dart';

abstract class Transaction extends Model {
  static final Map<TransactionEnum,
          Transaction Function(Map<String, dynamic>, DateTime)>
      _transactionTypes = {
    TransactionEnum.itemAdd: (m, t) =>
        TransactionShoppingListAddItem.fromJson(m, t),
    TransactionEnum.itemDelete: (m, t) =>
        TransactionShoppingListDeleteItem.fromJson(m, t),
  };

  final TransactionEnum type;
  final DateTime timestamp;

  Future<bool> runLocal();
  Future<bool> runOnline();

  const Transaction.internal(this.timestamp, this.type);

  factory Transaction.fromJson(Map<String, dynamic> map) {
    final TransactionEnum type = TransactionEnum.values[map['type']];
    final DateTime timestamp =
        DateTime.tryParse(map['timestamp']) ?? DateTime.now();
    return _transactionTypes[type](map, timestamp);
  }

  @override
  List<Object> get props => [this.type, this.timestamp];

  @override
  Map<String, dynamic> toJson() => {
        "type": this.type.index,
        "timestamp": this.timestamp.toIso8601String(),
      };
}
