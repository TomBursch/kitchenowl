import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/enums/update_enum.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/expense.dart';
import 'package:kitchenowl/services/transactions/user.dart';

class ExpenseCubit extends Cubit<ExpenseCubitState> {
  bool _refreshLock = false;

  ExpenseCubit(Expense expense, List<User> users)
      : super(ExpenseCubitState(
          expense: expense,
          users: users,
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
    final users = TransactionHandler.getInstance()
        .runTransaction(TransactionUserGetAll());
    emit(state.copyWith(
      expense: await expense,
      users: await users,
    ));
    _refreshLock = false;
  }
}

class ExpenseCubitState extends Equatable {
  final Expense expense;
  final List<User> users;
  final UpdateEnum updateState;

  const ExpenseCubitState({
    required this.expense,
    this.users = const [],
    this.updateState = UpdateEnum.unchanged,
  });

  ExpenseCubitState copyWith({
    Expense? expense,
    List<User>? users,
    UpdateEnum? updateState,
  }) =>
      ExpenseCubitState(
        expense: expense ?? this.expense,
        users: users ?? this.users,
        updateState: updateState ?? this.updateState,
      );

  @override
  List<Object?> get props => [updateState, expense, users];
}
