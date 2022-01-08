import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:kitchenowl/models/expense.dart';
import 'package:kitchenowl/models/user.dart';
import 'package:kitchenowl/services/transaction_handler.dart';
import 'package:kitchenowl/services/transactions/expense.dart';
import 'package:kitchenowl/services/transactions/user.dart';

class ExpenseListCubit extends Cubit<ExpenseListCubitState> {
  ExpenseListCubit() : super(const ExpenseListCubitState()) {
    refresh();
  }

  Future<void> remove(Expense expense) async {
    await TransactionHandler.getInstance()
        .runTransaction(TransactionExpenseRemove(expense: expense));
    await refresh();
  }

  Future<void> add(Expense expense) async {
    await TransactionHandler.getInstance()
        .runTransaction(TransactionExpenseAdd(expense: expense));
    await refresh();
  }

  Future<void> update(Expense expense) async {
    await TransactionHandler.getInstance()
        .runTransaction(TransactionExpenseUpdate(expense: expense));
    await refresh();
  }

  Future<void> refresh() async {
    final users = await TransactionHandler.getInstance()
        .runTransaction(TransactionUserGetAll());
    final expenses = await TransactionHandler.getInstance()
        .runTransaction(TransactionExpenseGetAll());

    emit(ExpenseListCubitState(users, expenses));
  }
}

class ExpenseListCubitState extends Equatable {
  final List<User> users;
  final List<Expense> expenses;

  const ExpenseListCubitState([
    this.users = const [],
    this.expenses = const [],
  ]);

  @override
  List<Object?> get props => users.cast<Object>() + expenses;
}
