import 'package:kitchenowl/enums/transaction_enum.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/models/transaction.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/storage/temp_storage.dart';

class TransactionShoppingListAddItem extends Transaction {
  final String name;

  TransactionShoppingListAddItem({this.name, DateTime timestamp})
      : super.internal(timestamp ?? DateTime.now(), TransactionEnum.itemAdd);

  factory TransactionShoppingListAddItem.fromJson(
          Map<String, dynamic> map, DateTime timestamp) =>
      TransactionShoppingListAddItem(
        name: map['name'],
        timestamp: timestamp,
      );

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "name": this.name,
    });

  @override
  Future<bool> runLocal() async {
    final list = await TempStorage.getInstance().readItems();
    list.add(ShoppinglistItem(name: this.name));
    await TempStorage.getInstance().writeItems(list);
    return true;
  }

  @override
  Future<bool> runOnline() {
    return ApiService.getInstance().addItemByName(this.name);
  }
}

class TransactionShoppingListDeleteItem extends Transaction {
  final ShoppinglistItem item;

  TransactionShoppingListDeleteItem({DateTime timestamp, this.item})
      : super.internal(timestamp ?? DateTime.now(), TransactionEnum.itemDelete);

  factory TransactionShoppingListDeleteItem.fromJson(
          Map<String, dynamic> map, DateTime timestamp) =>
      TransactionShoppingListDeleteItem(
        item: ShoppinglistItem.fromJson(map['item']),
        timestamp: timestamp,
      );

  @override
  Map<String, dynamic> toJson() => super.toJson()
    ..addAll({
      "item": this.item.toJsonWithId(),
    });

  @override
  Future<bool> runLocal() async {
    final list = await TempStorage.getInstance().readItems();
    list.removeWhere((e) => e.name == this.item.name);
    await TempStorage.getInstance().writeItems(list);
    return true;
  }

  @override
  Future<bool> runOnline() {
    return ApiService.getInstance().removeItem(this.item);
  }
}
