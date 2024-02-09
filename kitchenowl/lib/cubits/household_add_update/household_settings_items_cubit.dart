import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/enums/shoppinglist_sorting.dart';
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
      ShoppinglistSorting.sortShoppinglistItems(state.items, state.sorting);
      emit(HouseholdSettingsItemsState(
        items: (await items)!,
        categories: await categories,
      ));
    }
  }

  void incrementSorting() {
    setSorting(ShoppinglistSorting
        .values[(state.sorting.index + 1) % ShoppinglistSorting.values.length]);
  }

  void setSorting(ShoppinglistSorting sorting) {
    if (state is! LoadingHouseholdSettingsItemsState &&
        state.items != const []) {
      ShoppinglistSorting.sortShoppinglistItems(state.items, sorting);
    }
    emit(state.copyWith(sorting: sorting));
  }
}

class HouseholdSettingsItemsState extends Equatable {
  final List<Item> items;
  final List<Category> categories;
  final ShoppinglistSorting sorting;

  const HouseholdSettingsItemsState({
    this.items = const [],
    this.categories = const [],
    this.sorting = ShoppinglistSorting.alphabetical,
  });

  HouseholdSettingsItemsState copyWith({
    ShoppinglistSorting? sorting,
  }) =>
      HouseholdSettingsItemsState(
        items: this.items,
        categories: this.categories,
        sorting: sorting ?? this.sorting,
      );

  @override
  List<Object?> get props => [items, categories, sorting];
}

class LoadingHouseholdSettingsItemsState extends HouseholdSettingsItemsState {
  const LoadingHouseholdSettingsItemsState({super.sorting});

  @override
  HouseholdSettingsItemsState copyWith({
    ShoppinglistSorting? sorting,
  }) =>
      LoadingHouseholdSettingsItemsState(
        sorting: sorting ?? this.sorting,
      );
}
