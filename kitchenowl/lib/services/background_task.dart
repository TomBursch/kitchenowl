import 'package:kitchenowl/config.dart';
import 'package:kitchenowl/cubits/auth_cubit.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/storage/mem_storage.dart';
import 'package:kitchenowl/services/storage/storage.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/shoppinglist.dart';
import 'package:package_info_plus/package_info_plus.dart';

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

  static Future<void> runHeadless() async {
    final preferenceStorage = PreferenceStorage.getInstance();
    final forcedOfflineMode =
        await preferenceStorage.readBool(key: 'forcedOfflineMode') ?? false;
    if (forcedOfflineMode) return;

    Config.packageInfo = PackageInfo.fromPlatform();
    final url =
        await preferenceStorage.read(key: 'URL') ?? Config.defaultServer;
    final secureStorage = SecureStorage.getInstance();
    final token = await secureStorage.read(key: 'TOKEN');

    ApiService.setTokenRotationHandler(
      (token) => secureStorage.write(key: 'TOKEN', value: token),
    );
    ApiService.setTokenBeforeReauthHandler((token) {
      if (token == null) return Future.value(token);
      return secureStorage.read(key: 'TOKEN').then((value) => value ?? token);
    });

    await ApiService.connectTo(url, refreshToken: token);
    if (!ApiService.getInstance().isAuthenticated()) return;

    await Future.wait([
      TransactionHandler.getInstance().runOpenTransactions(),
      _refreshShoppingLists(preferenceStorage),
    ]);
  }

  static Future<void> _refreshShoppingLists(
    PreferenceStorage preferenceStorage,
  ) async {
    final householdId = await preferenceStorage.readInt(key: 'lastHouseholdId');
    if (householdId == null) return;

    final recentItemsCount =
        await preferenceStorage.readInt(key: 'recentItemsCount') ?? 9;
    final household = Household(id: householdId);
    final shoppingLists = await ApiService.getInstance().getShoppingLists(
      household,
      recentItemlimit: recentItemsCount + 3,
    );
    if (shoppingLists != null) {
      await MemStorage.getInstance()
          .writeShoppingLists(household, shoppingLists);
    }
  }
}
