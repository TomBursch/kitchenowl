import 'dart:convert';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/server_settings.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/storage/storage.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/household.dart';

class HouseholdCubit extends Cubit<HouseholdState> {
  HouseholdCubit(Household household)
      : super(HouseholdState(
          household: household,
        )) {
    // ApiService.getInstance().addSettingsListener(serverSettingsUpdated);
    refresh();
  }

  Future<void> serverSettingsUpdated() async {
    await PreferenceStorage.getInstance().write(
      key: 'serverSettings',
      value: jsonEncode(ApiService.getInstance().serverSettings.toJson()),
    );
    emit(state.copyWith(
        // household: ApiService.getInstance().serverSettings,
        ));
  }

  Future<void> load() async {
    ServerSettings serverSettings = ServerSettings.fromJson(jsonDecode(
      (await PreferenceStorage.getInstance().read(key: 'serverSettings')) ??
          "{}",
    ));

    if (ApiService.getInstance().serverSettings != null) {
      serverSettings = ApiService.getInstance().serverSettings;
    }

    // emit(HouseholdState());
  }

  Future<void> refresh() async {
    emit(state.copyWith(
      household: await TransactionHandler.getInstance()
          .runTransaction(TransactionHouseholdGet(
        household: state.household,
      )),
    ));
  }

  // void setView(ViewsEnum view, bool value) {
  //   if (state.household == null) return;
  //   if (view == ViewsEnum.mealPlanner) {
  //     final settings = state.household.copyWith(featurePlanner: value);
  //     emit(state.copyWith(serverSettings: settings));
  //     PreferenceStorage.getInstance()
  //         .write(key: 'serverSettings', value: jsonEncode(settings.toJson()));
  //     ApiService.getInstance()
  //         .setSettings(ServerSettings(featurePlanner: value));
  //   }
  //   if (view == ViewsEnum.balances) {
  //     final settings = state.serverSettings.copyWith(featureExpenses: value);
  //     emit(state.copyWith(serverSettings: settings));
  //     PreferenceStorage.getInstance()
  //         .write(key: 'serverSettings', value: jsonEncode(settings.toJson()));
  //     ApiService.getInstance()
  //         .setSettings(ServerSettings(featureExpenses: value));
  //   }
  // }

  // void reorderView(int oldIndex, int newIndex) {
  //   final l = List.of(state.serverSettings.viewOrdering!);
  //   l.insert(newIndex, l.removeAt(oldIndex));
  //   final settings = state.serverSettings.copyWith(viewOrdering: l);
  //   emit(state.copyWith(serverSettings: settings));
  //   PreferenceStorage.getInstance()
  //       .write(key: 'serverSettings', value: jsonEncode(settings.toJson()));
  //   ApiService.getInstance().setSettings(ServerSettings(viewOrdering: l));
  // }

  // void resetViewOrder() {
  //   final settings =
  //       state.serverSettings.copyWith(viewOrdering: ViewsEnum.values);
  //   emit(state.copyWith(serverSettings: settings));
  //   PreferenceStorage.getInstance().write(
  //     key: 'serverSettings',
  //     value: jsonEncode(
  //       settings.copyWith(viewOrdering: const []).toJson(),
  //     ),
  //   );
  //   ApiService.getInstance().setSettings(const ServerSettings(
  //     viewOrdering: [],
  //   ));
  // }
}

class HouseholdState extends Equatable {
  final Household household;

  const HouseholdState({
    required this.household,
  });

  HouseholdState copyWith({
    Household? household,
  }) =>
      HouseholdState(
        household: household ?? this.household,
      );

  @override
  List<Object?> get props => [household];
}
