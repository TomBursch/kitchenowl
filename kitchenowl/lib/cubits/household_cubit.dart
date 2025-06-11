import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/household.dart';

class HouseholdCubit extends Cubit<HouseholdState> {
  HouseholdCubit(Household household)
      : super(HouseholdState(
          household: household,
        )) {
    refresh();
  }

  Future<void> refresh() async {
    final household = await TransactionHandler.getInstance().runTransaction(
      TransactionHouseholdGet(
        household: state.household,
      ),
    );
    if (household == null) {
      emit(NotFoundHouseholdState(household: state.household));
    } else {
      emit(state.copyWith(household: household));
    }
  }

  Future<void> reorderShoppingLists(List<ShoppingList> reorderedLists) async {
    final standardList = reorderedLists.firstWhereOrNull((l) => l.isStandard);
    
    // Validate standard list is first
    if (standardList != null && reorderedLists.first != standardList) {
      emit(state.copyWith(error: 'Standard list must remain first'));
      return;
    }
  
    try {
      emit(state.copyWith(isLoading: true));
      
      // Only send non-standard lists for reordering
      final orderedIds = reorderedLists
        .where((l) => !l.isStandard)
        .map((list) => list.id!)
        .toList();
        
      final success = await TransactionHandler.getInstance().runTransaction(
        TransactionShoppingListReorder(
          household: state.household,
          orderedIds: orderedIds,
        ),
      );
  
      if (success) {
        emit(state.copyWith(
          shoppingLists: reorderedLists,
          isLoading: false,
          error: null,
        ));
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: 'Failed to update order',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Error reordering lists: ${e.toString()}',
      ));
    }
  }
  Future<void> refreshShoppingLists() async {
    // Refresh shopping lists from server
    await loadHouseholdData();
  }
  // Add method to make list standard
  Future<void> makeStandardList(ShoppingList list) async {
    try {
      emit(state.copyWith(isLoading: true));
      
      final success = await TransactionHandler.getInstance().runTransaction(
        TransactionShoppingListMakeStandard(
          household: state.household,
          shoppingList: list,
        ),
      );
  
      if (success) {
        await refresh(); // Refresh entire household
      } else {
        emit(state.copyWith(
          isLoading: false,
          error: 'Failed to make list standard',
        ));
      }
    } catch (e) {
      emit(state.copyWith(
        isLoading: false,
        error: 'Error updating standard list: ${e.toString()}',
      ));
    }
  }
}

class HouseholdState extends Equatable {
  final Household household;
  final List<ShoppingList> shoppingLists;
  final bool isLoading;
  final String? error;

  const HouseholdState({
    required this.household,
    this.shoppingLists = const [],
    this.isLoading = false,
    this.error,
  });

  // Add copyWith for all fields
  HouseholdState copyWith({
    Household? household,
    List<ShoppingList>? shoppingLists,
    bool? isLoading,
    String? error,
  }) => HouseholdState(
    household: household ?? this.household,
    shoppingLists: shoppingLists ?? this.shoppingLists,
    isLoading: isLoading ?? this.isLoading,
    error: error,
  );

  @override
  List<Object?> get props => [household, shoppingLists, isLoading, error];
}
class NotFoundHouseholdState extends HouseholdState {
  const NotFoundHouseholdState({required super.household});
}
