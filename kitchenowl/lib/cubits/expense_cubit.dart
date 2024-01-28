import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/models/household.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/expense.dart';
import 'package:kitchenowl/services/transactions/household.dart';

class ExpenseCubit extends Cubit<ExpenseCubitState> {
  bool _refreshLock = false;

  ExpenseCubit(Expense expense, Household household)
      : super(ExpenseCubitState(
          expense: expense,
          household: household,
        )) {
    refresh();
  }

  void setUpdateState(UpdateEnum updateState) {
    emit(state.copyWith(updateState: updateState));
  }

  Future<void> refresh() async {
    if (_refreshLock) return;
    _refreshLock = true;
    final expense = TransactionHandler.getInstance()
        .runTransaction(TransactionExpenseGet(expense: state.expense));
    final household = TransactionHandler.getInstance()
        .runTransaction(TransactionHouseholdGet(household: state.household));
    emit(state.copyWith(
      expense: await expense,
      household: await household,
    ));
    _refreshLock = false;
  }
}

class ExpenseCubitState extends Equatable {
  final Expense expense;
  final Household household;
  final UpdateEnum updateState;

  const ExpenseCubitState({
    required this.expense,
    required this.household,
    this.updateState = UpdateEnum.unchanged,
  });

  ExpenseCubitState copyWith({
    Expense? expense,
    Household? household,
    UpdateEnum? updateState,
  }) =>
      ExpenseCubitState(
        expense: expense ?? this.expense,
        household: household ?? this.household,
        updateState: updateState ?? this.updateState,
      );

  @override
  List<Object?> get props => [updateState, expense, household];
}
