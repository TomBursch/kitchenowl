import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/storage/temp_storage.dart';
import 'package:kitchenowl/services/transaction.dart';

class TransactionHouseholdGetAll extends Transaction<List<Household>> {
  TransactionHouseholdGetAll({DateTime? timestamp})
      : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionHouseholdGetAll",
        );

  @override
  Future<List<Household>> runLocal() async {
    // return (await TempStorage.getInstance().readUsers()) ?? const [];
    return const [];
  }

  @override
  Future<List<Household>?> runOnline() async {
    final households = await ApiService.getInstance().getAllHouseholds();
    // if (users != null) TempStorage.getInstance().writeUsers(users);

    return households;
  }
}

class TransactionHouseholdGet extends Transaction<Household> {
  final Household household;

  TransactionHouseholdGet({required this.household, DateTime? timestamp})
      : super.internal(
          timestamp ?? DateTime.now(),
          "TransactionHouseholdGet",
        );

  @override
  Future<Household> runLocal() async {
    // return (await TempStorage.getInstance().readUsers()) ?? const [];
    return household;
  }

  @override
  Future<Household?> runOnline() async {
    final households = await ApiService.getInstance().getHousehold(household);
    // if (users != null) TempStorage.getInstance().writeUsers(users);

    return households;
  }
}
