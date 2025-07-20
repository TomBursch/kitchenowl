import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/household.dart';

class HouseholdAboutCubit extends Cubit<HouseholdAboutState> {
  static const int pageSize = 10;

  HouseholdAboutCubit(Household household)
      : super(HouseholdAboutState(household: household)) {
    refresh();
  }

  Future<void> loadMore() async {
    if (state.allLoaded) return;

    final newRecipes = ApiService.getInstance().getNewestRecipesOfHousehold(
      state.household,
      state.loadedPages,
    );

    emit(HouseholdAboutState(
      household: state.household,
      recipes: List.from(state.recipes + (await newRecipes ?? [])),
      allLoaded: (await newRecipes ?? []).length < pageSize,
      loadedPages: state.loadedPages + 1,
    ));
  }

  Future<void> refresh() async {
    final household = await TransactionHandler.getInstance()
        .runTransaction(TransactionHouseholdGet(household: state.household));

    emit(HouseholdAboutState(
      household: household ?? state.household,
    ));

    loadMore();
  }
}

class HouseholdAboutState extends Equatable {
  final Household household;
  final List<Recipe> recipes;
  final int loadedPages;
  final bool allLoaded;

  const HouseholdAboutState({
    required this.household,
    this.recipes = const [],
    this.allLoaded = false,
    this.loadedPages = 0,
  });

  @override
  List<Object?> get props => [household, recipes, loadedPages, allLoaded];
}
