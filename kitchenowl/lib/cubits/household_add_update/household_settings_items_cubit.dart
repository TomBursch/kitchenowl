import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/category.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/item.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/category.dart';

class HouseholdSettingsItemsCubit extends Cubit<HouseholdSettingsItemsState> {
  final Household household;

  HouseholdSettingsItemsCubit(this.household)
      : super(const LoadingHouseholdSettingsItemsState()) {
    refresh();
  }

  Future<void> refresh() async {
    final items = ApiService.getInstance().getAllItems(household);
    final categories = TransactionHandler.getInstance().runTransaction(
      TransactionCategoriesGet(household: household),
    );
    if (await items != null) {
      emit(HouseholdSettingsItemsState(
        items: (await items)!,
        categories: await categories,
      ));
    }
  }
}

class HouseholdSettingsItemsState extends Equatable {
  final List<Item> items;
  final List<Category> categories;

  const HouseholdSettingsItemsState({
    this.items = const [],
    this.categories = const [],
  });

  @override
  List<Object?> get props => [items, categories];
}

class LoadingHouseholdSettingsItemsState extends HouseholdSettingsItemsState {
  const LoadingHouseholdSettingsItemsState();
}
