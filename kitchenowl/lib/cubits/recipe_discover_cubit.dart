import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/recipe_suggestions.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/household.dart';

class RecipeDiscoverCubit extends Cubit<RecipeDiscoverState> {
  final Household? household;

  RecipeDiscoverCubit(this.household)
      : super(RecipeDiscoverLoadingState(household: household)) {
    refresh();
  }

  Future<void> refresh() async {
    Household? loadedHousehold = null;
    if (household != null) {
      loadedHousehold = await TransactionHandler.getInstance()
          .runTransaction(TransactionHouseholdGet(household: household!));
    }
    final suggestions = await ApiService.getInstance()
        .discoverRecipes(loadedHousehold?.language);

    if (suggestions != null) {
      emit(RecipeDiscoverState(
        discover: suggestions,
        household: loadedHousehold,
      ));
    } else {
      emit(RecipeDiscoverErrorState(household: loadedHousehold));
    }
  }
}

class RecipeDiscoverState extends Equatable {
  final RecipeDiscover discover;
  final Household? household;

  RecipeDiscoverState({
    this.household,
    required this.discover,
  });

  @override
  List<Object?> get props => [discover, household];
}

class RecipeDiscoverLoadingState extends RecipeDiscoverState {
  RecipeDiscoverLoadingState({super.household})
      : super(discover: const RecipeDiscover());
}

class RecipeDiscoverErrorState extends RecipeDiscoverState {
  RecipeDiscoverErrorState({super.household})
      : super(discover: const RecipeDiscover());
}
