import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/storage/temp_storage.dart';
import 'package:kitchenowl/services/transaction.dart';

class TransactionUserGetAll extends Transaction<List<User>> {
  TransactionUserGetAll({DateTime? timestamp})
      : super.internal(timestamp ?? DateTime.now(), "TransactionUserGetAll");

  @override
  Future<List<User>> runLocal() async {
    return (await TempStorage.getInstance().readUsers()) ?? const [];
  }

  @override
  Future<List<User>?> runOnline() async {
    final users = await ApiService.getInstance().getAllUsers();
    if (users != null) TempStorage.getInstance().writeUsers(users);

    return users;
  }
}
