import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/models/recipe.dart';
import 'package:kitchenowl/services/api/api_service.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/household.dart';

class RecipeFindCubit extends Cubit<RecipeFindState> {
  final Household? household;

  RecipeFindCubit(this.household)
      : super(RecipeFindLoadingState(household: household)) {
    refresh();
  }

  Future<void> refresh() async {
    Household? loadedHousehold = null;
    if (household != null) {
      loadedHousehold = await TransactionHandler.getInstance()
          .runTransaction(TransactionHouseholdGet(household: household!));
    }
    final suggestions = await ApiService.getInstance()
        .suggestRecipes(loadedHousehold?.language);

    if (suggestions != null) {
      emit(RecipeFindState(
        tags: suggestions.$1,
        communityNewest: suggestions.$2,
        household: loadedHousehold,
      ));
    } else {
      emit(RecipeFindErrorState(household: loadedHousehold));
    }
  }
}

class RecipeFindState extends Equatable {
  final List<String> tags;
  final List<Recipe> communityNewest;
  final Household? household;

  RecipeFindState({
    this.household,
    required this.tags,
    required this.communityNewest,
  });

  @override
  List<Object?> get props => [tags, communityNewest, household];
}

class RecipeFindLoadingState extends RecipeFindState {
  RecipeFindLoadingState({super.household})
      : super(communityNewest: const [], tags: const []);
}

class RecipeFindErrorState extends RecipeFindState {
  RecipeFindErrorState({super.household})
      : super(communityNewest: const [], tags: const []);
}
